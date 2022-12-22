import 'dart:async';
import 'dart:convert';
import 'package:by_server/jwt/model.dart';
import 'package:by_server/main.dart';
import 'package:by_server/socket/main.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/router/user/model.dart';
import 'package:by_server/router/user/main.dart';
import 'package:shelf_static/shelf_static.dart';

class JwtGateway {
  Request request;
  static List<String> whitelist = [
    'sign-in/access',
    'sign-up/captcha',
    'sign-up/access',
    'sign-up/verify'
  ];
  JwtGateway(this.request);

  String get path => request.url.path;
  String get method => request.method.toUpperCase();
  String get token => request.headers['Access-Token'] ?? '';

  Future<Response> verify(Handler handler) async {
    Authentication? auth = Authentication.fromAccessToken(token);
    if (token.isEmpty) {
      return Response(401, body: jsonEncode({'message': 'token is not found'}));
    }
    if (auth == null) {
      return Response(401,
          body: jsonEncode({'message': 'token is not available'}));
    }
    if (!auth.endTime.isAfter(DateTime.now())) {
      return Response(403, body: jsonEncode({'message': 'token is Expired'}));
    }
    User? user = await UserLoginRouter(request).getUserById(auth.userId);
    if (user != null) {
      return await handler(
          request.change(headers: {'user': jsonEncode(user.toDb)}));
    }
    return Response(401, body: jsonEncode({'message': 'token is not found'}));
  }

  FutureOr<User?> exchange() async {
    Authentication? auth = Authentication.fromAccessToken(token);
    if (auth != null) {
      if (auth.endTime.isAfter(DateTime.now())) {
        return await UserLoginRouter(request).getUserById(auth.userId);
      }
    }
    return null;
  }

  Future<Response> toWithTokenRouter(Handler handler) async {
    Response res = await handler(request);
    if (res.statusCode == 200) {
      var json = jsonDecode(await res.readAsString());
      String token = Authentication(json['data']['id']).toAccessToken;
      json['data']['token'] = token;
      return Response(200,
          body: jsonEncode(json),
          headers: {'content-type': 'application/json'});
    }
    return res;
  }

  Future<Response> exchangeTokenToUser() async {
    Authentication? auth = Authentication.fromAccessToken(token);
    if (auth != null) {
      if (auth.endTime.isAfter(DateTime.now())) {
        User? user = await UserLoginRouter(request).getUserById(auth.userId);
        if (user != null) {
          return Response(200,
              body: jsonEncode(
                  {'code': 200, 'message': 'ok', 'data': user.toJson}));
        }
      }
    }
    return Response(400, body: jsonEncode({'code': 403, 'message': '验证信息错误'}));
  }

  Future<Response> refreshTokenWith() async {
    Authentication? auth = Authentication.fromAccessToken(token);
    if (auth == null) {
      return Response(403,
          body: jsonEncode({'code': 403, 'message': '验证信息错误'}));
    }
    String newToken = Authentication(auth.userId).toAccessToken;
    User? user = await UserLoginRouter(request).getUserById(auth.userId);
    if (user == null) {
      return Response(403,
          body: jsonEncode({'code': 403, 'message': '验证信息错误'}));
    }

    return Response(200,
        body: jsonEncode({'code': 200, 'message': 'ok', 'data': newToken}));
  }

  Future<Response> handler(Handler handler) async {
    String signInPath = 'sign-in';
    String signUpPath = 'sign-up';

    if ((path == signUpPath || path == signInPath) && method == 'POST') {
      // 登录 注册
      return await toWithTokenRouter(handler);
    }

    if (path == 'token' && method == 'GET') {
      // 换取用户信息
      return await exchangeTokenToUser();
    }

    if (path == 'token-refresh' && method == 'GET') {
      // 刷新token
      return await refreshTokenWith();
    }

    if (whitelist.contains(path)) {
      // websocket 或 白名单
      return await handler(request);
    }

    // 其他路由
    return await verify(handler);
  }

  static Middleware get jwtHandlerMiddleware {
    return (Handler handler) {
      return (Request request) async {
        // websocket
        if (request.headers['Upgrade'] == 'websocket') {
          return await SocketService.handler(request);
        }
        // 静态文件
        var staticHandler = createStaticHandler('$rootDirectory/lib/public');
        if (request.url.path.contains('static/')) {
          return await staticHandler(request);
        }
        // 验证路由
        var jwt = JwtGateway(request);
        return await jwt.handler(handler);
      };
    };
  }
}

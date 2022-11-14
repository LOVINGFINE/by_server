import 'dart:async';
import 'dart:convert';
import 'package:by_dart_server/gateway/model.dart';
import 'package:by_dart_server/socket/main.dart';
import 'package:shelf/shelf.dart';
import 'package:by_dart_server/router/user/model.dart';
import 'package:by_dart_server/router/user/main.dart';

class Gateway {
  static List<String> whitelist = ['user'];

  static Future<Response> verify(Handler handler, Request request) async {
    String token = request.headers['Access-Token'] ?? '';
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
    User? user = await UserRouter(request).getUserById(auth.userId);
    if (user != null) {
      return await handler(
          request.change(headers: {'user': jsonEncode(user.toJson())}));
    }
    return Response(400, body: jsonEncode({'message': 'not found user'}));
  }

  static exchange(Request request) async {
    String token = request.headers['Access-Token'] ?? '';
    Authentication? auth = Authentication.fromAccessToken(token);
    if (auth != null) {
      if (auth.endTime.isAfter(DateTime.now())) {
        return await UserRouter(request).getUserById(auth.userId);
      }
    }
  }

  static Future<Response> userRouter(Request request) async {
    Response userRes = await UserRouter(request).handler();
    if (userRes.statusCode == 200) {
      var res = jsonDecode(await userRes.readAsString());
      String token = Authentication(res['data']['id']).toAccessToken;
      res['data']['token'] = token;
      return Response(200,
          body: jsonEncode(res), headers: {'content-type': 'application/json'});
    }
    return userRes;
  }

  static Future<Response> registerRouter(Request request) async {
    Response userRes = await UserRegisterRouter(request).handler();
    if (userRes.statusCode == 200) {
      var res = jsonDecode(await userRes.readAsString());
      String token = Authentication(res['data']['id']).toAccessToken;
      res['data']['token'] = token;
      return Response(200,
          body: jsonEncode(res), headers: {'content-type': 'application/json'});
    }
    return userRes;
  }

  static Future<Response> accessToken(Request request) async {
    User? user = await exchange(request);
    if (user == null) {
      return Response(400,
          body: jsonEncode({'code': 403, 'message': '验证信息错误'}));
    }
    return Response(200,
        body: jsonEncode({
          'code': 200,
          'message': 'ok',
          'data': user.toJson(hide: ['password'])
        }));
  }

  static Middleware get handler {
    return (Handler handler) {
      return (Request request) async {
        var path = request.url.path;
        if (request.headers['Upgrade'] == 'websocket') {
          return SocketService.handler(request);
        }
        var method = request.method.toUpperCase();
        // 登录 注册
        if ((path == 'register') && method == 'POST') {
          return await registerRouter(request);
        }
        if ((path == 'login') && method == 'POST') {
          return await userRouter(request);
        }

        if (path == 'token' && method == 'GET') {
          // 换取用户信息
          return await accessToken(request);
        }

        if (whitelist.contains(path)) {
          // websocket 或 白名单
          return await handler(request);
        }

        // 其他路由
        return await verify(handler, request);
      };
    };
  }
}
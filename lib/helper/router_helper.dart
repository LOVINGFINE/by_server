import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http_parser/http_parser.dart';
import 'package:by_server/router/user/model.dart';

class BodyResult {
  /// The parsed json.
  dynamic json = {};

  /// All files uploaded within this request.
  List<File> files = [];

  /// You must set [storeOriginalBuffer] to `true` to see this.
  List<int> originalBuffer = [];
}

class RouterHelper {
  Request request;
  BodyResult body = BodyResult();
  RouterHelper(
    this.request,
  );

  Map<String, String> get query {
    return request.url.queryParameters;
  }

  Future<dynamic> getBodyJson() async {
    // 获取body
    try {
      String bodyString = await request.readAsString();
      var map = jsonDecode(bodyString);
      if (map != null) {
        return map;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future bodyParse() async {
    try {
      // Stream<List<int>> stream = request.read();
      MediaType contentType =
          MediaType.parse(request.headers['content-type'].toString());
      if (contentType.mimeType == 'application/json') {
        var json = await getBodyJson();
        body.json = json;
      }
    } catch (_) {
      body.json = {};
    }
  }

  Future<Response> before(Future<Response> Function() handle) async {
    return handle();
  }

  Future<Response> handler() async {
    await bodyParse();
    handle() async {
      switch (request.method.toUpperCase()) {
        case 'GET':
          return get();
        case 'POST':
          return post();
        case 'PUT':
          return put();
        case 'PATCH':
          return patch();
        case 'DELETE':
          return delete();
        default:
          return response(503,
              message: 'method [${request.method.toUpperCase()}] not allow');
      }
    }

    return before(handle);
  }

  Future<Response> get() {
    return Future(() => response(503,
        message: 'method [${request.method.toUpperCase()}] not allow'));
  }

  Future<Response> post() {
    return Future(() => response(503,
        message: 'method [${request.method.toUpperCase()}] not allow'));
  }

  Future<Response> put() {
    return Future(() => response(503,
        message: 'method [${request.method.toUpperCase()}] not allow'));
  }

  Future<Response> patch() {
    return Future(() => response(503,
        message: 'method [${request.method.toUpperCase()}] not allow'));
  }

  Future<Response> delete() {
    return Future(() => response(503,
        message: 'method [${request.method.toUpperCase()}] not allow'));
  }

  Response response(code, {data, message, headers}) {
    var body =
        json.encode({'code': code, 'message': message ?? '', 'data': data});
    return Response(code,
        body: body, headers: headers ?? {'content-type': 'application/json'});
  }
}

class RouterUserHelper extends RouterHelper {
  User user = User();
  RouterUserHelper(Request request) : super(request) {
    try {
      user = User.fromJson(jsonDecode(request.headers['user'] ?? ''));
    } catch (e) {
      print(e);
    }
  }
}

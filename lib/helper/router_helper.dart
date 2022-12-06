import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http_parser/http_parser.dart';
import 'package:by_server/router/user/model.dart';
import 'body_parser_helper.dart';

class RouterHelper {
  Request request;
  BodyResult body = BodyResult();
  RouterHelper(
    this.request,
  );

  Map<String, String> get query {
    return request.url.queryParameters;
  }

  Future setBodyJson() async {
    // 获取body
    try {
      String bodyString = await request.readAsString();
      body.json = jsonDecode(bodyString);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<dynamic> setBodyFiles(MediaType contentType) async {
    // 获取body
    try {
      if (request.isMultipartForm) {
        // Read all form-data parameters into a single map:
        final parameters = <String, String>{
          await for (final formData in request.multipartFormData)
            formData.name: await formData.part.readString(),
        };
        print(parameters);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future bodyParse() async {
    try {
      MediaType contentType =
          MediaType.parse(request.headers['content-type'].toString());
      if (contentType.type == 'multipart') {
        if (contentType.subtype == 'form-data') {
          setBodyFiles(contentType);
        }
      } else {
        setBodyJson();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Response> before(Future<Response> Function() handle) async {
    return handle();
  }

  Future<Response> handler() async {
    body = await BodyParserHelper(request).getBodyResult();
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

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/router/main.dart';
import 'package:by_server/jwt/main.dart';
import 'package:by_server/utils/easy_date.dart';

/// app 配置
InternetAddress iPv4 = InternetAddress.loopbackIPv4; // 配置
int port = 8080; // 端口
String rootDirectory = Directory.current.path; // 根目录
Db mongodb = Db("mongodb://${iPv4.host}:27017/DATABASESERVER");
String serverPath = 'http://${iPv4.host}:$port';

class AppServer {
  /// 其他
  final Map<String, String> overrideHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Allow-Methods': '*',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Max-Age': '3600',
  };
  run() async {
    // server
    try {
      await mongodb.open();
    } catch (e) {
      print(e.toString());
    }

    var pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders(headers: overrideHeaders))
        .addMiddleware(JwtGateway.jwtHandlerMiddleware)
        .addHandler(HttpRouter.router);
    await shelf_io.serve(pipeline, iPv4, port);
    print('[${EasyDate().format(EasyDate.time)}] http://${iPv4.host}:$port');
  }
}

import 'dart:io';
import 'package:by_server/main.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';

class CloudFileRouter extends RouterUserHelper {
  CloudFileRouter(Request request) : super(request);

  @override
  Future<Response> post() async {
    var root = '$rootDirectory/lib/public/static/${user.id}/';
    await for (var ele in body.files) {
      List<int> bytes = await ele.part.readBytes();
      var file = File('$root${ele.filename}');
      await file.writeAsBytes(bytes);
    }

    return response(200, message: 'ok', data: {});
  }
}

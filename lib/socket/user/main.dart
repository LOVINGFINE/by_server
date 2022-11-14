import 'dart:convert';
import 'package:by_dart_server/helper/socket_helper.dart';
import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './model.dart';

class UserSocket extends SocketHelper {
  UserSocket(Request request) : super(request);

  @override
  listen(String channel, msg) {
    try {
      var map = json.decode(msg);
      var id = map['id'];
    } catch (_) {
      print(msg);
    }
  }
}

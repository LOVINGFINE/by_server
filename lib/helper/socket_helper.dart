import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketMessage {
  String channel;
  Map<String, dynamic> content = {};
  SocketMessage(this.channel);
  SocketMessage.formJson(Map<String, dynamic> json)
      : channel = json['channel'],
        content = json['content'];
}


class SocketHelper {
  Request request;
  static Map<String, WebSocketChannel> sockets = {};
  SocketHelper(
    this.request,
  );

  Map<String, String> get query {
    return request.url.queryParameters;
  }

  register(WebSocketChannel value) {
    var key = request.url.queryParameters['id'];
    if (key != null) {
      sockets[key] = value;
      value.stream.listen((event) {
        listen(key, event);
      });
    }
  }

  listen(String channel, msg) {
    print(channel + msg);
  }

  static send(SocketMessage message) {
    var target = sockets[message.channel];
    if (target != null) {
      if (target.closeCode != null) {
        sockets.remove(target);
      } else {
        target.sink.add(json.encode(message.content));
      }
    }
  }
}

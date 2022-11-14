import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import './user/main.dart';

class SocketService {
  static Map<String, WebSocketChannel> sockets = {};
  static handler(Request request) {
    return webSocketHandler((WebSocketChannel webSocket) {
      String path = request.url.path;
      switch (path) {
        default:
          webSocket.sink.close(404);
      }
    });
  }
}

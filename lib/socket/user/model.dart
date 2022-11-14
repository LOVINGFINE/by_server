import 'package:by_dart_server/utils/lodash.dart';

enum MessageType { text, file, video, voice, link }

extension ParseMessageType on MessageType {
  String toTypeString() {
    return toString().split('.').last;
  }

  MessageType? stringToType(String type) {
    return ListUtil.find(MessageType.values, (v, i) {
      return v.toTypeString() == type;
    });
  }
}

class Message {
  String id;
  MessageType type = MessageType.values[0];
  String content;
  Message(this.id, {this.content = ''});
  Message.formJson(Map<String, dynamic> json)
      : id = json['id'],
        type = MessageType.values[0].stringToType(json['type']) ??
            MessageType.values[0],
        content = json['content'];
}

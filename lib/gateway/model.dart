import 'package:by_dart_server/utils/rsa.dart';
import 'dart:convert';

class Authentication {
  DateTime endTime = DateTime.now().add(const Duration(days: 7));
  String userId;
  Authentication(this.userId);

  Authentication.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        endTime = DateTime.parse(json['endTime']);

  String get toAccessToken {
    String str = json.encode({'userId': userId, 'endTime': endTime.toString()});
    return SecretRSA().enCode(str);
  }

  static fromAccessToken(String token) {
    if (token.isNotEmpty) {
      String? jsonString = SecretRSA().deCode(token);
      if (jsonString != null) {
        return Authentication.fromJson(jsonDecode(jsonString));
      }
    }
  }
}

import 'dart:developer';

import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/lodash.dart';

enum TodoType { mobile, email, username }

extension ParseTodoType on TodoType {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  TodoType? toType(String type) {
    return ListUtil.find<TodoType>(TodoType.values, (v, i) => v.toTypeString() == type);
  }
}

class User {
  String id = User.getNewId();
  String username;
  String password;
  String nickname;
  String mobile;
  String email;
  User({
    this.username = '',
    this.mobile = '',
    this.password = '',
    this.nickname = '',
    this.email = '',
  });

  Map<String, dynamic> toJson({hide}) {
    Map<String, dynamic> map = {
      'id': id,
      'username': username,
      'password': password,
      'nickname': nickname,
      'email': email,
      'mobile': mobile
    };
    if (hide != null) {
      for (var item in hide) {
        map.remove(item);
      }
    }

    return map;
  }

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        nickname = json['nickname'],
        password = json['password'],
        email = json['email'],
        mobile = json['mobile'];

  static getNewId() {
    return 'LF_${Md5EnCode('user-${DateTime.now()}').to32Bit}';
  }
}

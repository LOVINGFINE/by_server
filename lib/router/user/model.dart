import 'package:by_server/main.dart';
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
    return ListUtil.find<TodoType>(
        TodoType.values, (v, i) => v.toTypeString() == type);
  }
}

class User {
  String id = User.getNewId();
  String avatar = '';
  String username;
  String password;
  String nickname;
  String mobile;
  String email;
  String usernameUpdated = DateTime.now().toString();
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  User({
    this.username = '',
    this.mobile = '',
    this.password = '',
    this.nickname = '',
    this.email = '',
  });

  Map<String, dynamic> get toDb {
    return {
      'id': id,
      'avatar': avatar,
      'username': username,
      'password': password,
      'nickname': nickname,
      'email': email,
      'mobile': mobile,
      'usernameUpdated': usernameUpdated,
      'updatedTime': updatedTime,
      'createdTime': createdTime
    };
  }

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'avatar': serverPath + avatar,
      'username': username,
      'nickname': nickname,
      'email': email,
      'mobile': mobile,
      'usernameUpdated': usernameUpdated,
      'updatedTime': updatedTime,
      'createdTime': createdTime
    };
  }

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        avatar = json['avatar'],
        nickname = json['nickname'],
        password = json['password'],
        email = json['email'],
        usernameUpdated = json['usernameUpdated'],
        updatedTime = json['updatedTime'],
        createdTime = json['createdTime'],
        mobile = json['mobile'];

  static getNewId() {
    return Md5EnCode('user-${DateTime.now()}').to32Bit;
  }
}

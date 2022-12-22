import 'package:by_server/main.dart';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/lodash.dart';
import 'package:by_server/utils/platform.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

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
  String passwordUpdated = DateTime.now().toString();
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
      'passwordUpdated': passwordUpdated,
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
      'passwordUpdated': passwordUpdated,
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
        passwordUpdated = json['passwordUpdated'],
        updatedTime = json['updatedTime'],
        createdTime = json['createdTime'],
        mobile = json['mobile'];

  static getNewId() {
    return Md5EnCode('user-${DateTime.now()}').to32Bit;
  }
}

enum ActiveType { signIn }

extension ParseActiveType on ActiveType {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  ActiveType toType(String type) {
    ActiveType? t = ListUtil.find<ActiveType>(
        ActiveType.values, (v, i) => v.toTypeString() == type);
    if (t == null) {
      return ActiveType.values[0];
    }
    return t;
  }
}

class UserActiveHistory {
  String id = Md5EnCode('user-active-history-${DateTime.now()}').to32Bit;
  UserPlatform platform = UserPlatform('');
  String date = DateTime.now().toString();
  String host = '';
  ActiveType type;

  UserActiveHistory(this.type);

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'platform': platform.toJson,
      'date': date,
      'host': host,
      'type': type.toTypeString()
    };
  }

  static Future insert(Request request, String userId, ActiveType type) async {
    DbCollection activeHistoryDb =
        mongodb.collection('users_active_history_$userId');
    String userAgent = request.headers["user-agent"] ?? '';
    String host = request.requestedUri.host;
    var active = UserActiveHistory(type);
    active.platform = UserPlatform(userAgent);
    active.host = host;
    await activeHistoryDb.insertOne(active.toJson);
  }
}

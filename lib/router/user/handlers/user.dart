import 'package:shelf/shelf.dart';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/verify.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import '../model.dart';

class UserRouter extends RouterHelper {
  DbCollection userDb = mongodb.collection('users');
  UserRouter(Request request) : super(request);

  getUserById(String id) async {
    // 通过手机号登录
    Map<String, dynamic>? res = await userDb.findOne(where.eq('id', id));
    if (res != null) {
      return User.fromJson(res);
    }
  }

  Future<Response> toMobile() async {
    // 通过手机号登录
    String mobile = body.json['mobile'] ?? '';
    if (!Verify(mobile).mobile) {
      return response(412, message: '手机号格式不正确');
    } else {
      String password = Md5EnCode(body.json['password'] ?? '').to32Bit;
      Map<String, dynamic>? res = await userDb
          .findOne(where.eq('mobile', mobile).eq('password', password));
      if (res == null) {
        return response(400, message: '账号/密码错误');
      }
      User user = User.fromJson(res);
      return response(200,
          message: 'ok', data: user.toJson(hide: ['password']));
    }
  }

  Future<Response> toEmail() async {
    // 通过邮箱密码登录
    String email = body.json['email'] ?? '';
    if (!Verify(email).email) {
      return response(412, message: '邮箱格式不正确');
    } else {
      String password = Md5EnCode(body.json['password'] ?? '').to32Bit;
      var res = await userDb
          .findOne(where.eq('email', email).eq('password', password));
      if (res == null) {
        return response(400, message: '密码错误');
      }
      User user = User.fromJson(res);
      return response(200,
          message: 'ok', data: user.toJson(hide: ['password']));
    }
  }

  Future<Response> toUsername() async {
    // 通过账号密码登录
    String password = body.json['password'] ?? '';
    String username = body.json['username'] ?? '';
    if (username.isEmpty) {
      return response(412, message: '账号不能为空');
    }
    if (password.isEmpty) {
      return response(400, message: '密码不能为空');
    }
    Map<String, dynamic>? res =
        await userDb.findOne(where.eq('username', username));
    if (res == null) {
      return response(412, message: '账号不存在');
    }
    Map<String, dynamic>? userJson = await userDb.findOne(where
        .eq('username', username)
        .eq('password', Md5EnCode(password).to16Bit));
    if (userJson == null) {
      return response(400, message: '密码错误');
    }
    User user = User.fromJson(userJson);
    return response(200, message: 'ok', data: user.toJson(hide: ['password']));
  }

  @override
  Future<Response> post() async {
    TodoType? type = TodoType.values[0].toType(body.json['type'] ?? '');
    switch (type) {
      case TodoType.mobile:
        return toMobile();
      case TodoType.email:
        return toEmail();
      case TodoType.username:
        return toUsername();
      default:
        return response(400, message: 'type [$type] not found');
    }
  }
}

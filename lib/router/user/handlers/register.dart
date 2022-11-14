import 'package:shelf/shelf.dart';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/verify.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import '../model.dart';

class UserRegisterRouter extends RouterHelper {
  DbCollection userDb = mongodb.collection('DB_USERS');
  UserRegisterRouter(Request request) : super(request);

  Future<Response> toMobile() async {
    String mobile = body.json['mobile'] ?? '';
    if (!Verify(mobile).mobile) {
      return response(400, message: '手机号格式不正确');
    } else {
      Map<String, dynamic>? res =
          await userDb.findOne(where.eq('mobile', mobile));
      if (res == null) {
        String password = body.json['password'] ?? '12345678';
        User user = User(
            password: Md5EnCode(password).to32Bit,
            username: 'LF_${Md5EnCode(DateTime.now().toString()).to16Bit}',
            mobile: mobile);

        var status = await userDb.insertOne(user.toJson());
        if (status.isFailure) {
          return response(400, message: '注册用户失败');
        }
        return response(200,
            message: 'ok', data: user.toJson(hide: ['password']));
      }
      return response(412, message: '手机号已存在');
    }
  }

  Future<Response> toEmail() async {
    // 通过邮箱密码注册
    String email = body.json['email'] ?? '';
    if (!Verify(email).email) {
      return response(400, message: '邮箱格式不正确');
    } else {
      Map<String, dynamic>? res =
          await userDb.findOne(where.eq('email', email));
      if (res == null) {
        String password = body.json['password'] ?? '12345678';
        User user = User(
            password: Md5EnCode(password).to32Bit,
            username: 'LF_${DateTime.now()}',
            email: email);
        var status = await userDb.insertOne(user.toJson());
        if (status.isFailure) {
          return response(500, message: '注册用户失败');
        }
        return response(200,
            message: 'ok', data: user.toJson(hide: ['password']));
      }
      return response(412, message: '邮箱已存在');
    }
  }

  Future<Response> toUsername() async {
    String password = body.json['password'] ?? '12345678';
    String username = body.json['username'] ?? '';
    if (username.length < 6 || username.length >= 32) {
      return response(400,
          message: '账号长度 ${username.length < 8 ? '不能小于8个字符' : '不能大于32个字符'}');
    }
    var res = await userDb.findOne(where.eq('username', username));
    if (res == null) {
      // 生成用户
      User user =
          User(password: Md5EnCode(password).to32Bit, username: username);
      var status = await userDb.insertOne(user.toJson());
      if (status.isFailure) {
        return response(400, message: '注册用户失败');
      }
      return response(200,
          message: 'ok', data: user.toJson(hide: ['password']));
    }
    return response(412, message: '当前账号已被注册');
  }

  @override
  Future<Response> post() async {
    TodoType? type = TodoType.mobile.toType(body.json['type'] ?? '');
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

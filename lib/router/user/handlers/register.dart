import 'package:shelf/shelf.dart';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/verify.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/helper/mail_helper.dart';
import '../model.dart';

class UserRegisterRouter extends RouterHelper {
  DbCollection userDb = mongodb.collection('users');
  MailHelper mailHelper = MailHelper();
  // 'captcha' | 'access' | 'verify'
  String type;
  UserRegisterRouter(Request request, {this.type = ''}) : super(request);
  Future<Response> toSignUp() async {
    // 通过邮箱密码注册
    String email = body.json['email'] ?? '';
    if (!Verify(email).email) {
      return response(400, message: '邮箱格式不正确');
    } else {
      Map<String, dynamic>? res =
          await userDb.findOne(where.eq('email', email));
      if (res != null) {
        return response(412, message: '邮箱已存在');
      }
      // 开始注册
      String password = body.json['password'] ?? '12345678';
      User user = User(
          password: Md5EnCode(password).to32Bit,
          username: 'LF-${Md5EnCode(DateTime.now().toString()).to16Bit}',
          email: email);
      var status = await userDb.insertOne(user.toDb);
      if (status.isFailure) {
        return response(500, message: '注册用户失败');
      }
      return response(200, message: 'ok', data: user.toJson);
    }
  }

  Future<Response> toAccess() async {
    // 通过邮箱密码注册
    String email = body.json['email'] ?? '';
    if (!Verify(email).email) {
      return response(400, message: '邮箱格式不正确');
    } else {
      Map<String, dynamic>? res =
          await userDb.findOne(where.eq('email', email));
      if (res != null) {
        return response(412, message: '邮箱已存在');
      }
      return response(201, message: 'ok');
    }
  }

  Future<Response> toCaptcha() async {
    // 通过邮箱密码注册
    String email = body.json['email'] ?? '';
    if (!Verify(email).email) {
      return response(400, message: '邮箱格式不正确');
    } else {
      // 发送验证码
      mailHelper.sendRegisterCode(email);
      return response(201, message: 'ok');
    }
  }

  Future<Response> toVerify() async {
    // 发送验证码
    String email = body.json['email'] ?? '';
    String code = body.json['code'] ?? '';
    if (code.isEmpty) {
      return response(400, message: '验证码不能为空');
    }
    bool verify = await mailHelper.isVerify(email, code);
    if (!verify) {
      return response(400, message: '验证码过期');
    }
    return response(201, message: 'ok');
  }

  @override
  Future<Response> post() async {
    switch (type) {
      case 'access':
        return toAccess();
      case 'captcha':
        return toCaptcha();
      case 'verify':
        return toVerify();
      default:
        return toSignUp();
    }
  }
}

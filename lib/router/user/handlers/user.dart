import 'dart:io';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/utils/verify.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/helper/mail_helper.dart';

class UserRouter extends RouterUserHelper {
  DbCollection userDb = mongodb.collection('users');
  MailHelper mailHelper = MailHelper();
  //  'username'
  String type;
  UserRouter(Request request, {this.type = ''}) : super(request);

  Future<Response> updateUsername() async {
    String username = body.json['username'] ?? '';
    if (username.isEmpty) {
      return response(400, message: '用户名不可为空');
    }

    if (username.length < 8) {
      return response(400, message: '用户名的字符长度不少于8个字节');
    }

    if (!Verify(username).username) {
      return response(400,
          message: '帐号不合法(字母开头，允许字母数字、-、_、&、!、=、+、|, 8-32个字节)');
    }

    if (DateTime.parse(user.usernameUpdated)
        .add(const Duration(days: 30))
        .isAfter(DateTime.now())) {
      return response(400, message: '当前用户不可修改用户名,30天内只可修改一次');
    }

    // 可以修改
    var res = await userDb.findOne(where.eq('username', username));
    if (res != null) {
      return response(400, message: '用户名已存在');
    }

    user.username = username;
    user.updatedTime = DateTime.now().toString();
    user.usernameUpdated = DateTime.now().toString();
    var status = await userDb.updateOne(where.eq('id', user.id), {
      '\$set': {
        'username': user.username,
        'usernameUpdated': user.updatedTime,
        'updatedTime': user.updatedTime
      }
    });

    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    return response(200, message: 'ok', data: user.toJson);
  }

  Future<Response> updateNickname() async {
    if (body.json['nickname'] != null) {
      user.nickname = body.json['nickname'];
    }
    user.updatedTime = DateTime.now().toString();
    await userDb.updateOne(where.eq('id', user.id), {
      '\$set': {'nickname': user.nickname, 'updatedTime': user.updatedTime}
    });
    return response(200, message: 'ok', data: user.toJson);
  }

  Future<Response> updateMobile() async {
    if (body.json['mobile'] == null || !Verify(body.json['mobile']).mobile) {
      return response(400, message: '手机号 错误');
    }
    user.mobile = body.json['mobile'];
    user.updatedTime = DateTime.now().toString();
    await userDb.updateOne(where.eq('id', user.id), {
      '\$set': {'mobile': user.mobile, 'updatedTime': user.updatedTime}
    });
    return response(200, message: 'ok', data: user.toJson);
  }

  Future<Response> updateAvatar() async {
    var root = '$rootDirectory/lib/public/static/${user.id}/';
    await for (var ele in body.files) {
      if (ele.name == 'avatar') {
        List<int> bytes = await ele.part.readBytes();
        String es = (ele.filename ?? '.png').split('.')[1];
        String filename = 'avatar-${DateTime.now().millisecondsSinceEpoch}.$es';
        var file = File('$root$filename');
        await file.writeAsBytes(bytes);
        user.avatar = '/static/${user.id}/$filename';
      }
    }
    user.updatedTime = DateTime.now().toString();
    userDb.update(where.eq('id', user.id), {
      '\$set': {'avatar': user.avatar, 'updateTime': user.updatedTime}
    });
    return response(200, message: 'ok', data: user.toJson);
  }

  Future<Response> updateEmail() async {
    var newEmail = body.json['email'];
    String code = body.json['code'] ?? '';
    if (code.isEmpty) {
      return response(400, message: '验证码不能为空');
    }
    if (newEmail == null || !Verify(newEmail).email) {
      return response(400, message: '邮箱错误');
    }
    if (await mailHelper.isVerify(user.email, code)) {
      user.email = newEmail;
      user.updatedTime = DateTime.now().toString();
      await userDb.updateOne(where.eq('id', user.id), {
        '\$set': {'email': user.email, 'updatedTime': user.updatedTime}
      });
      return response(200, message: 'ok', data: user.toJson);
    }
    return response(400, message: '验证码错误');
  }

  Future<Response> setPasswordWithOld() async {
    String old = body.json['old'] ?? '';
    String password = body.json['password'] ?? '';

    if (user.password != Md5EnCode(old).to32Bit) {
      return response(400, message: '原密码不正确');
    }
    if (password.isEmpty || password.length < 8) {
      return response(400, message: '密码格式不正确');
    }
    user.password = Md5EnCode(password).to32Bit;
    user.updatedTime = DateTime.now().toString();
    userDb.update(where.eq('id', user.id), {
      '\$set': {'password': user.password, 'updateTime': user.updatedTime}
    });
    return response(200, message: 'ok', data: user.toJson);
  }

  Future<Response> setPasswordWithEmailCode() async {
    String code = body.json['code'] ?? '';
    String password = body.json['password'] ?? '';
    if (code.isEmpty) {
      return response(400, message: '验证码不能为空');
    }
    if (password.isEmpty || password.length < 8) {
      return response(400, message: '密码格式不正确');
    }
    if (await mailHelper.isVerify(user.email, code)) {
      user.password = Md5EnCode(password).to32Bit;
      user.updatedTime = DateTime.now().toString();
      await userDb.updateOne(where.eq('id', user.id), {
        '\$set': {'password': user.password, 'updatedTime': user.updatedTime}
      });
      return response(200, message: 'ok', data: user.toJson);
    }
    return response(400, message: '验证码错误');
  }

  @override
  Future<Response> patch() async {
    switch (type) {
      case 'username':
        return updateUsername();
      case 'nickname':
        return updateNickname();
      case 'mobile':
        return updateMobile();
      case 'avatar':
        return updateAvatar();
      case 'email':
        return updateEmail();
      case 'password-with-old':
        return setPasswordWithOld();
      case 'password-with-emailCode':
        return setPasswordWithEmailCode();
      default:
        return response(400, message: 'params error');
    }
  }

  Future<Response> sendEmailCode() async {
    var email = user.email;
    mailHelper.sendUpdateEmailCode(email);
    return response(200, message: 'ok');
  }

  Future<Response> sendPasswordEmailCode() async {
    var email = user.email;
    mailHelper.sendUpdatePasswordCode(email);
    return response(200, message: 'ok');
  }

  @override
  Future<Response> get() async {
    switch (type) {
      case 'email':
        return sendEmailCode();
      case 'password-with-code':
        return sendPasswordEmailCode();
      default:
        return response(400, message: 'params error');
    }
  }
}

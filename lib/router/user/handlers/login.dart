import 'package:shelf/shelf.dart';
import 'package:by_server/utils/md5.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import '../model.dart';

class UserLoginRouter extends RouterHelper {
  DbCollection userDb = mongodb.collection('users');
  //  'access'
  String type;
  UserLoginRouter(Request request, {this.type = ''}) : super(request);

  getUserById(String id) async {
    Map<String, dynamic>? res = await userDb.findOne(where.eq('id', id));
    if (res != null) {
      return User.fromJson(res);
    }
  }

  Future<Response> toAccess() async {
    String accent = body.json['accent'] ?? '';
    if (accent.isEmpty) {
      return response(412, message: '账号不能为空');
    }
    var selector = where
        .eq('username', accent)
        .or(where.eq('email', accent))
        .or(where.eq('mobile', accent));
    Map<String, dynamic>? userJson = await userDb.findOne(selector);
    if (userJson == null) {
      return response(412, message: '账号不存在');
    }
    return response(200, message: 'ok');
  }

  Future<Response> toSignIn() async {
    String accent = body.json['accent'] ?? '';
    String password = body.json['password'] ?? '';
    if (accent.isEmpty) {
      return response(412, message: '账号不能为空');
    }
    var selector = where
        .eq('username', accent)
        .or(where.eq('email', accent))
        .or(where.eq('mobile', accent));
    Map<String, dynamic>? userJson = await userDb.findOne(selector);
    if (userJson == null) {
      return response(412, message: '账号不存在');
    }
    if (password.isEmpty) {
      return response(400, message: '密码不能为空');
    }
    if (userJson['password'] != Md5EnCode(password).to32Bit) {
      return response(400, message: '密码错误');
    }
    User user = User.fromJson(userJson);
    return response(200, message: 'ok', data: user.toJson);
  }

  @override
  Future<Response> post() async {
    switch (type) {
      case 'access':
        return toAccess();
      default:
        return toSignIn();
    }
  }
}

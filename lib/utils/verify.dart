class Verify {
  // 手机号
  static RegExp mobileRegExp = RegExp(
      r'^((13[0-9])|(14[0-9])|(15[0-9])|(16[0-9])|(17[0-9])|(18[0-9])|(19[0-9]))\d{8}$');

  // 邮箱
  static RegExp emailRegExp =
      RegExp(r'^[A-Za-z0-9\u4e00-\u9fa5]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$');

  dynamic text;

  Verify(this.text);

  get mobile {
    return Verify.mobileRegExp.hasMatch('$text');
  }

  get email {
    return Verify.emailRegExp.hasMatch('$text');
  }
}

import 'dart:math';
import 'package:by_server/main.dart';
import 'package:by_server/utils/md5.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MailHelper {
  String username = 'loving_fine@qq.com';
  String password = 'cxwatyqgicqwbdig';
  DbCollection mailCodeDb = mongodb.collection('mail_codes');
  SmtpServer get smtpServer => SmtpServer('smtp.qq.com',
      ssl: true, port: 465, username: username, password: password);

  String getNewCode() {
    return Md5EnCode(Random().nextInt(1000000).toString())
        .to16Bit
        .substring(0, 6);
  }

  Future<bool> isVerify(String email, String code) async {
    var selector = where.eq('email', email).eq('code', code);
    var res = await mailCodeDb.findOne(selector);
    if (res != null) {
      var endTime = DateTime.parse(res['endTime']);
      await mailCodeDb.deleteOne(selector);
      if (endTime.isAfter(DateTime.now())) {
        return true;
      }
    }
    return false;
  }

  sendRegisterCode(String email) async {
    var code = getNewCode();

    var message = Message()
      ..from = Address(username, 'LOVINGFINE')
      ..recipients.add(email)
      ..subject = '注册帐号 | LOVINGFINE'
      ..html = HtmlMessage.getRegisterCodeHtml(code);
    try {
      await send(message, smtpServer);
      var selector = where.eq('email', email);
      var res = await mailCodeDb.findOne(selector);
      var endTime = DateTime.now().add(Duration(minutes: 5)).toString();
      if (res != null) {
        await mailCodeDb.update(selector, {
          '\$set': {'code': code, 'endTime': endTime}
        });
      } else {
        await mailCodeDb
            .insertOne({'code': code, 'email': email, 'endTime': endTime});
      }
    } on MailerException catch (e) {
      print('Message not sent. $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  sendUpdateEmailCode(String email) async {
    var code = getNewCode();
    var message = Message()
      ..from = Address(username, 'LOVINGFINE')
      ..recipients.add(email)
      ..subject = '修改邮箱 | LOVINGFINE'
      ..html = HtmlMessage.getUpdateVerifyEmailHtml(code);
    try {
      await send(message, smtpServer);
      var selector = where.eq('email', email);
      var res = await mailCodeDb.findOne(selector);
      var endTime = DateTime.now().add(Duration(minutes: 5)).toString();
      if (res != null) {
        await mailCodeDb.update(selector, {
          '\$set': {'code': code, 'endTime': endTime}
        });
      } else {
        await mailCodeDb
            .insertOne({'code': code, 'email': email, 'endTime': endTime});
      }
    } on MailerException catch (e) {
      print('Message not sent. $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  sendUpdatePasswordCode(String email) async {
    var code = getNewCode();
    var message = Message()
      ..from = Address(username, 'LOVINGFINE')
      ..recipients.add(email)
      ..subject = '修改密码 | LOVINGFINE'
      ..html = HtmlMessage.getPasswordCodeHtml(code);
    try {
      await send(message, smtpServer);
      var selector = where.eq('email', email);
      var res = await mailCodeDb.findOne(selector);
      var endTime = DateTime.now().add(Duration(minutes: 5)).toString();
      if (res != null) {
        await mailCodeDb.update(selector, {
          '\$set': {'code': code, 'endTime': endTime}
        });
      } else {
        await mailCodeDb
            .insertOne({'code': code, 'email': email, 'endTime': endTime});
      }
    } on MailerException catch (e) {
      print('Message not sent. $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}

class HtmlMessage {
  static getRegisterCodeHtml(String code) {
    return '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional //EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">  <head>    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />    <title></title>    <!--[if !mso]><!-->    <meta http-equiv="X-UA-Compatible" content="IE=edge" />    <!--<![endif]-->    <meta name="x-apple-disable-message-reformatting" />    <meta name="viewport" content="width=device-width" />    <style type="text/css">      * {        padding: 0;        margin: 0;        box-sizing: border-box;      }      #copy-message {        background-color: #fff;        padding: 11px 20px;        align-items: center;        border-radius: 4px;        box-shadow: 0 3px 6px -4px #0000001f, 0 6px 16px #00000014,          0 9px 28px 8px #0000000d;        gap: 6px;        position: fixed;        display: inline-block;        margin: 0 auto;        left: 50%;        transform: translateX(-50%);        z-index: 1200;        top: 20px;        color: #027116;        font-size: 16px;      }      body {        width: 100%;      }      table {        width: 100%;        width: 100%;        background-color: #f9f9f9;        padding: 85px 0 65px;      }      tr {        width: 100%;      }      .rc {        width: 100%;        display: flex;        justify-content: center;        margin-bottom: 12px;      }      .title {        font-size: 48px;        text-align: center;        line-height: 1.8;        color: #673147;        display: flex;        align-items: center;        gap: 12px;        margin: 0 auto;      }      .desc {        font-size: 22px;        font-family: Playfair Display, Didot, Bodoni MT, Times New Roman, serif;        text-align: center;        line-height: 1.2;        color: #666;        margin: 20px auto;      }      .code {        padding: 16px 28px;        border-radius: 8px;        font-size: 28px;        color: #333;        margin: 45px auto;        background-color: #ddd;        position: relative;        cursor: pointer;        width: auto;        display: inline-block !important;        display: inline;      }      .bottom_link {        padding: 16px 28px;        border-radius: 8px;        font-size: 16px;        color: #333;        font-size: 18px;        color: #999;      }    </style>    <meta name="robots" content="noindex,nofollow" />    <meta property="og:title" content="My First Campaign" />  </head>  <body>    <table>      <tr>        <td class="rc">          <div class="title">            <svg              viewBox="0 0 186.05 186.05"              fill="none"              width="65"              height="65"              xmlns="http://www.w3.org/2000/svg"            >              <defs>                <clipPath id="a">                  <rect                    rx="0"                    height="140"                    width="140"                    y="126.883"                    x="186.05"                  />                </clipPath>                <clipPath id="b">                  <rect                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </clipPath>                <clipPath id="c">                  <rect                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </clipPath>                <clipPath id="d">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </clipPath>                <clipPath id="e">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </clipPath>              </defs>              <g                clip-path="url(#a)"                transform="rotate(155 186.05 126.883)"                style="mix-blend-mode: passthrough"              >                <rect                  fill="none"                  rx="0"                  height="140"                  width="140"                  y="126.883"                  x="186.05"                />                <g clip-path="url(#b)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </g>                <g clip-path="url(#c)" style="mix-blend-mode: passthrough">                  <rect                    fill="#36CFC9"                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </g>                <g clip-path="url(#d)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </g>                <g clip-path="url(#e)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#36CFC9"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </g>              </g>            </svg>            欢迎加入我们          </div>        </td>        <td class="rc">          <div class="desc">            下面是您注册帐号的验证码,有效期5分钟,请妥善保管          </div>        </td>        <td class="rc">          <div class="code" id="code" title="点击复制">$code</div>        </td>        <td class="rc">          <div class="bottom_link">            欢迎您提供改进建议,帮助我们更好的改进产品          </div>        </td>        <td class="rc">          <div class="bottom_link">如有任何问题, 请联系 loving_fine@qq.com</div>        </td>      </tr>    </table>  </body>  <script>    function message(text) {      const remove = () => {        const is = document.getElementById("copy-message");        if (is) {          document.body.removeChild(is);        }      };      remove();      const div = document.createElement("div");      div.id = "copy-message";      div.textContent = text;      document.body.appendChild(div);      setTimeout(() => {        remove();      }, 2500);    }    async function onCopy(e) {      const text = e.target.textContent;      try {        const clipboard = navigator.clipboard;        await clipboard.writeText(text);        message("复制成功!");      } catch (e) {        console.warn(e);      }    }    const codeDom = document.getElementById("code");    codeDom.addEventListener("click", onCopy);  </script></html>';
  }

  static getUpdateVerifyEmailHtml(String code) {
    return '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional //EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">  <head>    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />    <title></title>    <!--[if !mso]><!-->    <meta http-equiv="X-UA-Compatible" content="IE=edge" />    <!--<![endif]-->    <meta name="x-apple-disable-message-reformatting" />    <meta name="viewport" content="width=device-width" />    <style type="text/css">      * {        padding: 0;        margin: 0;        box-sizing: border-box;      }      #copy-message {        background-color: #fff;        padding: 11px 20px;        align-items: center;        border-radius: 4px;        box-shadow: 0 3px 6px -4px #0000001f, 0 6px 16px #00000014,          0 9px 28px 8px #0000000d;        gap: 6px;        position: fixed;        display: inline-block;        margin: 0 auto;        left: 50%;        transform: translateX(-50%);        z-index: 1200;        top: 20px;        color: #027116;        font-size: 16px;      }      body {        width: 100%;      }      table {        width: 100%;        width: 100%;        background-color: #f9f9f9;        padding: 85px 0 65px;      }      tr {        width: 100%;      }      .rc {        width: 100%;        display: flex;        justify-content: center;        margin-bottom: 12px;      }      .title {        font-size: 48px;        text-align: center;        line-height: 1.8;        color: #673147;        display: flex;        align-items: center;        gap: 12px;        margin: 0 auto;      }      .desc {        font-size: 22px;        font-family: Playfair Display, Didot, Bodoni MT, Times New Roman, serif;        text-align: center;        line-height: 1.2;        color: #666;        margin: 20px auto;      }      .code {        padding: 16px 28px;        border-radius: 8px;        font-size: 28px;        color: #333;        margin: 45px auto;        background-color: #ddd;        position: relative;        cursor: pointer;        width: auto;        display: inline-block !important;        display: inline;      }      .bottom_link {        padding: 16px 28px;        border-radius: 8px;        font-size: 16px;        color: #333;        font-size: 18px;        color: #999;      }    </style>    <meta name="robots" content="noindex,nofollow" />    <meta property="og:title" content="My First Campaign" />  </head>  <body>    <table>      <tr>        <td class="rc">          <div class="title">            <svg              viewBox="0 0 186.05 186.05"              fill="none"              width="65"              height="65"              xmlns="http://www.w3.org/2000/svg"            >              <defs>                <clipPath id="a">                  <rect                    rx="0"                    height="140"                    width="140"                    y="126.883"                    x="186.05"                  />                </clipPath>                <clipPath id="b">                  <rect                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </clipPath>                <clipPath id="c">                  <rect                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </clipPath>                <clipPath id="d">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </clipPath>                <clipPath id="e">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </clipPath>              </defs>              <g                clip-path="url(#a)"                transform="rotate(155 186.05 126.883)"                style="mix-blend-mode: passthrough"              >                <rect                  fill="none"                  rx="0"                  height="140"                  width="140"                  y="126.883"                  x="186.05"                />                <g clip-path="url(#b)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </g>                <g clip-path="url(#c)" style="mix-blend-mode: passthrough">                  <rect                    fill="#36CFC9"                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </g>                <g clip-path="url(#d)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </g>                <g clip-path="url(#e)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#36CFC9"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </g>              </g>            </svg>            修改邮箱          </div>        </td>        <td class="rc">          <div class="desc">            当前您正在修改绑定邮箱,如不是您本人操作,请检查账号是否泄漏.          </div>        </td>        <td class="rc">          <div class="desc">下面是您修改邮箱验证码,有效期5分钟,请妥善保管</div>        </td>        <td class="rc">          <div class="code" id="code" title="点击复制">$code</div>        </td>        <td class="rc">          <div class="bottom_link">            欢迎您提供改进建议,帮助我们更好的改进产品          </div>        </td>        <td class="rc">          <div class="bottom_link">如有任何问题, 请联系 loving_fine@qq.com</div>        </td>      </tr>    </table>  </body>  <script>    function message(text) {      const remove = () => {        const is = document.getElementById("copy-message");        if (is) {          document.body.removeChild(is);        }      };      remove();      const div = document.createElement("div");      div.id = "copy-message";      div.textContent = text;      document.body.appendChild(div);      setTimeout(() => {        remove();      }, 2500);    }    async function onCopy(e) {      const text = e.target.textContent;      try {        const clipboard = navigator.clipboard;        await clipboard.writeText(text);        message("复制成功!");      } catch (e) {        console.warn(e);      }    }    const codeDom = document.getElementById("code");    codeDom.addEventListener("click", onCopy);  </script></html>';
  }

  static getPasswordCodeHtml(String code) {
    return '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional //EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">  <head>    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />    <title></title>    <!--[if !mso]><!-->    <meta http-equiv="X-UA-Compatible" content="IE=edge" />    <!--<![endif]-->    <meta name="x-apple-disable-message-reformatting" />    <meta name="viewport" content="width=device-width" />    <style type="text/css">      * {        padding: 0;        margin: 0;        box-sizing: border-box;      }      #copy-message {        background-color: #fff;        padding: 11px 20px;        align-items: center;        border-radius: 4px;        box-shadow: 0 3px 6px -4px #0000001f, 0 6px 16px #00000014,          0 9px 28px 8px #0000000d;        gap: 6px;        position: fixed;        display: inline-block;        margin: 0 auto;        left: 50%;        transform: translateX(-50%);        z-index: 1200;        top: 20px;        color: #027116;        font-size: 16px;      }      body {        width: 100%;      }      table {        width: 100%;        width: 100%;        background-color: #f9f9f9;        padding: 85px 0 65px;      }      tr {        width: 100%;      }      .rc {        width: 100%;        display: flex;        justify-content: center;        margin-bottom: 12px;      }      .title {        font-size: 48px;        text-align: center;        line-height: 1.8;        color: #673147;        display: flex;        align-items: center;        gap: 12px;        margin: 0 auto;      }      .desc {        font-size: 22px;        font-family: Playfair Display, Didot, Bodoni MT, Times New Roman, serif;        text-align: center;        line-height: 1.2;        color: #666;        margin: 20px auto;      }      .code {        padding: 16px 28px;        border-radius: 8px;        font-size: 28px;        color: #333;        margin: 45px auto;        background-color: #ddd;        position: relative;        cursor: pointer;        width: auto;        display: inline-block !important;        display: inline;      }      .bottom_link {        padding: 16px 28px;        border-radius: 8px;        font-size: 16px;        color: #333;        font-size: 18px;        color: #999;      }    </style>    <meta name="robots" content="noindex,nofollow" />    <meta property="og:title" content="My First Campaign" />  </head>  <body>    <table>      <tr>        <td class="rc">          <div class="title">            <svg              viewBox="0 0 186.05 186.05"              fill="none"              width="65"              height="65"              xmlns="http://www.w3.org/2000/svg"            >              <defs>                <clipPath id="a">                  <rect                    rx="0"                    height="140"                    width="140"                    y="126.883"                    x="186.05"                  />                </clipPath>                <clipPath id="b">                  <rect                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </clipPath>                <clipPath id="c">                  <rect                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </clipPath>                <clipPath id="d">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </clipPath>                <clipPath id="e">                  <rect                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </clipPath>              </defs>              <g                clip-path="url(#a)"                transform="rotate(155 186.05 126.883)"                style="mix-blend-mode: passthrough"              >                <rect                  fill="none"                  rx="0"                  height="140"                  width="140"                  y="126.883"                  x="186.05"                />                <g clip-path="url(#b)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="28"                    width="140"                    y="210.883"                    x="186.05"                  />                </g>                <g clip-path="url(#c)" style="mix-blend-mode: passthrough">                  <rect                    fill="#36CFC9"                    rx="14"                    height="28"                    width="140"                    y="154.883"                    x="186.05"                  />                </g>                <g clip-path="url(#d)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#08979C"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="214.05"                  />                </g>                <g clip-path="url(#e)" style="mix-blend-mode: passthrough">                  <rect                    fill-opacity=".76"                    fill="#36CFC9"                    rx="14"                    height="140"                    width="28"                    y="126.883"                    x="270.05"                  />                </g>              </g>            </svg>            修改密码          </div>        </td>        <td class="rc">          <div class="desc">            当前您正在修改密码,如不是您本人操作,请检查账号是否泄漏.          </div>        </td>        <td class="rc">          <div class="desc">下面是您修改密码验证码,有效期5分钟,请妥善保管</div>        </td>        <td class="rc">          <div class="code" id="code" title="点击复制">$code</div>        </td>        <td class="rc">          <div class="bottom_link">            欢迎您提供改进建议,帮助我们更好的改进产品          </div>        </td>        <td class="rc">          <div class="bottom_link">如有任何问题, 请联系 loving_fine@qq.com</div>        </td>      </tr>    </table>  </body>  <script>    function message(text) {      const remove = () => {        const is = document.getElementById("copy-message");        if (is) {          document.body.removeChild(is);        }      };      remove();      const div = document.createElement("div");      div.id = "copy-message";      div.textContent = text;      document.body.appendChild(div);      setTimeout(() => {        remove();      }, 2500);    }    async function onCopy(e) {      const text = e.target.textContent;      try {        const clipboard = navigator.clipboard;        await clipboard.writeText(text);        message("复制成功!");      } catch (e) {        console.warn(e);      }    }    const codeDom = document.getElementById("code");    codeDom.addEventListener("click", onCopy);  </script></html>';
  }
}

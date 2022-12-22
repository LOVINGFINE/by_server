final browsers = {
  'Chrome': RegExp('Chrome'),
  'IE': RegExp('MSIE'),
  'Firefox': RegExp('Firefox'),
  'Opera': RegExp('Presto'),
  'Safari': RegExp(r'Version/([\d.]+).*Safari'),
  '360': RegExp('360SE'),
  'QQ': RegExp('QQ'),
};

final devices = {
  'iPhone': RegExp('iPhone'),
  'iPad': RegExp('iPad'),
  'Android': RegExp('Android'),
  'PC': RegExp('Windows'),
  'Mac': RegExp('Macintosh'),
};

class PlatformOS {
  String name; // 操作系统名称
  String version; // 操作系统版本
  PlatformOS({this.name = '', this.version = ''});
  get toJson {
    return {'name': name, 'version': version};
  }
}

class PlatformBrowser {
  String name; // 浏览器名称
  String version; // 浏览器版本
  PlatformBrowser({this.name = '', this.version = ''});
  get toJson {
    return {'name': name, 'version': version};
  }
}

class PlatformDevice {
  String type; // 设备类型
  String name; // 设备名称
  PlatformDevice({this.type = '', this.name = ''});
  get toJson {
    return {'name': name, 'type': type};
  }
}

class UserPlatform {
  PlatformBrowser browser = PlatformBrowser(); // 浏览器名称
  PlatformOS os = PlatformOS(); // 操作系统名称
  PlatformDevice device = PlatformDevice(); // 设备类型

  UserPlatform(String userAgent) {
    browsers.forEach((key, value) {
      if (value.hasMatch(userAgent)) {
        browser.name = key;
        if (key == "Chrome") {
          browser.version = userAgent.split("Chrome/")[1].split(" ")[0];
        } else if (key == "IE") {
          browser.version = userAgent.split("MSIE ")[1].split(" ")[1];
        } else if (key == "Firefox") {
          browser.version = userAgent.split("Firefox/")[1];
        } else if (key == "Opera") {
          browser.version = userAgent.split("Version/")[1];
        } else if (key == "Safari") {
          browser.version = userAgent.split("Version/")[1].split(" ")[0];
        } else if (key == "360") {
          browser.version = "";
        } else if (key == "QQ") {
          browser.version = userAgent.split("Version/")[1].split(" ")[0];
        }
      }
    });

    devices.forEach((key, value) {
      if (value.hasMatch(userAgent)) {
        device.type = key;
        if (key == "PC") {
          os.name = 'Windows';
          os.version = userAgent.split("Windows NT ")[1].split(";")[0];
        } else if (key == "Mac") {
          os.name = 'Mac OS';
          os.version = userAgent.split("Mac OS X ")[1].split(")")[0];
        } else if (key == "iPhone") {
          os.name = 'ios';
          os.version = userAgent.split("iPhone OS ")[1].split(" ")[0];
        } else if (key == "iPad") {
          os.name = 'iPad OS';
          os.version = userAgent.split("iPad; CPU OS ")[1].split(" ")[0];
        } else if (key == "Android") {
          os.name = 'Android';
          os.version = userAgent.split("Android ")[1].split(";")[0];
          device.name = userAgent
              .split("(Linux; Android ")[1]
              .split("; ")[1]
              .split(" Build")[0];
        }
      }
    });
  }
  get toJson {
    return {
      'browser': browser.toJson,
      'device': device.toJson,
      'os': os.toJson,
    };
  }
}

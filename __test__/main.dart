import 'dart:math';

class ConfigColumn {
  int width;
  ConfigColumn({this.width = 120});
  ConfigColumn.fromJson(Map json) : width = json['width'];
  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'width': width,
    };
    return map;
  }
}

void main() async {
  var json = ['ssss'];

  print(DateTime.now().subtract(Duration(days: 50)));
}

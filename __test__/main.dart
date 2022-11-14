import 'package:by_server/utils/rsa.dart';

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

  print(json.map((e) => ConfigColumn()).toList() is List<ConfigColumn>);
}

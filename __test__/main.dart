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
  var list = [
    {'date': '2022-12-07 03:28:34.318117', 'k': 'a'},
    {'date': '2022-12-14 01:15:30.661324', 'k': 'b'},
    {'date': '', 'k': 'b'}
  ];

  list.sort((a, b) {
    try {
      return DateTime.parse(a['date'] ?? '')
              .isAfter(DateTime.parse(b['date'] ?? ''))
          ? 0
          : 1;
    } catch (e) {
      return 0;
    }
  });
  print(list);
}

import 'package:by_server/utils/md5.dart';

class Sheet {
  String id = Md5EnCode('sheet-${DateTime.now()}').to16Bit;
  String name;
  String owner;
  // user ids
  List<dynamic> share = [];
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  String lastOpenTime = DateTime.now().toString();
  Sheet({this.name = '未命名', this.owner = ''});

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'owner': owner,
      'name': name,
      'share': share,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'lastOpenTime': lastOpenTime,
    };
  }

  Sheet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        owner = json['owner'],
        share = json['share'],
        name = json['name'],
        createdTime = json['createdTime'] ?? '',
        updatedTime = json['updatedTime'] ?? '',
        lastOpenTime = json['lastOpenTime'] ?? '';
}

import 'package:by_server/utils/lodash.dart';
import 'package:by_server/utils/md5.dart';

enum SheetType {
  meta,
  common,
}

extension ParseSheetType on SheetType {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  SheetType? toType(String type) {
    return ListUtil.find<SheetType>(
        SheetType.values, (v, i) => v.toTypeString() == type);
  }
}

class Sheet {
  String id = Md5EnCode('sheet-${DateTime.now()}').to16Bit;
  String name;
  String owner;
  SheetType type;
  // user ids
  List<dynamic> share = [];
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  String lastOpenTime = DateTime.now().toString();
  Sheet({this.name = '未命名', this.owner = '', this.type = SheetType.common});

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'owner': owner,
      'name': name,
      'share': share,
      'type': type.toTypeString(),
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'lastOpenTime': lastOpenTime,
    };
  }

  Sheet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = SheetType.values[0].toType(json['type']) ?? SheetType.common,
        owner = json['owner'],
        share = json['share'],
        name = json['name'],
        createdTime = json['createdTime'] ?? '',
        updatedTime = json['updatedTime'] ?? '',
        lastOpenTime = json['lastOpenTime'] ?? '';
}

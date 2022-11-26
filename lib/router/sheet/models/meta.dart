import 'package:by_server/utils/lodash.dart';
import 'package:by_server/utils/md5.dart';

class MetaWorkbook {
  String id = Md5EnCode('meta-workbook-${DateTime.now()}').to16Bit;
  String code;
  String name;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  List<MetaColumn> columns = [];
  List<MetaEntry> entries = [];
  bool showRowCount = true;
  MetaWorkbook({this.code = '', this.name = 'Sheet1'});

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'name': name,
      'code': code,
      'showRowCount': showRowCount,
      'entries': ListUtil.map(entries, (v, i) => v.toJson),
      'columns': ListUtil.map(columns, (v, i) => v.toJson)
    };
  }

  Map<String, dynamic> get toDataJson {
    return {
      'id': id,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'code': code,
      'name': name,
      'showRowCount': showRowCount,
    };
  }

  MetaWorkbook.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        code = json['code'],
        name = json['name'],
        showRowCount = json['showRowCount'] ?? true,
        createdTime = json['createdTime'],
        updatedTime = json['updatedTime'],
        columns =
            ListUtil.map(json['columns'], (v, i) => MetaColumn.fromJson(v)),
        entries =
            ListUtil.map(json['entries'], (v, i) => MetaEntry.fromJson(v));

  static String numberToCode(int n) {
    String toCode(int n) {
      int base = 65;
      String last = String.fromCharCode(base + (n % 26));
      int prev = (n ~/ 26).toInt();
      if (prev > 0) {
        return toCode(prev - 1) + last;
      }
      return last;
    }

    return toCode(n + 26);
  }

  getEntryValues(Map<String, dynamic> json) {
    Map<String, dynamic> target = {};
    for (int i = 0; i < columns.length; i++) {
      target[columns[i].code] = json[columns[i].code] ?? '';
    }
    return target;
  }

  updateEntryValues(String id, Map<String, dynamic> json) {
    MetaEntry? entry;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == id) {
        entries[i].values = {...entries[i].values, ...json};
        entry = entries[i];
      }
    }
    return entry;
  }
}

// ignore_for_file: constant_identifier_names
enum MetaType { Text, Number, Boolean, Date, QrCode, Options, File }

extension ParseMetaType on MetaType {
  bool isTypeString(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  MetaType? stringToType(String type) {
    return ListUtil.find(MetaType.values, (v, i) => v.toTypeString() == type);
  }
}

class MetaNumber {
  String unit;
  int decimal;
  MetaNumber({this.unit = '', this.decimal = 3});
  MetaNumber.fromJson(Map<String, dynamic> json)
      : decimal = json['decimal'] ?? 3,
        unit = json['unit'] ?? '';

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'unit': unit,
      'decimal': decimal,
    };
    return map;
  }
}

class MetaDate {
  String format;
  MetaDate({this.format = 'YYYY-MM-DD HH:mm:ss'});
  MetaDate.fromJson(Map<String, dynamic> json) : format = json['format'];
  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'format': format,
    };
    return map;
  }
}

class MetaQrCode {
  int size;
  MetaQrCode({this.size = 120});
  MetaQrCode.fromJson(Map<String, dynamic> json) : size = json['size'];

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {'size': size};
    return map;
  }
}

class MetaOptionsItem {
  String color;
  String value;
  MetaOptionsItem({this.color = '', this.value = ''});
  MetaOptionsItem.fromJson(Map<String, dynamic> json)
      : color = json['color'] ?? '',
        value = json['value'] ?? '';

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {'value': value, 'color': color};
    return map;
  }
}

class MetaOptions {
  List<MetaOptionsItem> items = [];
  MetaOptions();
  MetaOptions.fromJson(Map<String, dynamic> json)
      : items =
            ListUtil.map(json['items'], (v, i) => MetaOptionsItem.fromJson(v));

  Map<String, dynamic> get toJson {
    return {'items': ListUtil.map(items, (v, i) => v - toJson)};
  }
}

// ignore_for_file: non_constant_identifier_names
class Meta {
  MetaNumber number = MetaNumber();
  MetaDate date = MetaDate();
  MetaQrCode qrCode = MetaQrCode();
  MetaOptions options = MetaOptions();
  Meta();
  Meta.fromJson(Map<String, dynamic> json)
      : number = MetaNumber.fromJson(json['number']),
        date = MetaDate.fromJson(json['date']),
        qrCode = MetaQrCode.fromJson(json['qrCode']),
        options = MetaOptions.fromJson(json['options']);

  get toJson {
    return {
      'number': number.toJson,
      'date': date.toJson,
      'qrCode': qrCode.toJson,
      'options': options.toJson,
    };
  }

  updateMeta(Map<String, dynamic> json) {
    if (json['number'] != null) {
      if (json['number']['unit'] != null) {
        number.unit = json['number']['unit'];
      }
      if (json['number']['decimal'] != null &&
          json['number']['decimal'] is int) {
        number.unit = json['number']['unit'];
      }
    }
    if (json['date'] != null) {
      if (json['date']['format'] != null) {
        date.format = json['date']['format'];
      }
    }
    if (json['qrCode'] != null) {
      if (json['qrCode']['size'] != null && json['qrCode']['size'] is int) {
        qrCode.size = json['qrCode']['size'];
      }
    }
    if (json['options'] != null) {
      if (json['options']['items'] != null &&
          json['options']['items'] is List<Map<String, dynamic>>) {
        options.items = ListUtil.map(
            json['options']['items'], (v, i) => MetaOptionsItem.fromJson(v));
      }
    }
  }
}

class MetaColumn {
  String code;
  String title;
  int width;
  String formula;
  MetaType type = MetaType.Text;
  Meta meta = Meta();
  MetaColumn(this.code, {this.title = '', this.formula = '', this.width = 180});

  MetaColumn.fromJson(Map<String, dynamic> json)
      : code = json['code'],
        type = MetaType.Text.stringToType(json['type']) ?? MetaType.Text,
        width = json['width'],
        title = json['title'],
        formula = json['formula'],
        meta = Meta.fromJson(json['meta']);

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'code': code,
      'title': title,
      'type': type.toTypeString(),
      'width': width,
      'formula': formula,
      'meta': meta.toJson
    };
    return map;
  }
}

class MetaEntry {
  String id;
  Map<String, dynamic> values = {};
  MetaEntry(this.id);

  get toJson {
    return {'id': id, 'values': values};
  }

  MetaEntry.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        values = json['values'];
}

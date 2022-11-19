import 'package:by_server/utils/lodash.dart';

class MetaWorkbook {
  String sheetId;
  String code;
  List<MetaColumn> columns = [];
  List<MetaEntry> entries = [];
  MetaWorkbook({
    this.sheetId = '',
    this.code = '',
  });

  Map<String, dynamic> get toJson {
    return {
      'sheetId': sheetId,
      'code': code,
      'columns': columns.map((c) => c.toJson).toList(),
      'entries': entries.map((e) => e.toJson).toList()
    };
  }

  MetaWorkbook.fromJson(Map<String, dynamic> json)
      : sheetId = json['sheetId'],
        code = json['code'],
        columns = json['columns'].map((v) => MetaColumn.fromJson(v)).toList(),
        entries = json['entries'].map((v) => MetaEntry.fromJson(v)).toList();

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

enum MetaUnit { none, b, k, m, t }

extension ParseMetaUnit on MetaUnit {
  String toTypeString() {
    return toString().split('.').last;
  }

  MetaUnit? stringToType(String type) {
    return ListUtil.find(MetaUnit.values, (v, i) => v.toTypeString() == type);
  }
}

class MetaNumber {
  MetaUnit unit;
  int decimal;
  MetaNumber({this.unit = MetaUnit.none, this.decimal = 3});
  MetaNumber.fromJson(Map<String, dynamic> json)
      : decimal = json['decimal'],
        unit = MetaUnit.values[0].stringToType(json['unit']) ?? MetaUnit.none;

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'unit': unit.toTypeString(),
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
      : color = json['color'],
        value = json['value'];

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {'value': value, 'color': color};
    return map;
  }
}

class MetaOptions {
  List<MetaOptionsItem> items = [];
  MetaOptions();
  MetaOptions.fromJson(Map<String, dynamic> json)
      : items = json['items'].map((v) => MetaOptionsItem.fromJson(v)).toList();

  Map<String, dynamic> get toJson {
    return {'items': items.map((e) => e.toJson).toList()};
  }
}

// ignore_for_file: non_constant_identifier_names
class Meta {
  MetaNumber Number = MetaNumber();
  MetaDate Date = MetaDate();
  MetaQrCode QrCode = MetaQrCode();
  MetaOptions Options = MetaOptions();
  Meta();
  Meta.fromJson(Map<String, dynamic> json)
      : Number = MetaNumber.fromJson(json['Number']),
        Date = MetaDate.fromJson(json['Date']),
        QrCode = MetaQrCode.fromJson(json['QrCode']),
        Options = MetaOptions.fromJson(json['Options']);

  get toJson {
    return {
      'Number': Number.toJson,
      'Date': Date.toJson,
      'QrCode': QrCode.toJson,
      'Options': Options.toJson,
    };
  }
}

class MetaColumn {
  String id;
  String code;
  String title;
  int width;
  String formula;
  MetaType type = MetaType.Text;
  Meta meta = Meta();
  MetaColumn(this.id,
      {this.code = '', this.title = '', this.formula = '', this.width = 180});

  MetaColumn.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        code = json['code'],
        type = MetaType.Text.stringToType(json['type']) ?? MetaType.Text,
        width = json['width'],
        title = json['title'],
        formula = json['formula'],
        meta = Meta.fromJson(json['meta']);

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'id': id,
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
  MetaEntry({this.id = ''});

  get toJson {
    return {'id': id, 'record': values};
  }

  MetaEntry.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        values = json['values'];

  initValues(List<MetaColumn> columns) {
    Map<String, dynamic> target = {};
    for (int i = 0; i < columns.length; i++) {
      target[columns[i].id] = values[columns[i].id] ?? '';
    }
    values = target;
  }

  updateValues(Map<String, dynamic> json) {
    json.forEach((key, value) {
      if (values[key] != null) {
        values[key] = value;
      }
    });
  }
}

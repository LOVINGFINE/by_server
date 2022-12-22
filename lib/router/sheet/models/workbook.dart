import 'package:by_server/utils/lodash.dart';
import '../../../utils/md5.dart';

class Workbook {
  String id = Md5EnCode('workbook-${DateTime.now()}').to16Bit;
  String name;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  WorkbookType type;
  // common
  Map<String, Cell> data = {};
  CommonConfig config = CommonConfig();

  // meta
  String code = '';
  List<MetaColumn> columns = [];
  List<MetaEntry> entries = [];
  bool showRowCount = true;

  Workbook(
      {this.name = 'Sheet1', this.type = WorkbookType.common, this.code = ''});
  Workbook.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        createdTime = json['createdTime'],
        updatedTime = json['updatedTime'],
        type = WorkbookType.values[0].toType(json['type']),
        // meta
        showRowCount = json['showRowCount'] ?? true,
        columns =
            ListUtil.map(json['columns'], (v, i) => MetaColumn.fromJson(v)),
        entries =
            ListUtil.map(json['entries'], (v, i) => MetaEntry.fromJson(v)),

        // common
        config = CommonConfig.fromJson(json['config']),
        data = Map.from(
            json['data'].map((key, v) => MapEntry(key, Cell.fromJson(v))));

  get toJson {
    return {
      'id': id,
      'name': name,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'type': type.toTypeString(),

      // meta
      'code': code,
      'showRowCount': showRowCount,
      'entries': ListUtil.map(entries, (v, i) => v.toJson),
      'columns': ListUtil.map(columns, (v, i) => v.toJson),

      // common
      'data': Map.from(data.map((key, v) => MapEntry(key, v.toJson))),
      'config': config.toJson
    };
  }

  get toMetaJson {
    return {
      'id': id,
      'name': name,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'type': type.toTypeString(),

      // meta
      'code': code,
      'showRowCount': showRowCount,
    };
  }

  get toCommonJson {
    return {
      'id': id,
      'name': name,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'type': type.toTypeString(),
      'config': config.toJson
    };
  }

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

  updateEntryValues(String id, {Map<String, dynamic>? json, int? height}) {
    MetaEntry? entry;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == id) {
        if (height != null) {
          entries[i].height = height;
        }
        if (json != null) {
          entries[i].values = {...entries[i].values, ...json};
        }
        entry = entries[i];
      }
    }
    return entry;
  }
}

enum WorkbookType {
  meta,
  common,
}

extension ParseWorkbookType on WorkbookType {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  WorkbookType toType(String type) {
    WorkbookType? t = ListUtil.find<WorkbookType>(
        WorkbookType.values, (v, i) => v.toTypeString() == type);
    if (t == null) {
      return WorkbookType.values[0];
    }
    return t;
  }
}

class CommonConfig {
  Map<String, ConfigColumn> column = {};
  Map<String, ConfigRow> row = {};
  CommonConfig();
  CommonConfig.fromJson(Map<String, dynamic> json)
      : column = MapUtil.map<String, ConfigColumn>(
            json['column'], (e, i) => ConfigColumn.fromJson(e)),
        row = MapUtil.map<String, ConfigRow>(
            json['row'], (e, i) => ConfigRow.fromJson(e));
  get toJson {
    return {
      'column':
          MapUtil.map<String, Map<String, dynamic>>(column, (e, i) => e.toJson),
      'row': MapUtil.map<String, Map<String, dynamic>>(row, (e, i) => e.toJson),
    };
  }
}

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

class ConfigRow {
  int height;
  ConfigRow({this.height = 28});
  ConfigRow.fromJson(Map<String, dynamic> json) : height = json['height'];
  Map<String, dynamic> get toJson {
    return {
      'height': height,
    };
  }
}

class Comment {
  String content = '';
  Comment.fromJson(Map<String, dynamic> json) : content = json['content'];
  get toJson {
    return {'content': content};
  }
}

class Cell {
  static final Map<String, dynamic> finalStyle = {
    'fontSize': 13,
    'lineHeight': 1,
    'background': "transparent",
    'color': "#424f58",
    'bold': false,
    'italic': false,
    'underline': false,
    'strike': false,
    'vertical': 'middle',
    'horizontal': 'left',
  };
  dynamic value;
  Map<String, dynamic> style = Cell.finalStyle;
  List<Comment> comments = [];
  Cell({this.value = ''});
  Cell.fromJson(Map<String, dynamic> json)
      : value = json['value'] ?? '',
        style = json['style'] ?? Cell.finalStyle,
        comments = ListUtil.map<Comment>(
            json['comments'] ?? [], (v, i) => Comment.fromJson(v));

  updateStyle(Map<String, dynamic> json) {
    style = {...style, ...json};
  }

  get toJson {
    return {
      'value': value,
      'style': style,
      'comments': comments.map((e) => e.toJson).toList()
    };
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

  update(Map<String, dynamic> json) {
    if (json['unit'] != null) {
      unit = json['unit'];
    }
    if (json['decimal'] != null && json['decimal'] is int) {
      unit = json['unit'];
    }
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

  update(Map<String, dynamic> json) {
    if (json['format'] != null) {
      format = json['format'];
    }
  }
}

class MetaQrCode {
  static List<String> constDisplay = ['VIEW', 'LABEL', 'VIEW_LABEL'];
  int size;
  // 'VIEW' | 'LABEL' | 'VIEW_LABEL'
  String display;
  String text;
  MetaQrCode(
      {this.size = 120,
      this.display = 'VIEW_LABEL',
      this.text = '{{current}}'});
  MetaQrCode.fromJson(Map<String, dynamic> json)
      : size = json['size'],
        display = json['display'] ?? 'VIEW_LABEL',
        text = json['text'] ?? '{{current}}';

  Map<String, dynamic> get toJson {
    return {'size': size, 'display': display, 'text': text};
  }

  update(Map<String, dynamic> json) {
    if (json['size'] != null && json['size'] is int) {
      size = json['size'];
    }
    if (json['display'] != null &&
        MetaQrCode.constDisplay.contains(json['display'])) {
      display = json['display'];
    }
    if (json['text'] != null) {
      text = json['text'];
    }
  }
}

class MetaBoolean {
  bool label;
  String checked;
  String unChecked;
  MetaBoolean({this.label = false, this.checked = '', this.unChecked = ''});
  MetaBoolean.fromJson(Map<String, dynamic> json)
      : label = json['label'] ?? false,
        checked = json['checked'] ?? "",
        unChecked = json['unChecked'] ?? "";

  Map<String, dynamic> get toJson {
    return {'label': label, 'checked': checked, 'unChecked': unChecked};
  }

  update(Map<String, dynamic> json) {
    if (json['label'] != null && json['label'] is bool) {
      label = json['label'];
    }
    if (json['checked'] != null && json['checked'] is String) {
      checked = json['checked'];
    }
    if (json['unChecked'] != null && json['unChecked'] is String) {
      unChecked = json['unChecked'];
    }
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
  bool multiple;
  List<MetaOptionsItem> items = [];
  MetaOptions({this.multiple = false});
  MetaOptions.fromJson(Map<String, dynamic> json)
      : items =
            ListUtil.map(json['items'], (v, i) => MetaOptionsItem.fromJson(v)),
        multiple = json['multiple'];

  Map<String, dynamic> get toJson {
    return {
      'items': ListUtil.map(items, (v, i) => v.toJson),
      'multiple': multiple
    };
  }

  update(Map<String, dynamic> json) {
    if (json['items'] != null && json['items'] is List<dynamic>) {
      items =
          ListUtil.map(json['items'], (v, i) => MetaOptionsItem.fromJson(v));
    }
    if (json['multiple'] != null && json['multiple'] is bool) {
      multiple = json['multiple'];
    }
  }
}

// ignore_for_file: non_constant_identifier_names
class Meta {
  MetaNumber number = MetaNumber();
  MetaDate date = MetaDate();
  MetaQrCode qrCode = MetaQrCode();
  MetaOptions options = MetaOptions();
  MetaBoolean boolean = MetaBoolean();
  Meta();
  Meta.fromJson(Map<String, dynamic> json)
      : number = MetaNumber.fromJson(json['number']),
        date = MetaDate.fromJson(json['date']),
        qrCode = MetaQrCode.fromJson(json['qrCode']),
        options = MetaOptions.fromJson(json['options']),
        boolean = MetaBoolean.fromJson(json);

  get toJson {
    return {
      'number': number.toJson,
      'date': date.toJson,
      'qrCode': qrCode.toJson,
      'options': options.toJson,
      'boolean': boolean.toJson
    };
  }

  updateMeta(Map<String, dynamic> json) {
    if (json['number'] != null) {
      number.update(json['number']);
    }
    if (json['date'] != null) {
      date.update(json['date']);
    }
    if (json['qrCode'] != null) {
      qrCode.update(json['qrCode']);
    }
    if (json['boolean'] != null) {
      boolean.update(json['boolean']);
    }
    if (json['options'] != null) {
      options.update(json['options']);
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
  int height;
  Map<String, dynamic> values = {};
  MetaEntry(this.id, {this.height = 36});

  get toJson {
    return {'id': id, 'values': values, 'height': height};
  }

  MetaEntry.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        height = json['height'],
        values = json['values'];
}

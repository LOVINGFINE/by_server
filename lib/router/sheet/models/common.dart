import 'package:by_server/utils/lodash.dart';
import 'package:by_server/utils/md5.dart';

class CommonWorkbook {
  String id = Md5EnCode('common-workbook-${DateTime.now()}').to16Bit;
  String name;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  Map<String, Cell> data = {};
  Map<String, ConfigColumn> columns = {};
  Map<String, ConfigRow> rows = {};
  CommonWorkbook({this.name = 'Sheet1'});
  CommonWorkbook.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        createdTime = json['createdTime'],
        updatedTime = json['updatedTime'],
        columns = MapUtil.map<String, ConfigColumn>(
            json['columns'], (e, i) => ConfigColumn.fromJson(e)),
        rows = MapUtil.map<String, ConfigRow>(
            json['rows'], (e, i) => ConfigRow.fromJson(e)),
        data = Map.from(
            json['data'].map((key, v) => MapEntry(key, Cell.fromJson(v))));
  get toJson {
    return {
      'id': id,
      'name': name,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'columns': MapUtil.map<String, Map<String, dynamic>>(
          columns, (e, i) => e.toJson),
      'rows':
          MapUtil.map<String, Map<String, dynamic>>(rows, (e, i) => e.toJson),
      'data': Map.from(data.map((key, v) => MapEntry(key, v.toJson)))
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

class WorkbookConfig {
  Map<String, ConfigColumn> columns = {};
  Map<String, ConfigRow> rows = {};
  WorkbookConfig();
  WorkbookConfig.fromJson(Map<String, dynamic> json)
      : columns = MapUtil.map<String, ConfigColumn>(
            json['columns'], (e, i) => ConfigColumn.fromJson(e)),
        rows = MapUtil.map<String, ConfigRow>(
            json['rows'], (e, i) => ConfigRow.fromJson(e));

  Map<String, dynamic> get toJson {
    Map<String, dynamic> map = {
      'columns': MapUtil.map<String, Map<String, dynamic>>(
          columns, (e, i) => e.toJson),
      'rows':
          MapUtil.map<String, Map<String, dynamic>>(rows, (e, i) => e.toJson),
    };
    return map;
  }

  static getIndex(String key) {
    return int.parse(key);
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

import 'package:by_dart_server/utils/lodash.dart';
import 'package:by_dart_server/utils/md5.dart';
import 'final.dart';

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
  dynamic value;
  Map<String, dynamic> style = FinalCell.style;
  List<Comment> comments = [];
  Cell({this.value = ''});
  Cell.fromJson(Map<String, dynamic> json)
      : value = json['value'] ?? '',
        style = json['style'] ?? FinalCell.style,
        comments = ListUtil.map<Comment>(
            json['comments'] ?? [], (v, i) => Comment.fromJson(v));
  get toJson {
    return {
      'value': value,
      'style': style,
      'comments': comments.map((e) => e.toJson).toList()
    };
  }
}

class Workbook {
  String id = Md5EnCode('workbook-${DateTime.now()}').to16Bit;
  String name;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  Map<String, Cell> data = {};
  Map<String, ConfigColumn> columns = {};
  Map<String, ConfigRow> rows = {};
  Workbook({this.name = 'Sheet1'});
  Workbook.fromJson(Map<String, dynamic> json)
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
      'lastOpenTime': lastOpenTime
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

class SheetTemplate {
  String id = Md5EnCode('Template-${DateTime.now()}').to16Bit;
  String title;
  String description;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  String categoryId;
  SheetTemplate(this.categoryId, {this.title = '空白模版', this.description = ''});

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'title': title,
      'createdTime': createdTime,
      'updatedTime': updatedTime,
      'categoryId': categoryId,
      'description': description
    };
  }

  SheetTemplate.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        categoryId = json['categoryId'],
        createdTime = json['createdTime'],
        updatedTime = json['updatedTime'];
}

class SheetTemplateCategory {
  String id = Md5EnCode('TemplateCategory-${DateTime.now()}').to16Bit;
  String title;
  String description;
  SheetTemplateCategory({this.title = '未知分类', this.description = ''});

  Map<String, dynamic> get toJson {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  SheetTemplateCategory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'];
}

import 'package:by_server/utils/md5.dart';

class SheetTemplate {
  String id = Md5EnCode('Template-${DateTime.now()}').to16Bit;
  String title;
  String description;
  String createdTime = DateTime.now().toString();
  String updatedTime = DateTime.now().toString();
  String categoryId;
  SheetTemplate(this.categoryId, {this.title = '', this.description = ''});

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

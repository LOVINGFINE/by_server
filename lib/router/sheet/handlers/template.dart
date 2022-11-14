import 'package:by_dart_server/main.dart';
import 'package:by_dart_server/utils/lodash.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_dart_server/helper/router_helper.dart';
import '../model.dart';

class SheetTemplateRouter extends RouterUserHelper {
  String? templateId;
  DbCollection templateDb = mongodb.collection('SHEET_TEMPLATES');
  DbCollection categoryDb = mongodb.collection('SHEET_TEMPLATE_CATEGORIES');
  SheetTemplateRouter(Request request, {this.templateId}) : super(request);

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    if (templateId == null) {
      var method = request.method.toUpperCase();
      if (method != 'GET' && method != 'POST') {
        return response(400, message: 'params not found');
      }
    }
    return handle();
  }

  @override
  Future<Response> get() async {
    if (templateId != null) {
      var data = await templateDb.findOne(where.eq('id', templateId));
      if (data != null) {
        return response(200, data: data);
      }
      return response(400, message: 'template [$templateId] not found');
    }
    var categories =
        await categoryDb.find(where.excludeFields(['_id'])).toList();
    SelectorBuilder selector =
        where.match('name', query['search'] ?? '').excludeFields(['_id']);
    var list = await templateDb.find(selector).toList();

    List<Map<String, dynamic>> data = ListUtil.map(categories, (ele, i) {
      var records = ListUtil.filter(list, (item, i) {
        return item['categoryId'] == ele['id'];
      });
      return {
        'id': ele['id'],
        'title': ele['title'],
        'description': ele['description'],
        'records': records
      };
    });
    return response(200,
        data: ListUtil.filter(data, (item, i) {
          return item['records'].length > 0;
        }));
  }

  @override
  Future<Response> post() async {
    if (templateId != null) {
      // 根据模版创建表格
      return response(200, data: {});
    } else {
      String categoryId = body.json['categoryId'] ?? '';
      var cat = await categoryDb.findOne(where.eq('id', categoryId));
      if (cat == null) {
        return response(400, message: 'category [$categoryId] not found');
      }
      String title = body.json['title'] ?? '';
      String description = body.json['description'] ?? '';
      var template =
          SheetTemplate(categoryId, title: title, description: description);
      var status = await templateDb.insertOne(template.toJson);
      if (status.isFailure) {
        return response(500, message: '添加失败');
      }
      return response(200, data: template.toJson);
    }
  }

  @override
  Future<Response> patch() async {
    return response(200, message: 'ok', data: {});
  }

  @override
  Future<Response> delete() async {
    var sheetTemp = await templateDb.findOne(where.eq('id', templateId));
    if (sheetTemp == null) {
      return response(400, message: 'template [$templateId] not found');
    }
    var status = await templateDb.deleteOne(where.eq('id', templateId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    return response(200, message: 'ok');
  }
}
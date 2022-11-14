import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../model.dart';

class SheetTemplateCategoryRouter extends RouterUserHelper {
  String? categoryId;
  DbCollection categoryDb = mongodb.collection('SHEET_TEMPLATE_CATEGORIES');
  SheetTemplateCategoryRouter(Request request, {this.categoryId})
      : super(request);

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    if (categoryId == null) {
      var method = request.method.toUpperCase();
      if (method != 'GET' && method != 'POST') {
        return response(400, message: 'params not found');
      }
    }
    return handle();
  }

  @override
  Future<Response> get() async {
    SelectorBuilder selector =
        where.match('name', query['search'] ?? '').excludeFields(['_id']);
    var list = await categoryDb.find(selector).toList();
    return response(200, data: list);
  }

  @override
  Future<Response> post() async {
    String title = body.json['title'] ?? '未命名分类';
    String description = body.json['description'] ?? '';
    SheetTemplateCategory category =
        SheetTemplateCategory(title: title, description: description);
    var status = await categoryDb.insertOne(category.toJson);
    if (status.isFailure) {
      return response(500, message: '添加失败');
    }
    return response(200, data: category.toJson);
  }

  @override
  Future<Response> patch() async {
    return response(200, message: 'ok', data: {});
  }

  @override
  Future<Response> delete() async {
    var status = await categoryDb.deleteOne(where.eq('id', categoryId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    return response(200, message: 'ok');
  }
}

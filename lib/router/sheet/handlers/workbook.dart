import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../model.dart';

class SheetWorkbookRouter extends RouterHelper {
  String sheetId;
  String workbookId;
  Sheet sheet = Sheet();
  Workbook workbook = Workbook();
  DbCollection sheetDb = mongodb.collection('SHEETS');
  DbCollection sheetWorkbookDb = mongodb.collection('SHEETS_WORKBOOKS');

  SheetWorkbookRouter(Request request, this.sheetId, {this.workbookId = ''})
      : super(request) {
    sheetWorkbookDb = mongodb.collection('SHEETS_WORKBOOKS_$sheetId');
  }

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    var json = await sheetDb.findOne(where.eq('id', sheetId));
    if (json == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    sheet = Sheet.fromJson(json);
    var jsonWb = await sheetWorkbookDb.findOne(where.eq('id', workbookId));
    if (jsonWb == null) {
      var method = request.method.toUpperCase();
      if (method != 'GET' && method != 'POST') {
        return response(400, message: 'workbook [$workbookId] not found');
      }
    } else {
      workbook = Workbook.fromJson(jsonWb);
    }
    return handle();
  }

  Future<void> updateSheet() async {
    sheet.updatedTime = DateTime.now().toString();
    await sheetDb.updateOne(where.eq('id', sheetId), {
      '\$set': {
        'updatedTime': sheet.updatedTime,
      }
    });
  }

  @override
  Future<Response> get() async {
    if (workbookId == '') {
      SelectorBuilder selector = where
          .match('name', query['search'] ?? '')
          .excludeFields(['_id', 'columns', 'rows', 'data']);
      var workbooks = await sheetWorkbookDb.find(selector).toList();
      return response(200, message: 'ok', data: workbooks);
    }
    return response(200, message: 'ok', data: workbook.toJson);
  }

  @override
  Future<Response> post() async {
    int count = await sheetWorkbookDb.count();
    String name = body.json['name'] ?? 'Sheet${count + 1}';
    Workbook target = Workbook(name: name);
    var status = await sheetWorkbookDb.insertOne(target.toJson);
    if (status.isFailure) {
      return response(500, message: '创建 workbook 失败');
    }
    return response(200, message: 'ok', data: target.toJson);
  }

  @override
  Future<Response> patch() async {
    if (body.json['name'] != null) {
      var status = await sheetDb.updateOne(where.eq('id', workbookId), {
        '\$set': {'updatedTime': sheet.updatedTime, 'name': body.json['name']}
      });
      if (status.isFailure) {
        return response(500, message: '更新失败');
      }
      workbook.name = body.json['name'];
      await updateSheet();
      return response(200, message: 'ok', data: workbook.toJson);
    }
    return response(400, message: 'not params');
  }

  @override
  Future<Response> delete() async {
    var status = await sheetWorkbookDb.deleteOne(where.eq('id', sheetId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    await updateSheet();
    return response(200, message: 'ok');
  }
}

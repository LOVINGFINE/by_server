import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetRouter extends RouterUserHelper {
  Sheet? sheet;
  String? sheetId;
  DbCollection sheetDb = mongodb.collection('sheets');
  SheetRouter(Request request, {this.sheetId}) : super(request);

  Future<Sheet?> createSheet(String name, {SheetType? type}) async {
    Sheet sheet =
        Sheet(name: name, owner: user.id, type: type ?? SheetType.common);
    var status = await sheetDb.insertOne(sheet.toJson);
    if (!status.isFailure) {
      if (type == SheetType.meta) {
        // meta
        DbCollection metaWorkbookDb = mongodb.collection('meta_workbooks');
        int count = await metaWorkbookDb.count();
        MetaWorkbook wb = MetaWorkbook(
            sheetId: sheet.id, code: MetaWorkbook.numberToCode(count));
        await metaWorkbookDb.insertOne(wb.toJson);
      } else {
        // 创建 工作表
        DbCollection newSheetWorkbookDb =
            mongodb.collection('sheet_workbooks_${sheet.id}');
        Workbook wb = Workbook(name: 'Sheet1');
        await newSheetWorkbookDb.insertOne(wb.toJson);
      }
      return sheet;
    }
    return Future(() => null);
  }

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    if (sheetId != null) {
      var json = await sheetDb.findOne(where.eq('id', sheetId));
      if (json != null) {
        sheet = Sheet.fromJson(json);
      }
    }
    return handle();
  }

  Future<Response> getSignalSheet() async {
    if (sheet != null) {
      sheet?.lastOpenTime = DateTime.now().toString();
      await sheetDb.updateOne(where.eq('id', sheetId), {
        '\$set': {
          'lastOpenTime': sheet?.lastOpenTime,
        }
      });
      return response(200, message: 'ok', data: sheet?.toJson);
    }
    return response(400, message: 'error', data: 'sheet [$sheetId] not found');
  }

  Future<Response> getSheetByScope() async {
    SelectorBuilder selector = where
        .eq('owner', user.id)
        .or(where.match('share', user.id))
        .match('name', query['search'] ?? '')
        .excludeFields(['_id']);

    if (query['page'] == null || query['pageSize'] == null) {
      // 不分页
      List<Map> data = await sheetDb.find(selector).toList();

      return response(200, message: 'ok', data: data);
    } else {
      // 分页
      int page = int.parse(query['page'] ?? '');
      int pageSize = int.parse(query['pageSize'] ?? '');
      List<Map> list = await sheetDb
          .find(selector.skip((page - 1) * pageSize).limit(pageSize))
          .toList();
      int total = await sheetDb.count(selector);
      return response(200, message: 'ok', data: {
        'list': list,
        'page': page,
        'pageSize': pageSize,
        'total': total
      });
    }
  }

  @override
  Future<Response> get() async {
    if (sheetId != null) {
      return getSignalSheet();
    } else {
      return getSheetByScope();
    }
  }

  @override
  Future<Response> post() async {
    String name = body.json['name'] ?? '未命名';
    SheetType? type = SheetType.values[0].toType(body.json['type'] ?? '');
    Sheet? sheet = await createSheet(name, type: type);
    if (sheet == null) {
      return response(500, message: '创建失败');
    }
    return response(200, message: 'ok', data: sheet.toJson);
  }

  @override
  Future<Response> patch() async {
    if (sheet == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    if (body.json['name'] != null) {
      sheet?.name = body.json['name'];
    }
    sheet?.updatedTime = DateTime.now().toString();
    var status = await sheetDb.updateOne(where.eq('id', sheetId), {
      '\$set': {
        'updatedTime': sheet?.updatedTime,
        'name': sheet?.name,
      }
    });
    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    return response(200, message: 'ok', data: sheet?.toJson);
  }

  @override
  Future<Response> delete() async {
    if (sheet == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    var status = await sheetDb.deleteOne(where.eq('id', sheetId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    if (sheet?.type == SheetType.meta) {
      DbCollection metaWorkbookDb = mongodb.collection('meta_workbooks');
      await metaWorkbookDb.deleteOne(where.eq('sheetId', sheetId));
    } else {
      DbCollection sheetWorkbookDb =
          mongodb.collection('sheet_workbooks_$sheetId');
      await sheetWorkbookDb.drop();
    }
    return response(200, message: 'ok');
  }
}

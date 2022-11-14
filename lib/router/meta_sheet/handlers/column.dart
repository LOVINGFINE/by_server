import 'package:by_dart_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_dart_server/helper/router_helper.dart';
import '../model.dart';

class SheetColumnRouter extends RouterHelper {
  String sheetId;
  DbCollection metaSheetDb = mongodb.collection('META_SHEETS');
  SheetColumnRouter(Request request, this.sheetId) : super(request);

  getSheet() async {
    var json = await metaSheetDb.findOne(where.eq('id', sheetId));
    if (json != null) {
      MetaSheet sheet = MetaSheet.fromJson(json);
      return sheet;
    }
  }

  @override
  patch() async {
    MetaSheet? sheet = getSheet();
    if (sheet == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    if (body.json['name'] != null) {
      sheet.name = body.json['name'];
    }
    sheet.updatedTime = DateTime.now().toString();
    var status = await metaSheetDb.updateOne(where.eq('id', sheetId), {
      '\$set': {'updatedTime': sheet.updatedTime, 'name': sheet.name}
    });
    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    return response(200, message: 'ok', data: sheet.toJson);
  }

  @override
  delete() async {
    MetaSheet? sheet = getSheet();
    if (sheet == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    var status = await metaSheetDb.deleteOne(where.eq('id', sheetId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    return response(200, message: 'ok');
  }
}

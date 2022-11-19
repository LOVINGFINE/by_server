import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/utils/lodash.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetMetaWorkbookRouter extends RouterHelper {
  String sheetId;
  Sheet sheet = Sheet();
  MetaWorkbook metaWorkbook = MetaWorkbook();
  DbCollection sheetDb = mongodb.collection('sheets');
  DbCollection metaWorkbookDb = mongodb.collection('meta_workbooks');
  String command;
  SheetMetaWorkbookRouter(Request request, this.sheetId, {this.command = ''})
      : super(request);

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    var json = await sheetDb.findOne(where.eq('id', sheetId));
    var jsonWb = await metaWorkbookDb.findOne(where.eq('sheetId', sheetId));
    if (json == null || jsonWb == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    sheet = Sheet.fromJson(json);
    metaWorkbook = MetaWorkbook.fromJson(jsonWb);
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
    return response(200, message: 'ok', data: metaWorkbook.toJson);
  }

  Future<Response> patchColumns() async {
    await updateSheet();
    return response(200, message: 'ok', data: metaWorkbook.columns);
  }

  Future<Response> patchEntries() async {
    await updateSheet();
    return response(200, message: 'ok', data: metaWorkbook.entries);
  }

  @override
  Future<Response> patch() async {
    switch (command) {
      case 'columns':
        return patchColumns();
      case 'entries':
        return patchEntries();
      default:
        return response(400, message: 'command [$command] not found');
    }
  }
}

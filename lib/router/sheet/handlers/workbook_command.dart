import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/utils/lodash.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

enum WorkbookCommand {
  none,
  column,
  row,
  data,
}

extension ParseMetaType on WorkbookCommand {
  bool isTypeString(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  WorkbookCommand? stringToType(String type) {
    return ListUtil.find(
        WorkbookCommand.values, (v, i) => v.toTypeString() == type);
  }
}

class SheetWorkbookCommandRouter extends RouterHelper {
  String sheetId;
  String workbookId;
  Sheet sheet = Sheet();
  Workbook workbook = Workbook();
  WorkbookCommand command = WorkbookCommand.none;
  DbCollection sheetDb = mongodb.collection('sheets');
  DbCollection sheetWorkbookDb = mongodb.collection('sheet_workbooks');
  SheetWorkbookCommandRouter(
      Request request, this.sheetId, this.workbookId, String action)
      : super(request) {
    sheetWorkbookDb = mongodb.collection('sheet_workbooks_$sheetId');
    WorkbookCommand? t = command.stringToType(action);
    if (t != null) {
      command = t;
    }
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
      return response(400,
          message: 'sheet [${sheet.name}] workbook [$workbookId]  not found');
    }
    workbook = Workbook.fromJson(jsonWb);
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

  Future<Response> patchConfigColumn() async {
    Map<String, dynamic> configColumn = body.json;
    configColumn.forEach((key, value) {
      if (workbook.columns[key] != null) {
        workbook.columns[key]?.width =
            value['width'] ?? workbook.columns[key]?.width;
      } else {
        workbook.columns
            .addAll({key: ConfigColumn(width: value['width'] ?? 120)});
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.columns, (e, i) => e.toJson);
    workbook.updatedTime = DateTime.now().toString();
    var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'updatedTime': workbook.updatedTime, 'columns': targetJson}
    });
    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    await updateSheet();
    return response(200, message: 'ok', data: targetJson);
  }

  Future<Response> patchConfigRow() async {
    Map<String, dynamic> configRow = body.json;
    configRow.forEach((key, value) {
      if (workbook.rows[key] != null) {
        workbook.rows[key]?.height =
            value['height'] ?? workbook.rows[key]?.height;
      } else {
        workbook.rows.addAll({key: ConfigRow(height: value['height'] ?? 28)});
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.rows, (e, i) => e.toJson);
    workbook.updatedTime = DateTime.now().toString();
    var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'updatedTime': workbook.updatedTime, 'rows': targetJson}
    });

    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    await updateSheet();
    return response(200, message: 'ok', data: targetJson);
  }

  Future<Response> patchDataSource() async {
    Map<String, dynamic> dataJson = body.json;
    dataJson.forEach((key, item) {
      if (workbook.data[key] != null) {
        if (item['value'] != null) {
          workbook.data[key]?.value = item['value'];
        }
        if (item['style'] != null) {
          workbook.data[key]?.style = item['style'];
        }
      } else {
        workbook.data[key] = Cell.fromJson(item);
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.data, (e, i) => e.toJson);
    workbook.updatedTime = DateTime.now().toString();
    var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'updatedTime': workbook.updatedTime, 'data': targetJson}
    });
    if (status.isFailure) {
      return response(500, message: '更新失败');
    }
    await updateSheet();
    return response(200, message: 'ok', data: targetJson);
  }

  @override
  Future<Response> patch() async {
    switch (command) {
      case WorkbookCommand.column:
        return patchConfigColumn();
      case WorkbookCommand.row:
        return patchConfigRow();
      case WorkbookCommand.data:
        return patchDataSource();
      default:
        return response(400, message: 'not found command');
    }
  }
}

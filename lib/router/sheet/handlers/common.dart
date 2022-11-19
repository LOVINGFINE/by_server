import 'package:by_server/main.dart';
import 'package:by_server/utils/lodash.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetCommonWorkbookRouter extends RouterHelper {
  String sheetId;
  String workbookId;
  Sheet sheet = Sheet();
  Workbook workbook = Workbook();
  DbCollection sheetDb = mongodb.collection('sheets');
  String command;
  SheetCommonWorkbookRouter(Request request, this.sheetId,
      {this.workbookId = '', this.command = ''})
      : super(request);

  DbCollection get sheetWorkbookDb {
    return mongodb.collection('sheet_workbooks_$sheetId');
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

  Future<Response> patchWorkbookAbout() async {
    if (body.json['name'] != null) {
      var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
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
  Future<Response> patch() async {
    switch (command) {
      case 'column':
        return patchConfigColumn();
      case 'row':
        return patchConfigRow();
      case 'data':
        return patchDataSource();
      default:
        return patchWorkbookAbout();
    }
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

import 'package:by_server/main.dart';
import 'package:by_server/utils/lodash.dart';
import 'package:by_server/utils/md5.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetWorkbooksRouter extends RouterHelper {
  String sheetId;
  Sheet sheet = Sheet();
  DbCollection sheetDb = mongodb.collection('sheets');
  SheetWorkbooksRouter(Request request, this.sheetId) : super(request);

  DbCollection get workbookDb {
    return mongodb.collection('workbooks_$sheetId');
  }

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    var json = await sheetDb.findOne(where.eq('id', sheetId));
    if (json == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    sheet = Sheet.fromJson(json);
    return handle();
  }

  @override
  Future<Response> get() async {
    SelectorBuilder selector = where
        .match('name', query['search'] ?? '')
        .fields([
      'id',
      'createdTime',
      'updatedTime',
      'name',
      'type'
    ]).excludeFields(['_id']);
    var workbooks = await workbookDb.find(selector).toList();
    return response(200, message: 'ok', data: workbooks);
  }

  Future<Workbook?> insertWorkbook({name = '', type = 'common'}) async {
    int count = await workbookDb.count();
    String name = body.json['name'] ?? 'Sheet${count + 1}';
    String typeString = body.json['type'] ?? 'common';
    WorkbookType type = WorkbookType.common.toType(typeString);
    Workbook target =
        Workbook(name: name, type: type, code: Workbook.numberToCode(count));
    var status = await workbookDb.insertOne(target.toJson);
    if (!status.isFailure) {
      return target;
    }
    return null;
  }

  @override
  Future<Response> post() async {
    Workbook? newWorkbook =
        await insertWorkbook(name: body.json['name'], type: body.json['type']);
    if (newWorkbook == null) {
      return response(500, message: '创建 workbook 失败');
    }
    if (newWorkbook.type == WorkbookType.common) {
      return response(200, message: 'ok', data: newWorkbook.toCommonJson);
    } else {
      return response(200, message: 'ok', data: newWorkbook.toMetaJson);
    }
  }
}

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
    return mongodb.collection('workbooks_$sheetId');
  }

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    var json = await sheetDb.findOne(where.eq('id', sheetId));
    if (json == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    var jsonWb = await sheetWorkbookDb.findOne(where.eq('id', workbookId));
    if (jsonWb == null) {
      return response(400, message: 'workbook [$workbookId] not found');
    }
    sheet = Sheet.fromJson(json);
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

  @override
  Future<Response> get() async {
    switch (command) {
      case 'data':
        return response(200,
            message: 'ok',
            data: Map.from(
                workbook.data.map((key, v) => MapEntry(key, v.toJson))));
      default:
        return response(200, message: 'ok', data: workbook.toCommonJson);
    }
  }

  Future<Response> patchConfigColumn() async {
    Map<String, dynamic> configColumn = body.json;
    configColumn.forEach((key, value) {
      if (workbook.config.column[key] != null) {
        workbook.config.column[key]?.width =
            value['width'] ?? workbook.config.column[key]?.width;
      } else {
        workbook.config.column
            .addAll({key: ConfigColumn(width: value['width'] ?? 120)});
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.config.column, (e, i) => e.toJson);
    var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'config': workbook.config.toJson}
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
      if (workbook.config.row[key] != null) {
        workbook.config.row[key]?.height =
            value['height'] ?? workbook.config.row[key]?.height;
      } else {
        workbook.config.row
            .addAll({key: ConfigRow(height: value['height'] ?? 28)});
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.config.row, (e, i) => e.toJson);
    var status = await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'config': workbook.config.toJson}
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
          workbook.data[key]?.updateStyle(item['style']);
        }
      } else {
        workbook.data[key] = Cell.fromJson(item);
      }
    });
    var targetJson = MapUtil.map<String, Map<String, dynamic>>(
        workbook.data, (e, i) => e.toJson);
    await sheetWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'data': targetJson}
    });
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
    var count = await sheetWorkbookDb.count();
    if (count > 1) {
      var status = await sheetWorkbookDb.deleteOne(where.eq('id', workbookId));
      if (!status.isFailure) {
        await updateSheet();
        return response(200, message: 'ok');
      }
    }
    return response(500, message: '删除失败');
  }
}

class SheetMetaWorkbookRouter extends RouterHelper {
  String sheetId;
  Sheet sheet = Sheet();
  Workbook workbook = Workbook();
  DbCollection sheetDb = mongodb.collection('sheets');
  String command;
  String workbookId;
  SheetMetaWorkbookRouter(Request request, this.sheetId,
      {this.command = '', this.workbookId = ''})
      : super(request);

  DbCollection get metaWorkbookDb {
    return mongodb.collection('workbooks_$sheetId');
  }

  @override
  Future<Response> before(Future<Response> Function() handle) async {
    var json = await sheetDb.findOne(where.eq('id', sheetId));
    var jsonWb = await metaWorkbookDb.findOne(where.eq('id', workbookId));
    if (json == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    if (jsonWb == null) {
      var method = request.method.toUpperCase();
      if (method != 'POST') {
        return response(400, message: 'workbook [$workbookId] not found');
      }
    } else {
      workbook = Workbook.fromJson(jsonWb);
    }
    sheet = Sheet.fromJson(json);
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

  Future<Response> getColumns() async {
    return response(200,
        message: 'ok',
        data: ListUtil.map(workbook.columns, (e, i) => e.toJson));
  }

  Future<Response> getEntries() async {
    int? form = int.tryParse(query['form'] ?? '');
    int? to = int.tryParse(query['to'] ?? '');
    if (form != null && to != null) {
      return response(200, message: 'ok', data: {
        'form': form,
        'to': to,
        'records': ListUtil.map(
            ListUtil.filter(workbook.entries, (e, i) => i >= form && i <= to),
            (e, i) => e.toJson)
      });
    }
    int page = int.parse(query['page'] ?? '1');
    int? pageSize = int.tryParse(query['pageSize'] ?? '');
    if (pageSize != null) {
      return response(200, message: 'ok', data: {
        'form': form,
        'to': to,
        'records': ListUtil.map(
            ListUtil.filter(workbook.entries,
                (e, i) => i >= page * pageSize && i <= (page + 1) * pageSize),
            (e, i) => e.toJson)
      });
    }
    return response(200,
        message: 'ok',
        data: ListUtil.map(workbook.entries, (e, i) => e.toJson));
  }

  Future<Response> getWorkbook() async {
    if (workbookId == '') {
      SelectorBuilder selector = where
          .match('name', query['search'] ?? '')
          .excludeFields(
              ['_id', 'columns', 'entries', 'createdTime', 'updatedTime']);
      var workbooks = await metaWorkbookDb.find(selector).toList();
      return response(200, message: 'ok', data: workbooks);
    }
    return response(200, message: 'ok', data: workbook.toMetaJson);
  }

  @override
  Future<Response> get() async {
    switch (command) {
      case 'columns':
        return getColumns();
      case 'entries':
        return getEntries();
      default:
        return getWorkbook();
    }
  }

  Future<Response> patchColumns() async {
    var columnMap = body.json;
    List<MetaColumn> data = [];
    if (columnMap is Map<String, dynamic>) {
      for (var i = 0; i < workbook.columns.length; i++) {
        String code = workbook.columns[i].code;
        if (columnMap[code] != null) {
          if (columnMap[code]['title'] != null) {
            workbook.columns[i].title = columnMap[code]['title'];
          }
          if (columnMap[code]['width'] != null &&
              columnMap[code]['width'] is int) {
            workbook.columns[i].width = columnMap[code]['width'];
          }
          if (columnMap[code]['type'] != null) {
            var type = MetaType.Text.stringToType(columnMap[code]['type']);
            if (type != null) {
              workbook.columns[i].type = type;
            }
          }
          if (columnMap[code]['meta'] != null) {
            workbook.columns[i].meta.updateMeta(columnMap[code]['meta']);
          }
          data.add(workbook.columns[i]);
        }
      }
    }
    await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'columns': ListUtil.map(workbook.columns, (e, i) => e.toJson)}
    });
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(data, (e, i) => e.toJson));
  }

  Future<Response> patchEntries() async {
    var entryMap = body.json;
    List<MetaEntry> data = [];
    if (entryMap is Map<String, dynamic>) {
      entryMap.forEach((key, item) {
        var entry = workbook.updateEntryValues(key,
            json: item['values'], height: item['height']);
        if (entry != null) {
          data.add(entry);
        }
      });
    }
    await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'entries': ListUtil.map(workbook.entries, (e, i) => e.toJson)}
    });
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(data, (e, i) => e.toJson));
  }

  Future<Response> patchAbout() async {
    var showRowCount = body.json['showRowCount'];
    var name = body.json['name'];
    if (showRowCount != null && showRowCount is bool) {
      workbook.showRowCount = showRowCount;
    }
    if (name != null && name is String) {
      workbook.name = name;
    }
    workbook.updatedTime = DateTime.now().toString();
    var status = await metaWorkbookDb
        .updateOne(where.eq('id', workbookId), {'\$set': workbook.toMetaJson});
    if (status.isFailure) {
      return response(500, message: 'update $sheetId error');
    }
    await updateSheet();
    return response(200, message: 'ok', data: workbook.toMetaJson);
  }

  @override
  Future<Response> patch() async {
    switch (command) {
      case 'columns':
        return patchColumns();
      case 'entries':
        return patchEntries();
      default:
        return patchAbout();
    }
  }

  Future<Response> postColumns() async {
    var columns = body.json;
    if (columns is List) {
      for (var i = 0; i < columns.length; i++) {
        int width = int.parse(columns[i]['width'] ?? '180');
        String code = '${workbook.code}${workbook.columns.length + 1}';
        workbook.columns.add(MetaColumn(code,
            title: columns[i]['title'] ?? "未命名", width: width));
      }
    }
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'columns': ListUtil.map(workbook.columns, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'create $sheetId meta columns error');
    }
    await updateSheet();
    return response(200,
        message: 'ok',
        data: ListUtil.map(workbook.columns, (e, i) => e.toJson));
  }

  Future<Response> postEntries() async {
    var entries = body.json;
    var list = [];
    if (entries is List) {
      for (var i = 0; i < entries.length; i++) {
        var entry = MetaEntry(Md5EnCode(DateTime.now().toString()).to16Bit);
        entry.values = workbook.getEntryValues(entries[i]);
        workbook.entries.insert(0, entry);
        list.insert(0, entry);
      }
    }
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'entries': ListUtil.map(workbook.entries, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'create $sheetId entries error');
    }
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(list, (e, i) => e.toJson));
  }

  @override
  Future<Response> post() async {
    switch (command) {
      case 'columns':
        return postColumns();
      case 'entries':
        return postEntries();
      default:
        {
          var count = await metaWorkbookDb.count();
          var name = body.json['name'] ?? 'Sheet${count + 1}';
          Workbook wb =
              Workbook(name: name, code: Workbook.numberToCode(count));
          await metaWorkbookDb.insertOne(wb.toJson);
          return response(200, message: 'ok', data: wb.toMetaJson);
        }
    }
  }

  Future<Response> deleteColumns() async {
    List<dynamic> codes = body.json ?? [];
    for (var i = 0; i < codes.length; i++) {
      workbook.columns.removeWhere((ele) => ele.code == codes[i]);
    }
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'columns': ListUtil.map(workbook.columns, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'delete $sheetId columns error');
    }
    await updateSheet();
    return response(200, message: 'ok');
  }

  Future<Response> deleteEntries() async {
    List<dynamic> ids = body.json ?? [];
    for (var i = 0; i < ids.length; i++) {
      workbook.entries.removeWhere((ele) => ele.id == ids[i]);
    }
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'entries': ListUtil.map(workbook.entries, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'delete $sheetId entries error');
    }
    await updateSheet();
    return response(200, message: 'ok');
  }

  Future<Response> deleteWorkbook() async {
    var count = await metaWorkbookDb.count();
    if (count > 1) {
      var status = await metaWorkbookDb.deleteOne(where.eq('id', workbookId));
      if (!status.isFailure) {
        await updateSheet();
        return response(200, message: 'ok');
      }
    }
    return response(500, message: '删除失败');
  }

  @override
  Future<Response> delete() async {
    switch (command) {
      case 'columns':
        return deleteColumns();
      case 'entries':
        return deleteEntries();
      default:
        return deleteWorkbook();
    }
  }
}

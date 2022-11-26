import 'package:by_server/main.dart';
import 'package:by_server/utils/md5.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:by_server/utils/lodash.dart';
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetMetaWorkbookRouter extends RouterHelper {
  String sheetId;
  Sheet sheet = Sheet();
  MetaWorkbook workbook = MetaWorkbook();
  DbCollection sheetDb = mongodb.collection('sheets');
  String command;
  String workbookId;
  SheetMetaWorkbookRouter(Request request, this.sheetId,
      {this.command = '', this.workbookId = ''})
      : super(request);

  DbCollection get metaWorkbookDb {
    return mongodb.collection('meta_workbooks_$sheetId');
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
      if (method != 'GET' && method != 'POST') {
        return response(400, message: 'workbook [$workbookId] not found');
      }
    } else {
      workbook = MetaWorkbook.fromJson(jsonWb);
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
    return response(200, message: 'ok', data: workbook.toDataJson);
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
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'columns': ListUtil.map(workbook.columns, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'update $sheetId entries error');
    }
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(data, (e, i) => e.toJson));
  }

  Future<Response> patchEntries() async {
    var entryMap = body.json;
    List<MetaEntry> data = [];
    if (entryMap is Map<String, dynamic>) {
      entryMap.forEach((key, value) {
        var entry = workbook.updateEntryValues(key, value);
        if (entry != null) {
          data.add(entry);
        }
      });
    }
    var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
      '\$set': {'entries': ListUtil.map(workbook.entries, (e, i) => e.toJson)}
    });
    if (status.isFailure) {
      return response(500, message: 'update $sheetId entries error');
    }
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(data, (e, i) => e.toJson));
  }

  Future<Response> patchAbout() async {
    var showRowCount = body.json['showRowCount'];
    if (showRowCount != null && showRowCount is bool) {
      var status = await metaWorkbookDb.updateOne(where.eq('id', workbookId), {
        '\$set': {'showRowCount': workbook.showRowCount}
      });
      if (status.isFailure) {
        return response(500, message: 'update $sheetId error');
      }
    }
    await updateSheet();
    return response(200, message: 'ok', data: workbook.toDataJson);
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
          MetaWorkbook wb =
              MetaWorkbook(name: name, code: MetaWorkbook.numberToCode(count));
          await metaWorkbookDb.insertOne(wb.toJson);
          return response(200, message: 'ok', data: wb.toDataJson);
        }
    }
  }

  Future<Response> deleteColumns() async {
    var codeString = query['code'] ?? '';
    List<String> codes = codeString.split(',');
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
    var idsString = query['id'] ?? '';
    List<String> ids = idsString.split(',');
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

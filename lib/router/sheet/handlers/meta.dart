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

  get metaJson {
    return {'code': metaWorkbook.code, 'sheetId': metaWorkbook.sheetId};
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
    return response(200, message: 'ok', data: metaWorkbook.columnsJson);
  }

  Future<Response> getEntries() async {
    int? form = int.tryParse(query['form'] ?? '');
    int? to = int.tryParse(query['to'] ?? '');
    if (form != null && to != null) {
      return response(200,
          message: 'ok',
          data: ListUtil.filter(metaWorkbook.entriesJson, (e, i) {
            return i >= form && i <= to;
          }));
    }
    int page = int.parse(query['page'] ?? '1');
    int? pageSize = int.tryParse(query['pageSize'] ?? '');
    if (pageSize != null) {
      return response(200,
          message: 'ok',
          data: ListUtil.filter(metaWorkbook.entriesJson, (e, i) {
            return i >= page * pageSize && i <= (page + 1) * pageSize;
          }));
    }
    return response(200, message: 'ok', data: metaWorkbook.entriesJson);
  }

  @override
  Future<Response> get() async {
    switch (command) {
      case 'columns':
        return getColumns();
      case 'entries':
        return getEntries();
      default:
        return response(200, message: 'ok', data: metaJson);
    }
  }

  Future<Response> patchColumns() async {
    var columnMap = body.json;
    List<MetaColumn> data = [];
    if (columnMap is Map<String, dynamic>) {
      for (var i = 0; i < metaWorkbook.columns.length; i++) {
        String code = metaWorkbook.columns[i].code;
        if (columnMap[code] != null) {
          if (columnMap[code]['title'] != null) {
            metaWorkbook.columns[i].title = columnMap[code]['title'];
          }
          if (columnMap[code]['type'] != null) {
            var type = MetaType.Text.stringToType(columnMap[code]['type']);
            if (type != null) {
              metaWorkbook.columns[i].type = type;
            }
          }
          metaWorkbook.columns[i].meta.updateMeta(columnMap[code]['meta']);
          data.add(metaWorkbook.columns[i]);
        }
      }
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'columns': ListUtil.map(metaWorkbook.columns, (e, i) => e.toJson)
      }
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
        var entry = metaWorkbook.updateEntryValues(key, value);
        if (entry != null) {
          data.add(entry);
        }
      });
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'entries': ListUtil.map(metaWorkbook.entries, (e, i) => e.toJson)
      }
    });
    if (status.isFailure) {
      return response(500, message: 'update $sheetId entries error');
    }
    await updateSheet();
    return response(200,
        message: 'ok', data: ListUtil.map(data, (e, i) => e.toJson));
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

  Future<Response> postColumns() async {
    var columns = body.json;
    if (columns is List) {
      for (var i = 0; i < columns.length; i++) {
        int width = int.parse(columns[i]['width'] ?? '180');
        String code = '${metaWorkbook.code}${metaWorkbook.columns.length + 1}';
        metaWorkbook.columns.add(MetaColumn(code,
            title: columns[i]['title'] ?? "未命名", width: width));
      }
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'columns': ListUtil.map(metaWorkbook.columns, (e, i) => e.toJson)
      }
    });
    if (status.isFailure) {
      return response(500, message: 'create $sheetId meta columns error');
    }
    await updateSheet();
    return response(200,
        message: 'ok',
        data: ListUtil.map(metaWorkbook.columns, (e, i) => e.toJson));
  }

  Future<Response> postEntries() async {
    var entries = body.json;
    if (entries is List) {
      for (var i = 0; i < entries.length; i++) {
        var entry = MetaEntry(Md5EnCode(DateTime.now().toString()).to16Bit);
        entry.values = metaWorkbook.getEntryValues(entries[i]);
        metaWorkbook.entries.add(entry);
      }
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'entries': ListUtil.map(metaWorkbook.entries, (e, i) => e.toJson)
      }
    });
    if (status.isFailure) {
      return response(500, message: 'create $sheetId entries error');
    }
    await updateSheet();
    return response(200,
        message: 'ok',
        data: ListUtil.map(metaWorkbook.entries, (e, i) => e.toJson));
  }

  @override
  Future<Response> post() async {
    switch (command) {
      case 'columns':
        return postColumns();
      case 'entries':
        return postEntries();
      default:
        return response(400, message: 'command [$command] not found');
    }
  }

  Future<Response> deleteColumns() async {
    var codeString = query['code'] ?? '';
    List<String> codes = codeString.split(',');
    for (var i = 0; i < codes.length; i++) {
      metaWorkbook.columns.removeWhere((ele) => ele.code == codes[i]);
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'columns': ListUtil.map(metaWorkbook.columns, (e, i) => e.toJson)
      }
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
      metaWorkbook.entries.removeWhere((ele) => ele.id == ids[i]);
    }
    var status = await metaWorkbookDb.updateOne(where.eq('sheetId', sheetId), {
      '\$set': {
        'entries': ListUtil.map(metaWorkbook.entries, (e, i) => e.toJson)
      }
    });
    if (status.isFailure) {
      return response(500, message: 'delete $sheetId entries error');
    }
    await updateSheet();
    return response(200, message: 'ok');
  }

  @override
  Future<Response> delete() async {
    switch (command) {
      case 'columns':
        return deleteColumns();
      case 'entries':
        return deleteEntries();
      default:
        return response(400, message: 'command [$command] not found');
    }
  }
}

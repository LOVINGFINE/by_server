import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/db_helper.dart';
import 'package:by_server/helper/router_helper.dart';
import 'package:by_server/utils/md5.dart';
import '../model.dart';

class MetaSheetRouter extends RouterHelper {
  String? sheetId;
  DbCollection metaSheetDb = mongodb.collection('meta_sheets');
  MetaSheetRouter(Request request, {this.sheetId})
      : super(
          request,
        );
  getSheet() async {
    if (sheetId != null) {
      var json = await metaSheetDb.findOne(where.eq('id', sheetId));
      if (json != null) {
        MetaSheet sheet = MetaSheet.fromJson(json);
        return sheet;
      }
    }
  }

  @override
  post() async {
    int count = await metaSheetDb.count();
    String code = MetaSheet.numberToCode(count);
    String name = body.json['name'] ?? '未命名';
    MetaSheet sheet = MetaSheet(
        Md5EnCode('sheet-$code${DateTime.now()}').to16Bit,
        code: code,
        name: name);
    Map<String, dynamic> data = sheet.toJson;
    var status = await metaSheetDb.insertOne(data);
    if (status.isFailure) {
      return response(500, message: '创建失败');
    }
    return response(200, message: 'ok', data: data);
  }

  @override
  Future<Response> get() async {
    if (sheetId != null) {
      MetaSheet? sheet = await getSheet();
      if (sheet != null) {
        return response(200, message: 'ok', data: sheet.toJson);
      }
      return response(400,
          message: 'error', data: 'sheet [$sheetId] not found');
    } else {
      DbFind find = DbFind(metaSheetDb);
      String search = query['search'] ?? '';
      if (query['page'] == null || query['pageSize'] == null) {
        // 不分页
        var data = await find.search(value: search);
        return response(200, message: 'ok', data: data);
      } else {
        // 分页
        int page = int.parse(query['page'] ?? '');
        int pageSize = int.parse(query['pageSize'] ?? '');
        Pagination pagination = await find.searchPagination(
            page: page, pageSize: pageSize, value: search);
        return response(200, message: 'ok', data: pagination.toJson);
      }
    }
  }

  @override
  patch() async {
    MetaSheet? sheet = await getSheet();
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
    MetaSheet? sheet = await getSheet();
    if (sheet == null) {
      return response(400, message: 'sheet [$sheetId] not found');
    }
    var status = await metaSheetDb.deleteOne(where.eq('id', sheetId));
    if (status.isFailure) {
      return response(500, message: '删除失败');
    }
    return response(200, message: 'ok');
  }

  // Future<Response> insertColumn(String sheetId) async {
  //   var body = await getBody;
  //   MetaSheet? sheet = await getSheetById(sheetId);
  //   if (sheet == null) {
  //     return response(400, message: 'sheet [$sheetId] not found');
  //   }
  //   String code = '${sheet.code}${sheet.columns.length + 1}';

  //   String id = Md5EnCode('sheet-col-$code').to16Bit;
  //   MetaColumn column = MetaColumn(id, code: code);
  //   if (column.type.isTypeString(body['type'])) {
  //     column.type == body['type'];
  //   }
  //   if (body['meta'] != null) {
  //     column.meta.fromJson(body['meta']);
  //   }
  //   column.title = body['title'] ?? '未命名$code';
  //   column.formula = body['formula'] ?? "";
  //   sheet.columns.add(column);
  //   for (var item in sheet.entries) {
  //     item.initValues(sheet.columns);
  //   }
  //   var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //     '\$set': {
  //       'columns': sheet.columns.map((e) => e.toJson).toList(),
  //       'entries': sheet.entries.map((e) => e.toJson).toList()
  //     }
  //   });
  //   if (status.isFailure) {
  //     return response(500, message: '新增失败');
  //   }
  //   return response(200, message: 'ok', data: column.toJson);
  // }

  // Future<Response> updateColumn(String sheetId, String id) async {
  //   try {
  //     MetaSheet? sheet = await getSheetById(sheetId);
  //     if (sheet == null) {
  //       return response(400, message: 'sheet [$sheetId] not found');
  //     }
  //     var body = await getBody;
  //     var target = {};
  //     for (var column in sheet.columns) {
  //       if (column.id == id) {
  //         if (column.type.isTypeString(body['type'])) {
  //           column.type == body['type'];
  //         }
  //         if (body['meta'] != null) {
  //           column.meta.fromJson(body['meta']);
  //         }
  //         column.title = body['title'] ?? column.title;
  //         column.formula = body['formula'] ?? column.formula;
  //         target = column.toJson;
  //       }
  //     }
  //     var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //       '\$set': {'columns': sheet.columns.map((e) => e.toJson).toList()}
  //     });
  //     if (status.isFailure) {
  //       return response(500, message: '修改失败');
  //     }
  //     return response(200, message: 'ok', data: target);
  //   } catch (e) {
  //     print(e);
  //     return response(500, message: '修改失败');
  //   }
  // }

  // Future<Response> removeColumn(String sheetId, String idsString) async {
  //   MetaSheet? sheet = await getSheetById(sheetId);
  //   if (sheet == null) {
  //     return response(400, message: 'sheet [$sheetId] not found');
  //   }
  //   var ids = idsString.split(',');
  //   if ((ids is! List)) {
  //     return response(404, message: '参数错误');
  //   }

  //   for (var column in sheet.columns) {
  //     if (ids.contains(column.id)) {
  //       sheet.columns.remove(column);
  //     }
  //   }

  //   for (var item in sheet.entries) {
  //     item.initValues(sheet.columns);
  //   }
  //   var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //     '\$set': {
  //       'columns': sheet.columns.map((e) => e.toJson).toList(),
  //       'entries': sheet.entries.map((e) => e.toJson).toList()
  //     }
  //   });
  //   if (status.isFailure) {
  //     return response(500, message: '删除失败');
  //   }
  //   return response(200, message: 'ok');
  // }

  // Future<Response> insertEntry(sheetId) async {
  //   MetaSheet? sheet = await getSheetById(sheetId);
  //   if (sheet == null) {
  //     return response(400, message: 'sheet [$sheetId] not found');
  //   }
  //   String id = Md5EnCode('sheet-row-${sheet.entries.length}').to16Bit;
  //   MetaSheetEntry entry = MetaSheetEntry(id, {});
  //   entry.initValues(sheet.columns);
  //   sheet.entries.add(entry);
  //   var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //     '\$set': {'entries': sheet.entries.map((e) => e.toJson).toList()}
  //   });
  //   if (status.isFailure) {
  //     return response(500, message: '新增失败');
  //   }
  //   return response(200, message: 'ok', data: entry.toJson);
  // }

  // Future<Response> updateEntry(String sheetId) async {
  //   MetaSheet? sheet = await getSheetById(sheetId);
  //   if (sheet == null) {
  //     return response(400, message: 'sheet [$sheetId] not found');
  //   }
  //   var body = await getBody;
  //   var target = [];
  //   for (var entry in sheet.entries) {
  //     if (body[entry.id] != null) {
  //       entry.updateValues(body[entry.id]);
  //       target.add(entry.toJson);
  //     }
  //   }
  //   var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //     '\$set': {'entries': sheet.entries.map((e) => e.toJson).toList()}
  //   });
  //   if (status.isFailure) {
  //     return response(500, message: '修改失败');
  //   }
  //   return response(200, message: 'ok', data: target);
  // }

  // Future<Response> removeEntry(String sheetId, String idsString) async {
  //   MetaSheet? sheet = await getSheetById(sheetId);
  //   if (sheet == null) {
  //     return response(400, message: 'sheet [$sheetId] not found');
  //   }
  //   var ids = idsString.split(',');
  //   if (ids is List) {
  //     for (var entry in sheet.entries) {
  //       if (ids.contains(entry.id)) {
  //         sheet.entries.remove(entry);
  //       }
  //     }
  //     var status = await dbHelper.updateOne(where.eq('id', sheetId), {
  //       '\$set': {'entries': sheet.columns.map((e) => e.toJson).toList()}
  //     });
  //     if (status.isFailure) {
  //       return response(500, message: '删除失败');
  //     }
  //     return response(200, message: 'ok');
  //   }
  //   return response(400, message: '参数错误');
  // }
}

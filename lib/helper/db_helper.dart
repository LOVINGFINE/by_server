import 'package:mongo_dart/mongo_dart.dart' hide State;

class Pagination<T> {
  List<T> records;
  int total;
  int page;
  int pageSize;
  Pagination(this.records, {this.total = 0, this.page = 1, this.pageSize = 0});

  get toJson {
    return {
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'records': records
    };
  }
}

class DbFind {
  DbCollection collection;
  DbFind(this.collection);

  Future<List<T>> search<T>({String value = ''}) async {
    return await collection
        .find(where
            .match('name', value)
            .fields(['name', 'id', 'updatedTime', 'createdTime']))
        .toList() as List<T>;
  }

  Future<Pagination<T>> searchPagination<T>(
      {String value = '', int page = 1, int pageSize = 0}) async {
    SelectorBuilder selector = where.match('name', value);
    List<T> list = await collection
        .find(selector.skip((page - 1) * pageSize).limit(pageSize))
        .toList() as List<T>;
    int total = await collection.count(selector);
    return Pagination<T>(list, page: page, pageSize: pageSize, total: total);
  }
}

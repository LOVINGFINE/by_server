import 'package:by_server/utils/lodash.dart';

enum ListMode {
  list,
  grid,
}

extension ParseListMode on ListMode {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  ListMode? toType(String type) {
    return ListUtil.find<ListMode>(
        ListMode.values, (v, i) => v.toTypeString() == type);
  }
}

enum ListSort {
  // 最近编辑时间
  editDate,
  // 标题
  title,
  openDate,
}

extension ParseListSort on ListSort {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  ListSort? toType(String type) {
    return ListUtil.find<ListSort>(
        ListSort.values, (v, i) => v.toTypeString() == type);
  }
}

enum ListFilter {
  none,
  createByMe,
  shareToMe,
}

extension ParseListFilter on ListFilter {
  bool isType(type) {
    if (type == null) {
      return false;
    }
    return toString().split('.').last == type;
  }

  String toTypeString() {
    return toString().split('.').last;
  }

  ListFilter? toType(String type) {
    return ListUtil.find<ListFilter>(
        ListFilter.values, (v, i) => v.toTypeString() == type);
  }
}

class UserSheetSettings {
  String userId;
  bool hideTemplate = false;
  ListMode mode = ListMode.list;
  ListSort sort = ListSort.openDate;
  ListFilter filter = ListFilter.none;

  UserSheetSettings(this.userId);

  UserSheetSettings.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        hideTemplate = json['hideTemplate'],
        mode = ListMode.values[0].toType(json['mode']) ?? ListMode.values[0],
        filter =
            ListFilter.values[0].toType(json['filter']) ?? ListFilter.values[0],
        sort = ListSort.values[0].toType(json['sort']) ?? ListSort.values[0];

  Map<String, dynamic> get toJson {
    return {'userId': userId, ...toJsonHideUser};
  }

  Map<String, dynamic> get toJsonHideUser {
    return {
      'hideTemplate': hideTemplate,
      'mode': mode.toTypeString(),
      'sort': sort.toTypeString(),
      'filter': filter.toTypeString()
    };
  }
}

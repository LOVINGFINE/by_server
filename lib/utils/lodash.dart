class MapUtil {
  static Map<K, V> map<K, V>(
      Map<K, dynamic> obj,
      V Function(
    dynamic e,
    K i,
  )
          fn) {
    return Map<K, V>.from(obj.map((k, v) => MapEntry(k, fn(v, k))));
  }
}

class ListUtil {
  static List<T> map<T>(
      List<dynamic> list,
      T Function(
    dynamic e,
    int i,
  )
          fn) {
    List<T> targets = [];
    for (var i = 0; i < list.length; i++) {
      targets.add(fn(list[i], i));
    }
    return targets;
  }

  static List<T> filter<T>(
      List<T> list,
      bool Function(
    dynamic e,
    int i,
  )
          fn) {
    List<T> targets = [];
    for (var i = 0; i < list.length; i++) {
      if (fn(list[i], i)) {
        targets.add(list[i]);
      }
    }
    return targets;
  }

  static forEach<T>(
      List<T> list,
      Function(
    dynamic e,
    int i,
  )
          fn) {
    for (var i = 0; i < list.length; i++) {
      fn(list[i], i);
    }
  }

  static T? find<T>(
      List<T> list,
      bool Function(
    T e,
    int i,
  )
          fn) {
    T? e;
    for (var i = 0; i < list.length; i++) {
      if (fn(list[i], i)) {
        e = list[i];
      }
    }
    return e;
  }

  static findIndex<T>(List<T> list, bool Function(T v, int i) fn) {
    int index = -1;
    for (var i = 0; i < list.length; i++) {
      if (fn(list[i], i)) {
        index = i;
        break;
      }
    }
    return index;
  }
}

class EasyDate {
  static String full = 'YYYY-MM-dd HH:mm:ss';
  static String day = 'YYYY-MM-dd';
  static String time = 'HH:mm:ss';

  DateTime dateTime = DateTime.now();
  // 构造函数
  EasyDate({date}) {
    if (date is String) {
      dateTime = DateTime.parse(date);
    }
    if (date is DateTime) {
      dateTime = date;
    }
  }

  String format(String format) {
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    int second = dateTime.second;

    return format
        .replaceAll('YYYY', year.toString())
        .replaceAll('MM', month > 9 ? month.toString() : '0${month.toString()}')
        .replaceAll('DD', day > 9 ? day.toString() : '0${day.toString()}')
        .replaceAll('dd', day.toString())
        .replaceAll('HH', hour > 9 ? hour.toString() : '0${hour.toString()}')
        .replaceAll('hh', hour.toString())
        .replaceAll(
            'mm', minute > 9 ? minute.toString() : '0${minute.toString()}')
        .replaceAll(
            'ss', second > 9 ? second.toString() : '0${second.toString()}');
  }
}

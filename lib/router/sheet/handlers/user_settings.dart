import 'package:by_server/main.dart';
import 'package:mongo_dart/mongo_dart.dart' hide State;
import 'package:shelf/shelf.dart';
import 'package:by_server/helper/router_helper.dart';
import '../models/main.dart';

class SheetUserSettingsRouter extends RouterUserHelper {
  DbCollection settingsDb = mongodb.collection('user_sheet_settings');
  SheetUserSettingsRouter(Request request) : super(request);

  Future<UserSheetSettings> findUserSettings() async {
    var data = await settingsDb
        .findOne(where.eq('userId', user.id).excludeFields(['_id']));
    if (data == null) {
      UserSheetSettings settings = UserSheetSettings(user.id);
      await settingsDb.insertOne(settings.toJson);
      return settings;
    }
    return UserSheetSettings.fromJson(data);
  }

  @override
  Future<Response> get() async {
    var settings = await findUserSettings();
    return response(200, message: 'ok', data: settings.toJsonHideUser);
  }

  @override
  Future<Response> patch() async {
    var settings = await findUserSettings();
    var hideTemplate = body.json['hideTemplate'];
    var sort = body.json['sort'];
    var filter = body.json['filter'];
    var mode = body.json['mode'];

    if (hideTemplate != null && hideTemplate is bool) {
      settings.hideTemplate = hideTemplate;
    }
    if (sort != null) {
      settings.sort = settings.sort.toType(sort) ?? settings.sort;
    }
    if (filter != null) {
      settings.filter = settings.filter.toType(filter) ?? settings.filter;
    }
    if (mode != null) {
      settings.mode = settings.mode.toType(mode) ?? settings.mode;
    }

    await settingsDb.updateOne(
        where.eq('userId', user.id), {'\$set': settings.toJsonHideUser});
    return response(200, message: 'ok', data: settings.toJsonHideUser);
  }
}

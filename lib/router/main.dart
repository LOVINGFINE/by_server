import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'sheet/main.dart';

class HttpRouter {
  static Handler get router {
    Router appRouter = Router();

    /// 模版分类
    appRouter.all('/sheet/template-categories', (Request request) {
      return SheetTemplateCategoryRouter(request).handler();
    });

    appRouter.all('/sheet/template-categories/<categoryId>',
        (Request request, String categoryId) {
      return SheetTemplateCategoryRouter(request, categoryId: categoryId)
          .handler();
    });

    /// 表格模版
    appRouter.all('/sheet/templates', (
      Request request,
    ) {
      return SheetTemplateRouter(request).handler();
    });

    appRouter.all('/sheet/templates/<templateId>',
        (Request request, String templateId) {
      return SheetTemplateRouter(request, templateId: templateId).handler();
    });

    /// sheet 用户设置
    appRouter.all('/sheet/user/settings', (
      Request request,
    ) {
      return SheetUserSettingsRouter(request).handler();
    });

    /// 表格
    appRouter.all('/sheets', (Request request) {
      return SheetRouter(request).handler();
    });

    appRouter.all('/sheets/<sheetId>', (Request request, String? sheetId) {
      return SheetRouter(request, sheetId: sheetId).handler();
    });

    appRouter.all('/sheets/<sheetId>/meta', (Request request, String sheetId) {
      return SheetMetaWorkbookRouter(request, sheetId).handler();
    });

    appRouter.all('/sheets/<sheetId>/meta/<command>',
        (Request request, String sheetId, String command) {
      return SheetMetaWorkbookRouter(request, sheetId, command: command)
          .handler();
    });

    appRouter.all('/sheets/<sheetId>/common',
        (Request request, String sheetId) {
      return SheetCommonWorkbookRouter(
        request,
        sheetId,
      ).handler();
    });

    appRouter.all('/sheets/<sheetId>/common/<workbookId>',
        (Request request, String sheetId, String workbookId) {
      return SheetCommonWorkbookRouter(request, sheetId, workbookId: workbookId)
          .handler();
    });

    appRouter.all('/sheets/<sheetId>/common/<workbookId>/<command>',
        (Request request, String sheetId, String workbookId, String command) {
      return SheetCommonWorkbookRouter(request, sheetId,
              workbookId: workbookId, command: command)
          .handler();
    });

    return appRouter;
  }
}

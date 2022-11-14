import 'package:by_dart_server/router/user/main.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'sheet/main.dart';

class HttpRouter {
  static Handler get router {
    Router appRouter = Router();
    appRouter.all('/register', (Request request) {
      return UserRegisterRouter(request).handler();
    });

    appRouter.all('/login', (Request request) {
      return UserRouter(request).handler();
    });

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

    /// 表格
    appRouter.all('/sheets', (
      Request request,
    ) {
      return SheetRouter(request).handler();
    });

    appRouter.all('/sheets/<sheetId>', (Request request, String sheetId) {
      return SheetRouter(request, sheetId: sheetId).handler();
    });

    appRouter.all('/sheets/<sheetId>/workbooks',
        (Request request, String sheetId) {
      return SheetWorkbookRouter(request, sheetId).handler();
    });

    appRouter.all('/sheets/<sheetId>/workbooks/<workbookId>',
        (Request request, String sheetId, String workbookId) {
      return SheetWorkbookRouter(request, sheetId, workbookId: workbookId)
          .handler();
    });

    appRouter.all('/sheets/<sheetId>/workbooks/<workbookId>/command/<command>',
        (Request request, String sheetId, String workbookId, String command) {
      return SheetWorkbookCommandRouter(request, sheetId, workbookId, command)
          .handler();
    });

    return appRouter;
  }
}

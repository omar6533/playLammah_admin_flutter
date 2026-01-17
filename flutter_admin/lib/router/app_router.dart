import 'package:auto_route/auto_route.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/categories_page.dart';
import '../pages/questions_page.dart';
import '../pages/users_page.dart';
import '../pages/games_page.dart';
import '../pages/payments_page.dart';
import '../pages/settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LoginRoute.page, initial: true),
        AutoRoute(
          page: HomeRoute.page,
          children: [
            AutoRoute(page: DashboardRoute.page, initial: true),
            AutoRoute(page: CategoriesRoute.page),
            AutoRoute(page: QuestionsRoute.page),
            AutoRoute(page: UsersRoute.page),
            AutoRoute(page: GamesRoute.page),
            AutoRoute(page: PaymentsRoute.page),
            AutoRoute(page: SettingsRoute.page),
          ],
        ),
      ];
}

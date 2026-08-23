import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar.dart';
import '../router/app_router.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DashboardRoute(),
        CategoriesRoute(),
        QuestionsRoute(),
        UsersRoute(),
        GamesRoute(),
        PaymentsRoute(),
        SettingsRoute(),
      ],
      transitionBuilder: (context, child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: Row(
            children: [
              Sidebar(
                currentPage: _getCurrentPageName(tabsRouter.activeIndex),
                onPageChange: (page) {
                  final index = _getIndexForPage(page);
                  tabsRouter.setActiveIndex(index);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Spacer(),
          Image.asset(
            'assets/images/logo_full.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Sign out',
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
              context.router.replace(const LoginRoute());
            },
          ),
        ],
      ),
    );
  }

  String _getCurrentPageName(int index) {
    switch (index) {
      case 0:
        return 'dashboard';
      case 1:
        return 'categories';
      case 2:
        return 'questions';
      case 3:
        return 'users';
      case 4:
        return 'games';
      case 5:
        return 'payments';
      case 6:
        return 'settings';
      default:
        return 'dashboard';
    }
  }

  int _getIndexForPage(String page) {
    switch (page) {
      case 'dashboard':
        return 0;
      case 'categories':
        return 1;
      case 'questions':
        return 2;
      case 'users':
        return 3;
      case 'games':
        return 4;
      case 'payments':
        return 5;
      case 'settings':
        return 6;
      default:
        return 0;
    }
  }
}

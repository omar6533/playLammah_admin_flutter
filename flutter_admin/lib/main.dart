import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/categories/categories_bloc.dart';
import 'blocs/categories/categories_event.dart';
import 'blocs/questions/questions_bloc.dart';
import 'blocs/users/users_bloc.dart';
import 'blocs/games/games_bloc.dart';
import 'blocs/payments/payments_bloc.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/dashboard/dashboard_event.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDCxMT_ouWkmcSNw015ANi-MwvsDryHqlE",
          authDomain: "allmahgame.firebaseapp.com",
          projectId: "allmahgame",
          storageBucket: "allmahgame.firebasestorage.app",
          messagingSenderId: "564436165702",
          appId: "1:564436165702:web:e5835d1939d8122cab9647",
          measurementId: "G-STJQ93CRJL"),
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) =>
              CategoriesBloc(FirestoreService())..add(const LoadCategories()),
        ),
        BlocProvider(
          create: (context) => QuestionsBloc(FirestoreService()),
        ),
        BlocProvider(
          create: (context) => UsersBloc(FirestoreService()),
        ),
        BlocProvider(
          create: (context) => GamesBloc(FirestoreService()),
        ),
        BlocProvider(
          create: (context) => PaymentsBloc(FirestoreService()),
        ),
        BlocProvider(
          create: (context) => DashboardBloc()..add(LoadDashboardStats()),
        ),
      ],
      child: MaterialApp.router(
        title: 'SeenJeem Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.config(),
      ),
    );
  }
}

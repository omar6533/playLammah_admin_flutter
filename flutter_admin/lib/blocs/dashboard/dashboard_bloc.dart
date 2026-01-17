import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final FirestoreService _firestoreService = FirestoreService();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
  }

  Future<void> _onLoadDashboardStats(
      LoadDashboardStats event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      // Add timeout to prevent infinite loading, similar to original implementation
      final stats = await _firestoreService.getDashboardStats().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return {
            'totalUsers': 0,
            'totalGames': 0,
            'totalQuestions': 0,
            'totalRevenue': 0.0,
            'activeQuestions': 0,
            'totalMainCategories': 0,
            'totalSubCategories': 0,
          };
        },
      );
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}

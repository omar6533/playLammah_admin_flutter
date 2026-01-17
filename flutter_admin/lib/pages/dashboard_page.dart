import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/dashboard/dashboard_state.dart';
import '../blocs/dashboard/dashboard_event.dart';
import '../widgets/stat_card.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading dashboard data...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                } else if (state is DashboardError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Showing default values. Check Firebase configuration.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<DashboardBloc>()
                              .add(LoadDashboardStats()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is DashboardLoaded) {
                  final stats = state.stats;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive cross axis count based on screen width
                      int crossAxisCount = 4;
                      if (constraints.maxWidth < 1200) {
                        crossAxisCount = 3;
                      }
                      if (constraints.maxWidth < 900) {
                        crossAxisCount = 2;
                      }
                      if (constraints.maxWidth < 600) {
                        crossAxisCount = 1;
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossAxisCount == 1
                            ? 3.5
                            : crossAxisCount == 2
                                ? 2.0
                                : 2.5,
                        children: [
                          StatCard(
                            title: 'Total Users',
                            value: (stats['totalUsers'] ?? 0).toString(),
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          StatCard(
                            title: 'Total Games',
                            value: (stats['totalGames'] ?? 0).toString(),
                            icon: Icons.gamepad,
                            color: Colors.green,
                          ),
                          StatCard(
                            title: 'Total Questions',
                            value: (stats['totalQuestions'] ?? 0).toString(),
                            icon: Icons.question_answer,
                            color: Colors.orange,
                          ),
                          StatCard(
                            title: 'Total Revenue',
                            value:
                                '\$${((stats['totalRevenue'] ?? 0.0) as num).toStringAsFixed(2)}',
                            icon: Icons.attach_money,
                            color: Colors.red,
                          ),
                        ],
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

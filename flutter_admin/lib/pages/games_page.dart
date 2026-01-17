import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/game_model.dart';
import '../widgets/custom_data_table.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../blocs/games/games_bloc.dart';
import '../blocs/games/games_event.dart';
import '../blocs/games/games_state.dart';
import 'package:intl/intl.dart';

@RoutePage()
class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  @override
  void initState() {
    super.initState();
    context.read<GamesBloc>().add(LoadGames());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GamesBloc, GamesState>(
      listener: (context, state) {
        if (state is GamesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        List<GameModel> games = [];
        bool isLoading = state is GamesLoading;

        if (state is GamesLoaded) {
          games = state.games;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: LoadingOverlay(
            isLoading: isLoading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildContent(context, state, games),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, GamesState state, List<GameModel> games) {
    if (state is GamesLoading && games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is GamesError && games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (games.isEmpty) {
      return const EmptyState(
        icon: Icons.gamepad_outlined,
        title: 'No Games',
        message: 'No games have been played yet.',
      );
    }

    final rows = games.map((game) {
      return [
        game.userId,
        game.categoryId,
        '${game.score}/${game.totalQuestions}',
        game.status,
        DateFormat('MMM dd, yyyy HH:mm').format(game.createdAt),
      ];
    }).toList();

    return CustomDataTable(
      columns: const ['User ID', 'Category', 'Score', 'Status', 'Created At'],
      rows: rows,
      onDelete: (index) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Game'),
            content: const Text('Are you sure you want to delete this game?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          if (context.mounted) {
            context.read<GamesBloc>().add(DeleteGame(games[index].id));
          }
        }
      },
    );
  }
}

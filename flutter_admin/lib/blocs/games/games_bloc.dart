import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import '../../models/game_model.dart';
import 'games_event.dart';
import 'games_state.dart';

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final FirestoreService _firestoreService;

  GamesBloc(this._firestoreService) : super(GamesInitial()) {
    on<LoadGames>(_onLoadGames);
    on<CreateGame>(_onCreateGame);
    on<UpdateGame>(_onUpdateGame);
    on<DeleteGame>(_onDeleteGame);
  }

  Future<void> _onLoadGames(LoadGames event, Emitter<GamesState> emit) async {
    emit(GamesLoading());
    try {
      await emit.forEach(
        _firestoreService.getGames(),
        onData: (List<GameModel> games) => GamesLoaded(games),
        onError: (error, stackTrace) => GamesError(error.toString()),
      );
    } catch (e) {
      emit(GamesError(e.toString()));
    }
  }

  Future<void> _onCreateGame(CreateGame event, Emitter<GamesState> emit) async {
    try {
      final game = GameModel.fromFirestore(event.data, '');
      await _firestoreService.addGame(game);
    } catch (e) {
      emit(GamesError(e.toString()));
    }
  }

  Future<void> _onUpdateGame(UpdateGame event, Emitter<GamesState> emit) async {
    try {
      final game = GameModel.fromFirestore(event.data, event.id);
      await _firestoreService.updateGame(event.id, game);
    } catch (e) {
      emit(GamesError(e.toString()));
    }
  }

  Future<void> _onDeleteGame(DeleteGame event, Emitter<GamesState> emit) async {
    try {
      await _firestoreService.deleteGame(event.id);
    } catch (e) {
      emit(GamesError(e.toString()));
    }
  }
}

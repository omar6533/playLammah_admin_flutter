import 'package:equatable/equatable.dart';
import '../../models/game_model.dart';

abstract class GamesState extends Equatable {
  const GamesState();
  @override
  List<Object?> get props => [];
}

class GamesInitial extends GamesState {}

class GamesLoading extends GamesState {}

class GamesLoaded extends GamesState {
  final List<GameModel> games;
  const GamesLoaded(this.games);
  @override
  List<Object?> get props => [games];
}

class GamesError extends GamesState {
  final String message;
  const GamesError(this.message);
  @override
  List<Object?> get props => [message];
}

class GameOperationSuccess extends GamesState {
  final String message;
  const GameOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

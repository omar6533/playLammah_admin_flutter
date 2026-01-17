import 'package:equatable/equatable.dart';

abstract class GamesEvent extends Equatable {
  const GamesEvent();
  @override
  List<Object?> get props => [];
}

class LoadGames extends GamesEvent {}

class CreateGame extends GamesEvent {
  final Map<String, dynamic> data;
  const CreateGame(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateGame extends GamesEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateGame(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class DeleteGame extends GamesEvent {
  final String id;
  const DeleteGame(this.id);
  @override
  List<Object?> get props => [id];
}

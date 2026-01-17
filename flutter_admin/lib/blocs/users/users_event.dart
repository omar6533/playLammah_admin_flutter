import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {}

class CreateUser extends UsersEvent {
  final UserModel user;
  const CreateUser(this.user);
  @override
  List<Object?> get props => [user];
}

class UpdateUser extends UsersEvent {
  final UserModel user;
  const UpdateUser(this.user);
  @override
  List<Object?> get props => [user];
}

class DeleteUser extends UsersEvent {
  final String id;
  const DeleteUser(this.id);
  @override
  List<Object?> get props => [id];
}

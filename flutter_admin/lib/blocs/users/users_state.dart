import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserOperationSuccess extends UsersState {
  final String message;
  const UserOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

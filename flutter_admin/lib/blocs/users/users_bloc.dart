import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final FirestoreService _firestoreService;

  UsersBloc(this._firestoreService) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(UsersLoading());
    try {
      await emit.forEach(
        _firestoreService.getUsers(),
        onData: (List<UserModel> users) => UsersLoaded(users),
        onError: (error, stackTrace) => UsersError(error.toString()),
      );
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onCreateUser(CreateUser event, Emitter<UsersState> emit) async {
    try {
      await _firestoreService.addUser(event.user);
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      await _firestoreService.updateUser(event.user.id, event.user);
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    try {
      await _firestoreService.deleteUser(event.id);
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}

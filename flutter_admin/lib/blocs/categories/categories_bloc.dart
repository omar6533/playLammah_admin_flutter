import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final FirestoreService _firestoreService;

  CategoriesBloc(this._firestoreService) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateMainCategory>(_onCreateMainCategory);
    on<UpdateMainCategory>(_onUpdateMainCategory);
    on<ToggleMainCategoryStatus>(_onToggleMainCategoryStatus);
    on<CreateSubCategory>(_onCreateSubCategory);
    on<UpdateSubCategory>(_onUpdateSubCategory);
    on<ToggleSubCategoryStatus>(_onToggleSubCategoryStatus);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final mainCategories = await _firestoreService.getMainCategories();
      final subCategories = await _firestoreService
          .getSubCategories(event.selectedMainCategoryId);
      emit(CategoriesLoaded(
        mainCategories: mainCategories,
        subCategories: subCategories,
        selectedMainCategoryId: event.selectedMainCategoryId,
      ));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onCreateMainCategory(
    CreateMainCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _firestoreService.createMainCategory(event.data);
      add(const LoadCategories()); // Reload data
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdateMainCategory(
    UpdateMainCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _firestoreService.updateMainCategory(event.id, event.data);
      add(const LoadCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onToggleMainCategoryStatus(
    ToggleMainCategoryStatus event,
    Emitter<CategoriesState> emit,
  ) async {
    // No full loading state to avoid UI flicker, or maybe just reload quietly?
    // For now, let's just trigger load, maybe improved later.
    // But user asked for loading.
    emit(CategoriesLoading());
    try {
      await _firestoreService.updateMainCategory(event.id, {
        'is_active': event.isActive,
        'status': event.isActive ? 'active' : 'disabled',
      });
      add(const LoadCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onCreateSubCategory(
    CreateSubCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _firestoreService.createSubCategory(event.data);
      // We need to know previous selected Main Category to remain consistent,
      // but state is lost during loading.
      // ideally we should preserve it.
      // For now, reload fresh.
      add(const LoadCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdateSubCategory(
    UpdateSubCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _firestoreService.updateSubCategory(event.id, event.data);
      add(const LoadCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onToggleSubCategoryStatus(
    ToggleSubCategoryStatus event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      await _firestoreService.updateSubCategory(event.id, {
        'is_active': event.isActive,
      });
      add(const LoadCategories());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}

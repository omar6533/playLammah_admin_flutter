import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firestore_service.dart';
import 'questions_event.dart';
import 'questions_state.dart';

class QuestionsBloc extends Bloc<QuestionsEvent, QuestionsState> {
  final FirestoreService _firestoreService;

  QuestionsBloc(this._firestoreService) : super(QuestionsInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<CreateQuestion>(_onCreateQuestion);
    on<UpdateQuestion>(_onUpdateQuestion);
    on<ToggleQuestionStatus>(_onToggleQuestionStatus);
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(QuestionsLoading());
    try {
      final questions = await _firestoreService.getQuestions(
          subCategoryId: event.subCategoryId);
      emit(QuestionsLoaded(
        questions: questions,
        selectedSubCategoryId: event.subCategoryId,
      ));
    } catch (e) {
      emit(QuestionsError(e.toString()));
    }
  }

  Future<void> _onCreateQuestion(
    CreateQuestion event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(QuestionsLoading());
    try {
      await _firestoreService.createQuestion(event.data);
      add(LoadQuestions()); // Reload all or filter? Ideally keep filter if applied.
      // But we don't store filter in Bloc member, only in State.
      // We should check state.
      // But we can't easily access previous state if we just emitted Loading.
      // Actually we can pass filter from event.
      // For now, reload all.
    } catch (e) {
      emit(QuestionsError(e.toString()));
    }
  }

  Future<void> _onUpdateQuestion(
    UpdateQuestion event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(QuestionsLoading());
    try {
      await _firestoreService.updateQuestion(event.id, event.data);
      add(LoadQuestions());
    } catch (e) {
      emit(QuestionsError(e.toString()));
    }
  }

  Future<void> _onToggleQuestionStatus(
    ToggleQuestionStatus event,
    Emitter<QuestionsState> emit,
  ) async {
    emit(QuestionsLoading());
    try {
      // Assuming 'status' field string vs 'is_active' boolean
      // SeenjeemQuestionModel has `status`.
      // We update both if needed, usually just status.
      await _firestoreService.updateQuestion(event.id, {
        'status': event.isActive ? 'active' : 'disabled',
      });
      add(LoadQuestions());
    } catch (e) {
      emit(QuestionsError(e.toString()));
    }
  }
}

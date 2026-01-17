import 'package:equatable/equatable.dart';
import '../../models/seenjeem_question_model.dart';

abstract class QuestionsState extends Equatable {
  const QuestionsState();

  @override
  List<Object?> get props => [];
}

class QuestionsInitial extends QuestionsState {}

class QuestionsLoading extends QuestionsState {}

class QuestionsLoaded extends QuestionsState {
  final List<SeenjeemQuestionModel> questions;
  final String? selectedSubCategoryId;

  const QuestionsLoaded({
    required this.questions,
    this.selectedSubCategoryId,
  });

  @override
  List<Object?> get props => [questions, selectedSubCategoryId];
}

class QuestionsError extends QuestionsState {
  final String message;

  const QuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class QuestionOperationSuccess extends QuestionsState {
  final String message;

  const QuestionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

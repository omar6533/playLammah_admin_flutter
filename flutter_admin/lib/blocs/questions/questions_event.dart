import 'package:equatable/equatable.dart';

abstract class QuestionsEvent extends Equatable {
  const QuestionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuestions extends QuestionsEvent {
  final String? subCategoryId;

  const LoadQuestions({this.subCategoryId});

  @override
  List<Object?> get props => [subCategoryId];
}

class CreateQuestion extends QuestionsEvent {
  final Map<String, dynamic> data;

  const CreateQuestion(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateQuestion extends QuestionsEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateQuestion(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class ToggleQuestionStatus extends QuestionsEvent {
  final String id;
  final bool isActive;

  const ToggleQuestionStatus(this.id, this.isActive);

  @override
  List<Object?> get props => [id, isActive];
}

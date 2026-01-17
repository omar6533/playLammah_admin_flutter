class QuestionModel {
  final String id;
  final String categoryId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String difficulty;
  final bool isActive;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.isActive,
    required this.createdAt,
  });

  factory QuestionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      categoryId: data['categoryId'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? 0,
      difficulty: data['difficulty'] ?? 'medium',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

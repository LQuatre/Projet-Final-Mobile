class QuizQuestion {
  final String category;
  final String type;
  final String difficulty;
  final String question;
  final String originalQuestion;
  final String correctAnswer;
  final List<String> allAnswers;
  final List<String> originalAllAnswers;
  final String? selectedAnswer;

  const QuizQuestion({
    required this.category,
    required this.type,
    required this.difficulty,
    required this.question,
    required this.originalQuestion,
    required this.correctAnswer,
    required this.allAnswers,
    required this.originalAllAnswers,
    this.selectedAnswer,
  });

  QuizQuestion copyWith({
    String? selectedAnswer,
  }) {
    return QuizQuestion(
      category: category,
      type: type,
      difficulty: difficulty,
      question: question,
      originalQuestion: originalQuestion,
      correctAnswer: correctAnswer,
      allAnswers: allAnswers,
      originalAllAnswers: originalAllAnswers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    );
  }

  bool get isCorrect => selectedAnswer == correctAnswer;
  bool get isAnswered => selectedAnswer != null;
}

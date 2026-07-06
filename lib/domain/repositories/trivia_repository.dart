import '../models/quiz_question.dart';
import '../models/trivia_category.dart';

abstract class TriviaRepository {
  Future<List<TriviaCategory>> fetchCategories();
  Future<List<QuizQuestion>> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
    String? type,
  });
}

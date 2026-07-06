import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/domain/models/quiz_question.dart';
import 'package:quiz_app/domain/models/trivia_category.dart';
import 'package:quiz_app/domain/repositories/trivia_repository.dart';
import 'package:quiz_app/presentation/controllers/quiz_controller.dart';

class MockTriviaRepository implements TriviaRepository {
  bool shouldFail = false;

  @override
  Future<List<TriviaCategory>> fetchCategories() async {
    if (shouldFail) throw Exception('API Error');
    return [
      const TriviaCategory(id: 9, name: 'General Knowledge'),
    ];
  }

  @override
  Future<List<QuizQuestion>> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
    String? type,
  }) async {
    if (shouldFail) throw Exception('API Error');
    return [
      const QuizQuestion(
        category: 'General Knowledge',
        type: 'multiple',
        difficulty: 'easy',
        question: 'Question 1',
        originalQuestion: 'Question 1',
        correctAnswer: 'A',
        allAnswers: ['A', 'B', 'C', 'D'],
        originalAllAnswers: ['A', 'B', 'C', 'D'],
      ),
      const QuizQuestion(
        category: 'General Knowledge',
        type: 'multiple',
        difficulty: 'easy',
        question: 'Question 2',
        originalQuestion: 'Question 2',
        correctAnswer: 'X',
        allAnswers: ['W', 'X', 'Y', 'Z'],
        originalAllAnswers: ['W', 'X', 'Y', 'Z'],
      ),
    ];
  }
}

void main() {
  group('QuizController', () {
    late MockTriviaRepository mockRepository;
    late QuizController controller;

    setUp(() {
      mockRepository = MockTriviaRepository();
      controller = QuizController(repository: mockRepository);
    });

    test('initial state', () {
      expect(controller.state, equals(QuizState.initial));
      expect(controller.categories.isEmpty, isTrue);
      expect(controller.questions.isEmpty, isTrue);
    });

    test('loadCategories success', () async {
      await controller.loadCategories();
      expect(controller.state, equals(QuizState.idle));
      expect(controller.categories.length, equals(1));
      expect(controller.categories[0].name, equals('General Knowledge'));
    });

    test('loadCategories failure', () async {
      mockRepository.shouldFail = true;
      await controller.loadCategories();
      expect(controller.state, equals(QuizState.error));
      expect(controller.errorMessage, contains('Impossible de charger les catégories'));
    });

    test('quiz workflow (start, answer, next, finish)', () async {
      await controller.startQuiz();
      expect(controller.state, equals(QuizState.playing));
      expect(controller.questions.length, equals(2));
      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.score, equals(0));

      controller.answerQuestion('A');
      expect(controller.score, equals(1));
      expect(controller.questions[0].isCorrect, isTrue);

      controller.nextQuestion();
      expect(controller.currentQuestionIndex, equals(1));

      controller.answerQuestion('Y');
      expect(controller.score, equals(1));

      controller.nextQuestion();
      expect(controller.state, equals(QuizState.finished));
    });
  });
}

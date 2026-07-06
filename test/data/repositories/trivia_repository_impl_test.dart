import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_app/data/datasources/trivia_remote_datasource.dart';
import 'package:quiz_app/data/models/trivia_response_model.dart';
import 'package:quiz_app/data/repositories/trivia_repository_impl.dart';

class MockTriviaRemoteDatasource implements TriviaRemoteDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  final http.Client client = MockClient((request) async {
    if (request.url.host == 'api.mymemory.translated.net') {
      final q = request.url.queryParameters['q'] ?? '';
      if (q.contains('General Knowledge | Books')) {
        return http.Response(
          '{"responseData": {"translatedText": "Culture Générale | Livres"}}',
          200,
        );
      }
      return http.Response(
        '{"responseData": {"translatedText": "Culture Générale | Quelle est la \\"capitale\\" de la France? | Paris | Londres | Berlin | Rome"}}',
        200,
      );
    }
    return http.Response('', 404);
  });

  @override
  Future<List<TriviaCategoryDto>> fetchCategories() async {
    return [
      const TriviaCategoryDto(id: 9, name: 'General Knowledge'),
      const TriviaCategoryDto(id: 10, name: 'Books'),
    ];
  }

  @override
  Future<List<TriviaQuestionDto>> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
    String? type,
  }) async {
    return [
      const TriviaQuestionDto(
        category: 'General Knowledge',
        type: 'multiple',
        difficulty: 'easy',
        question: 'What is the &quot;capital&quot; of France?',
        correctAnswer: 'Paris',
        incorrectAnswers: ['London', 'Berlin', 'Rome'],
      ),
    ];
  }
}

void main() {
  group('TriviaRepositoryImpl', () {
    late MockTriviaRemoteDatasource mockDatasource;
    late TriviaRepositoryImpl repository;

    setUp(() {
      mockDatasource = MockTriviaRemoteDatasource();
      repository = TriviaRepositoryImpl(remoteDatasource: mockDatasource);
    });

    test('should fetch, map, and translate categories to French', () async {
      final categories = await repository.fetchCategories();
      expect(categories.length, equals(2));
      expect(categories[0].id, equals(9));
      expect(categories[0].name, equals('Culture Générale'));
      expect(categories[1].name, equals('Livres'));
    });

    test('should fetch questions, decode HTML entities, and translate all fields to French', () async {
      final questions = await repository.fetchQuestions(amount: 1);
      expect(questions.length, equals(1));
      
      final question = questions[0];
      expect(question.category, equals('Culture Générale'));
      expect(question.question, equals('Quelle est la "capitale" de la France?'));
      expect(question.originalQuestion, equals('What is the "capital" of France?'));
      expect(question.correctAnswer, equals('Paris'));
      
      expect(question.allAnswers.length, equals(4));
      expect(question.allAnswers, contains('Paris'));
      expect(question.allAnswers, contains('Londres'));
      expect(question.allAnswers, contains('Berlin'));
      expect(question.allAnswers, contains('Rome'));

      expect(question.originalAllAnswers.length, equals(4));
      expect(question.originalAllAnswers, contains('Paris'));
      expect(question.originalAllAnswers, contains('London'));
      expect(question.originalAllAnswers, contains('Berlin'));
      expect(question.originalAllAnswers, contains('Rome'));
    });
  });
}

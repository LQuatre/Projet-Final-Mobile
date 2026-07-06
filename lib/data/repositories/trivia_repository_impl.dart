import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/trivia_category.dart';
import '../../domain/repositories/trivia_repository.dart';
import '../datasources/trivia_remote_datasource.dart';

class TriviaRepositoryImpl implements TriviaRepository {
  final TriviaRemoteDatasource remoteDatasource;
  final HtmlUnescape _unescape = HtmlUnescape();

  TriviaRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<TriviaCategory>> fetchCategories() async {
    final categoriesDto = await remoteDatasource.fetchCategories();
    if (categoriesDto.isEmpty) return [];

    // Batch translate all category names to French in a single HTTP call
    final joinedNames = categoriesDto.map((dto) => dto.name).join(' | ');
    final translatedJoined = await _translateToFrench(joinedNames, remoteDatasource.client);
    final parts = translatedJoined.split(RegExp(r'\s*\|\s*'));

    if (parts.length == categoriesDto.length) {
      return List.generate(categoriesDto.length, (index) {
        return TriviaCategory(
          id: categoriesDto[index].id,
          name: parts[index],
        );
      });
    }

    return categoriesDto.map((dto) => dto.toDomain()).toList();
  }

  Future<String> _translateToFrench(String text, http.Client client) async {
    try {
      final uri = Uri.https('api.mymemory.translated.net', '/get', {
        'q': text,
        'langpair': 'en|fr',
      });
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>;
        return responseData['translatedText'] as String;
      }
    } catch (_) {
      // Fallback on error
    }
    return text;
  }

  @override
  Future<List<QuizQuestion>> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
    String? type,
  }) async {
    final questionsDto = await remoteDatasource.fetchQuestions(
      amount: amount,
      categoryId: categoryId,
      difficulty: difficulty,
      type: type,
    );

    final futures = questionsDto.map((dto) async {
      final unescapedCategory = _unescape.convert(dto.category);
      final unescapedQuestion = _unescape.convert(dto.question);
      final unescapedCorrect = _unescape.convert(dto.correctAnswer);
      final unescapedIncorrect =
          dto.incorrectAnswers.map((ans) => _unescape.convert(ans)).toList();

      // Join category, question, and answers to translate in a single request
      final joinedSource = [
        unescapedCategory,
        unescapedQuestion,
        unescapedCorrect,
        ...unescapedIncorrect
      ].join(' | ');

      final translatedJoined = await _translateToFrench(joinedSource, remoteDatasource.client);

      final parts = translatedJoined.split(RegExp(r'\s*\|\s*'));

      String translatedCategory = unescapedCategory;
      String translatedQuestion = unescapedQuestion;
      String translatedCorrect = unescapedCorrect;
      List<String> translatedIncorrect = unescapedIncorrect;

      if (parts.length == 1 + 1 + 1 + unescapedIncorrect.length) {
        translatedCategory = parts[0];
        translatedQuestion = parts[1];
        translatedCorrect = parts[2];
        translatedIncorrect = parts.sublist(3);
      }

      final allAnswers = [translatedCorrect, ...translatedIncorrect];
      final originalAllAnswers = [unescapedCorrect, ...unescapedIncorrect];

      final indices = List<int>.generate(allAnswers.length, (i) => i)..shuffle();
      final shuffledAnswers = indices.map((i) => allAnswers[i]).toList();
      final shuffledOriginalAnswers = indices.map((i) => originalAllAnswers[i]).toList();

      return QuizQuestion(
        category: translatedCategory,
        type: dto.type,
        difficulty: dto.difficulty,
        question: translatedQuestion,
        originalQuestion: unescapedQuestion,
        correctAnswer: translatedCorrect,
        allAnswers: shuffledAnswers,
        originalAllAnswers: shuffledOriginalAnswers,
      );
    }).toList();

    return Future.wait(futures);
  }
}

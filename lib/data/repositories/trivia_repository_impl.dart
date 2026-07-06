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

    final List<TriviaCategory> results = [];
    final List<int> apiIndices = [];
    final List<String> toTranslate = [];

    for (int i = 0; i < categoriesDto.length; i++) {
      final dto = categoriesDto[i];
      if (_localCategoryTranslations.containsKey(dto.name)) {
        results.add(TriviaCategory(
          id: dto.id,
          name: _localCategoryTranslations[dto.name]!,
        ));
      } else {
        results.add(TriviaCategory(
          id: dto.id,
          name: dto.name,
        ));
        apiIndices.add(i);
        toTranslate.add(dto.name);
      }
    }

    if (toTranslate.isNotEmpty) {
      try {
        final joinedNames = toTranslate.join(' | ');
        final translatedJoined = await _translateToFrench(joinedNames, remoteDatasource.client);
        final parts = translatedJoined.split(RegExp(r'\s*\|\s*'));
        if (parts.length == toTranslate.length) {
          for (int i = 0; i < apiIndices.length; i++) {
            final index = apiIndices[i];
            results[index] = TriviaCategory(
              id: results[index].id,
              name: parts[i],
            );
          }
        }
      } catch (_) {}
    }

    return results;
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
    } catch (_) {}
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

  static const Map<String, String> _localCategoryTranslations = {
    "General Knowledge": "Culture Générale",
    "Books": "Livres",
    "Entertainment: Books": "Livres",
    "Entertainment: Film": "Divertissement : Cinéma",
    "Entertainment: Music": "Divertissement : Musique",
    "Entertainment: Musicals & Theatres": "Divertissement : Théâtre",
    "Entertainment: Television": "Divertissement : Télévision",
    "Entertainment: Video Games": "Divertissement : Jeux vidéo",
    "Entertainment: Board Games": "Divertissement : Jeux de société",
    "Science & Nature": "Sciences & Nature",
    "Science: Computers": "Sciences : Informatique",
    "Science: Mathematics": "Sciences : Mathématiques",
    "Science: Gadgets": "Sciences : Gadgets",
    "Mythology": "Mythologie",
    "Sports": "Sports",
    "Geography": "Géographie",
    "History": "Histoire",
    "Politics": "Politique",
    "Art": "Art",
    "Celebrities": "Célébrités",
    "Animals": "Animaux",
    "Vehicles": "Véhicules",
    "Entertainment: Comics": "Divertissement : Bandes dessinées",
    "Entertainment: Japanese Anime & Manga": "Divertissement : Anime & Manga japonais",
    "Entertainment: Cartoon & Animations": "Divertissement : Dessins animés",
  };
}

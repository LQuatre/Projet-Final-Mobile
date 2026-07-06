import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trivia_response_model.dart';

class TriviaRemoteDatasource {
  final http.Client client;

  TriviaRemoteDatasource({required this.client});

  Future<List<TriviaCategoryDto>> fetchCategories() async {
    final response = await client.get(
      Uri.parse('https://opentdb.com/api_category.php'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final categoriesList = data['trivia_categories'] as List<dynamic>;
      return categoriesList
          .map((json) => TriviaCategoryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load categories. Status: ${response.statusCode}');
    }
  }

  Future<List<TriviaQuestionDto>> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
    String? type,
  }) async {
    final queryParameters = {
      'amount': amount.toString(),
      'category': ?categoryId?.toString(),
      'difficulty': ?difficulty,
      'type': ?type,
    };

    final uri = Uri.https('opentdb.com', '/api.php', queryParameters);
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responseCode = data['response_code'] as int;

      if (responseCode == 0) {
        final results = data['results'] as List<dynamic>;
        return results
            .map((json) => TriviaQuestionDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (responseCode == 1) {
        return [];
      } else {
        throw Exception('API returned response code: $responseCode');
      }
    } else {
      throw Exception('Failed to load questions. Status: ${response.statusCode}');
    }
  }
}

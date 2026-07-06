import 'package:flutter/material.dart';
import '../../domain/models/quiz_question.dart';
import '../../domain/models/trivia_category.dart';
import '../../domain/repositories/trivia_repository.dart';

enum QuizState { initial, loadingCategories, idle, loadingQuestions, playing, finished, error }

class QuizController extends ChangeNotifier {
  final TriviaRepository repository;

  QuizController({required this.repository});

  QuizState _state = QuizState.initial;
  QuizState get state => _state;

  List<TriviaCategory> _categories = [];
  List<TriviaCategory> get categories => _categories;

  TriviaCategory? _selectedCategory;
  TriviaCategory? get selectedCategory => _selectedCategory;

  String _selectedDifficulty = 'medium';
  String get selectedDifficulty => _selectedDifficulty;

  int _selectedAmount = 10;
  int get selectedAmount => _selectedAmount;

  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _score = 0;
  int get score => _score;

  void selectCategory(TriviaCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void selectAmount(int amount) {
    _selectedAmount = amount;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _state = QuizState.loadingCategories;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await repository.fetchCategories();
      _state = QuizState.idle;
    } catch (e) {
      _errorMessage = 'Impossible de charger les catégories : ${e.toString()}';
      _state = QuizState.error;
    }
    notifyListeners();
  }

  Future<void> startQuiz() async {
    _state = QuizState.loadingQuestions;
    _errorMessage = null;
    _currentQuestionIndex = 0;
    _score = 0;
    notifyListeners();

    try {
      _questions = await repository.fetchQuestions(
        amount: _selectedAmount,
        categoryId: _selectedCategory?.id,
        difficulty: _selectedDifficulty == 'all' ? null : _selectedDifficulty,
      );

      if (_questions.isEmpty) {
        _errorMessage = 'Aucune question trouvée pour ces critères.';
        _state = QuizState.error;
      } else {
        _state = QuizState.playing;
      }
    } catch (e) {
      _errorMessage = 'Impossible de charger les questions : ${e.toString()}';
      _state = QuizState.error;
    }
    notifyListeners();
  }

  void answerQuestion(String answer) {
    if (_state != QuizState.playing) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    if (currentQuestion.isAnswered) return;

    final updatedQuestion = currentQuestion.copyWith(selectedAnswer: answer);
    _questions[_currentQuestionIndex] = updatedQuestion;

    if (updatedQuestion.isCorrect) {
      _score++;
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (_state != QuizState.playing) return;
    
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _state = QuizState.finished;
    }
    notifyListeners();
  }

  void resetQuiz() {
    _questions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _state = QuizState.idle;
    notifyListeners();
  }
}

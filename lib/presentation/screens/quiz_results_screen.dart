import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/quiz_controller.dart';
import '../theme/app_theme.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<QuizController>(
        builder: (context, controller, child) {
          final total = controller.questions.length;
          final score = controller.score;
          final percentage = total > 0 ? (score / total * 100).round() : 0;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Score Final',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$score / $total',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 48,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        Text(
                          '$percentage% de bonnes réponses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: percentage >= 50 ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Question Recap Title
                Text(
                  'Récapitulatif',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),

                // Detailed Recap List
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.questions.length,
                    itemBuilder: (context, index) {
                      final question = controller.questions[index];
                      final isCorrect = question.isCorrect;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${index + 1}: ${question.question}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.cancel,
                                    color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Votre réponse : ${question.selectedAnswer}',
                                      style: TextStyle(
                                        color: isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Bonne réponse : ${question.correctAnswer}',
                                  style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Restart Button
                ElevatedButton(
                  onPressed: () {
                    controller.resetQuiz();
                    Navigator.of(context).pop();
                  },
                  child: const Text('REJOUER'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

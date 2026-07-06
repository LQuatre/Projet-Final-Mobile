import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/quiz_controller.dart';
import '../theme/app_theme.dart';
import 'quiz_game_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<QuizController>();
      if (controller.state == QuizState.initial) {
        controller.loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurer le Quiz'),
      ),
      body: Consumer<QuizController>(
        builder: (context, controller, child) {
          if (controller.state == QuizState.loadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.state == QuizState.error && controller.categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.errorMessage ?? 'Une erreur est survenue',
                      style: const TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadCategories(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paramètres du Quiz',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Catégorie',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      initialValue: controller.selectedCategory?.id,
                      hint: const Text('Toutes les catégories'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Toutes les catégories'),
                        ),
                        ...controller.categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }),
                      ],
                      onChanged: (id) {
                        final cat = id == null
                            ? null
                            : controller.categories.firstWhere((c) => c.id == id);
                        controller.selectCategory(cat);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Difficulty Selection
                    Text(
                      'Difficulté',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      initialValue: controller.selectedDifficulty,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Toutes')),
                        DropdownMenuItem(value: 'easy', child: Text('Facile')),
                        DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                        DropdownMenuItem(value: 'hard', child: Text('Difficile')),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.selectDifficulty(val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Question Amount
                    Text(
                      'Nombre de questions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      initialValue: controller.selectedAmount,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 Questions')),
                        DropdownMenuItem(value: 10, child: Text('10 Questions')),
                        DropdownMenuItem(value: 15, child: Text('15 Questions')),
                        DropdownMenuItem(value: 20, child: Text('20 Questions')),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.selectAmount(val);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Start Button
                    ElevatedButton(
                      onPressed: () async {
                        await controller.startQuiz();
                        if (!context.mounted) return;
                        if (controller.state == QuizState.playing) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QuizGameScreen(),
                            ),
                          );
                        } else if (controller.state == QuizState.error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.errorMessage ?? 'Erreur lors du lancement'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                      child: controller.state == QuizState.loadingQuestions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('DÉMARRER LE QUIZ'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

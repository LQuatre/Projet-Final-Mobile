import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/quiz_controller.dart';
import '../theme/app_theme.dart';
import 'quiz_results_screen.dart';
import '../widgets/scale_on_press.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> with SingleTickerProviderStateMixin {
  bool _showOriginal = false;
  int _lastQuestionIndex = -1;
  late AnimationController _glitterAnimationController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _glitterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glitterAnimationController.addListener(() {
      setState(() {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.4;
          p.vx *= 0.98;
          p.vy *= 0.98;
          p.rotation += p.rotationSpeed;
        }
      });
    });
  }

  @override
  void dispose() {
    _glitterAnimationController.dispose();
    super.dispose();
  }

  void _spawnGlitter(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    _particles.clear();

    final colors = [
      Colors.amber,
      const Color(0xFFFFD700),
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.lightGreenAccent,
    ];

    for (int i = 0; i < 25; i++) {
      final angle = -random.nextDouble() * (math.pi / 3);
      final speed = 8.0 + random.nextDouble() * 14.0;
      _particles.add(Particle(
        x: 0,
        y: size.height * 0.55,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 4.0,
        color: colors[random.nextInt(colors.length)],
        size: 6.0 + random.nextDouble() * 8.0,
        rotation: random.nextDouble() * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.15,
      ));
    }

    for (int i = 0; i < 25; i++) {
      final angle = math.pi - random.nextDouble() * (math.pi / 3);
      final speed = 8.0 + random.nextDouble() * 14.0;
      _particles.add(Particle(
        x: size.width,
        y: size.height * 0.55,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 4.0,
        color: colors[random.nextInt(colors.length)],
        size: 6.0 + random.nextDouble() * 8.0,
        rotation: random.nextDouble() * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.15,
      ));
    }

    _glitterAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz en cours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Quitter le quiz ?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Voulez-vous vraiment quitter la partie en cours ? Votre progression actuelle sera perdue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "Oui, quitter",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text(
                          "Continuer la partie",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Consumer<QuizController>(
            builder: (context, controller, child) {
              if (controller.questions.isEmpty) {
                return const Center(child: Text('Aucune question chargée.'));
              }

              final questionIndex = controller.currentQuestionIndex;
              final totalQuestions = controller.questions.length;
              final currentQuestion = controller.questions[questionIndex];

              if (_lastQuestionIndex != questionIndex) {
                _showOriginal = false;
                _lastQuestionIndex = questionIndex;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (questionIndex + 1) / totalQuestions,
                      backgroundColor: AppTheme.borderLight,
                      color: AppTheme.primaryColor,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${questionIndex + 1} sur $totalQuestions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            switch (currentQuestion.difficulty.toLowerCase()) {
                              'easy' => 'FACILE',
                              'medium' => 'MOYEN',
                              'hard' => 'DIFFICILE',
                              _ => currentQuestion.difficulty.toUpperCase(),
                            },
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _showOriginal ? currentQuestion.originalQuestion : currentQuestion.question,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(currentQuestion.allAnswers.length, (index) {
                      final frenchAnswer = currentQuestion.allAnswers[index];
                      final englishAnswer = currentQuestion.originalAllAnswers[index];
                      final displayText = _showOriginal ? englishAnswer : frenchAnswer;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildAnswerButton(
                          context,
                          currentQuestion,
                          frenchAnswer,
                          displayText,
                          controller,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showOriginal = !_showOriginal;
                          });
                        },
                        icon: Icon(
                          _showOriginal ? Icons.g_translate : Icons.translate,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(
                          _showOriginal ? "VOIR LE QUIZ EN FRANÇAIS" : "VOIR LE QUIZ EN ANGLAIS (EN)",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentQuestion.isAnswered)
                      ElevatedButton(
                        onPressed: () {
                          controller.nextQuestion();
                          if (controller.state == QuizState.finished) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const QuizResultsScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                        ),
                        child: Text(
                          questionIndex == totalQuestions - 1
                              ? 'VOIR LES RÉSULTATS'
                              : 'QUESTION SUIVANTE',
                        ),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              );
            },
          ),
          if (_glitterAnimationController.isAnimating)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: GlitterPainter(particles: _particles),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(
    BuildContext context,
    dynamic question,
    String answer,
    String displayText,
    QuizController controller,
  ) {
    final isAnswered = question.isAnswered;
    final isCorrectAnswer = answer == question.correctAnswer;
    final isSelectedAnswer = answer == question.selectedAnswer;

    Color buttonColor = Colors.white;
    Color textColor = AppTheme.textPrimary;
    BorderSide borderSide = const BorderSide(color: AppTheme.borderLight, width: 1.5);

    if (isAnswered) {
      if (isCorrectAnswer) {
        buttonColor = AppTheme.successColor.withValues(alpha: 0.15);
        textColor = AppTheme.successColor;
        borderSide = const BorderSide(color: AppTheme.successColor, width: 2);
      } else if (isSelectedAnswer) {
        buttonColor = AppTheme.errorColor.withValues(alpha: 0.15);
        textColor = AppTheme.errorColor;
        borderSide = const BorderSide(color: AppTheme.errorColor, width: 2);
      } else {
        textColor = AppTheme.textSecondary;
      }
    }

    return ScaleOnPress(
      onTap: isAnswered
          ? null
          : () {
              controller.answerQuestion(answer);
              if (answer == question.correctAnswer) {
                _spawnGlitter(context);
              }
            },
      child: OutlinedButton(
        onPressed: null, // Gesture detection and tap action handled by ScaleOnPress wrapper
        style: OutlinedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          side: borderSide,
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class GlitterPainter extends CustomPainter {
  final List<Particle> particles;

  GlitterPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final r = p.size / 2;
      final path = Path()
        ..moveTo(0, -r)
        ..lineTo(r, 0)
        ..lineTo(0, r)
        ..lineTo(-r, 0)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

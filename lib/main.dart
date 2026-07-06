import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'data/datasources/trivia_remote_datasource.dart';
import 'data/repositories/trivia_repository_impl.dart';
import 'domain/repositories/trivia_repository.dart';
import 'presentation/controllers/quiz_controller.dart';
import 'presentation/screens/category_selection_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  final httpClient = http.Client();
  final remoteDatasource = TriviaRemoteDatasource(client: httpClient);
  final repository = TriviaRepositoryImpl(remoteDatasource: remoteDatasource);

  runApp(
    MultiProvider(
      providers: [
        Provider<TriviaRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (context) => QuizController(repository: repository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzty',
      theme: AppTheme.lightTheme,
      home: const CategorySelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

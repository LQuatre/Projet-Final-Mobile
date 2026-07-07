import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'data/datasources/landmark_api_service.dart';
import 'data/datasources/trivia_remote_datasource.dart';
import 'data/repositories/landmark_repository_impl.dart';
import 'data/repositories/trivia_repository_impl.dart';
import 'domain/repositories/landmark_repository.dart';
import 'domain/repositories/trivia_repository.dart';
import 'presentation/controllers/landmark_controller.dart';
import 'presentation/controllers/quiz_controller.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  final httpClient = http.Client();
  final remoteDatasource = TriviaRemoteDatasource(client: httpClient);
  final repository = TriviaRepositoryImpl(remoteDatasource: remoteDatasource);

  final landmarkApiService = LandmarkApiService();
  final landmarkRepository = LandmarkRepositoryImpl(apiService: landmarkApiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<TriviaRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (context) => QuizController(repository: repository),
        ),
        Provider<LandmarkRepository>.value(value: landmarkRepository),
        ChangeNotifierProvider(
          create: (context) => LandmarkController(repository: landmarkRepository)..loadLandmarks(),
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
      title: 'TravelQuizzie',
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

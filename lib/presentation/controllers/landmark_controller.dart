import 'package:flutter/material.dart';
import '../../domain/models/landmark.dart';
import '../../domain/repositories/landmark_repository.dart';

enum LandmarkState { initial, loading, loaded, error }

class LandmarkController extends ChangeNotifier {
  final LandmarkRepository repository;

  LandmarkController({required this.repository});

  LandmarkState _state = LandmarkState.initial;
  LandmarkState get state => _state;

  List<Landmark> _landmarks = [];
  List<Landmark> get landmarks => _landmarks;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get visitedCount => _landmarks.where((l) => l.isVisited).length;

  Future<void> loadLandmarks() async {
    _state = LandmarkState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _landmarks = await repository.fetchLandmarks();
      _state = LandmarkState.loaded;
    } catch (e) {
      _errorMessage = "Impossible de charger les données.";
      _state = LandmarkState.error;
    }
    notifyListeners();
  }

  Future<void> visitLandmark(String id, String photoPath) async {
    try {
      await repository.markAsVisited(id);
      await repository.savePhotoPath(id, photoPath);
      
      final index = _landmarks.indexWhere((l) => l.id == id);
      if (index != -1) {
        _landmarks[index].isVisited = true;
        _landmarks[index].imageUrl = photoPath;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur lors du marquage comme visité : $e");
    }
  }
}

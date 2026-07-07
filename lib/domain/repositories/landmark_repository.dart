import '../models/landmark.dart';

abstract class LandmarkRepository {
  Future<List<Landmark>> fetchLandmarks();
  Future<List<String>> getVisitedIds();
  Future<void> markAsVisited(String id);
  Future<void> savePhotoPath(String id, String path);
  Future<String?> getPhotoPath(String id);
}

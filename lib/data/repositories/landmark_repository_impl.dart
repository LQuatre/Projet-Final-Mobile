import '../../domain/models/landmark.dart';
import '../../domain/repositories/landmark_repository.dart';
import '../datasources/landmark_api_service.dart';

class LandmarkRepositoryImpl implements LandmarkRepository {
  final LandmarkApiService apiService;

  LandmarkRepositoryImpl({required this.apiService});

  @override
  Future<List<Landmark>> fetchLandmarks() => apiService.fetchLandmarks();

  @override
  Future<List<String>> getVisitedIds() => apiService.getVisitedIds();

  @override
  Future<void> markAsVisited(String id) => apiService.markAsVisited(id);

  @override
  Future<void> savePhotoPath(String id, String path) => apiService.savePhotoPath(id, path);

  @override
  Future<String?> getPhotoPath(String id) => apiService.getPhotoPath(id);
}

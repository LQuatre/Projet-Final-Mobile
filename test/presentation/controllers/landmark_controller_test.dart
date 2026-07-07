import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/domain/models/landmark.dart';
import 'package:quiz_app/domain/repositories/landmark_repository.dart';
import 'package:quiz_app/presentation/controllers/landmark_controller.dart';

class MockLandmarkRepository implements LandmarkRepository {
  bool shouldFail = false;
  final List<Landmark> mockLandmarks = [
    Landmark(
      id: '1',
      title: 'Tour Eiffel',
      imageUrl: 'http://eiffel.jpg',
      description: 'Description 1',
      latitude: 48.8584,
      longitude: 2.2945,
      date: '1889-03-31',
    ),
    Landmark(
      id: '2',
      title: 'Colisée',
      imageUrl: 'http://colisee.jpg',
      description: 'Description 2',
      latitude: 41.8902,
      longitude: 12.4922,
      date: '0080-01-01',
      isVisited: true,
    ),
  ];

  final List<String> visitedIds = ['2'];
  final Map<String, String> photoPaths = {};

  @override
  Future<List<Landmark>> fetchLandmarks() async {
    if (shouldFail) throw Exception('API Error');
    return mockLandmarks;
  }

  @override
  Future<List<String>> getVisitedIds() async {
    return visitedIds;
  }

  @override
  Future<void> markAsVisited(String id) async {
    if (!visitedIds.contains(id)) {
      visitedIds.add(id);
    }
  }

  @override
  Future<void> savePhotoPath(String id, String path) async {
    photoPaths[id] = path;
  }

  @override
  Future<String?> getPhotoPath(String id) async {
    return photoPaths[id];
  }
}

void main() {
  group('LandmarkController', () {
    late MockLandmarkRepository mockRepository;
    late LandmarkController controller;

    setUp(() {
      mockRepository = MockLandmarkRepository();
      controller = LandmarkController(repository: mockRepository);
    });

    test('initial state', () {
      expect(controller.state, equals(LandmarkState.initial));
      expect(controller.landmarks.isEmpty, isTrue);
      expect(controller.visitedCount, equals(0));
    });

    test('loadLandmarks success', () async {
      await controller.loadLandmarks();
      expect(controller.state, equals(LandmarkState.loaded));
      expect(controller.landmarks.length, equals(2));
      expect(controller.visitedCount, equals(1));
    });

    test('loadLandmarks failure', () async {
      mockRepository.shouldFail = true;
      await controller.loadLandmarks();
      expect(controller.state, equals(LandmarkState.error));
      expect(
        controller.errorMessage,
        equals('Impossible de charger les données.'),
      );
    });

    test('visitLandmark success updates state', () async {
      await controller.loadLandmarks();
      expect(controller.visitedCount, equals(1));

      // Visiter la Tour Eiffel (id '1')
      await controller.visitLandmark('1', 'local/path/to/eiffel.jpg');

      expect(controller.visitedCount, equals(2));
      expect(controller.landmarks[0].isVisited, isTrue);
      expect(
        controller.landmarks[0].imageUrl,
        equals('local/path/to/eiffel.jpg'),
      );
      expect(mockRepository.visitedIds, contains('1'));
      expect(
        mockRepository.photoPaths['1'],
        equals('local/path/to/eiffel.jpg'),
      );
    });
  });
}

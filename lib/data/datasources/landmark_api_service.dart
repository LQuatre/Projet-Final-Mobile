import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/landmark.dart';

class LandmarkApiService {
  static const String apiUrl = 'https://raw.githubusercontent.com/lucas-diot/mock-api/main/landmarks.json';

  static final List<Landmark> fallbackLandmarks = [
    Landmark(
      id: '1',
      title: 'Tour Eiffel',
      imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=800&q=80',
      description: 'La tour Eiffel est une tour de fer puddlé de 330 m de hauteur située à Paris, à l\'extrémité nord-ouest du parc du Champ-de-Mars en bordure de la Seine. Construite par Gustave Eiffel et ses collaborateurs pour l\'Exposition universelle de Paris de 1889, elle est devenue le symbole de la capitale française.',
      latitude: 48.8584,
      longitude: 2.2945,
      date: '1889-03-31',
    ),
    Landmark(
      id: '2',
      title: 'Colisée',
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=800&q=80',
      description: 'Le Colisée est un immense amphithéâtre ovoïde situé dans le centre de la ville de Rome, en Italie. C\'est l\'une des plus grandes œuvres de l\'architecture et de l\'ingénierie romaines, construite au Ier siècle apr. J.-C. sous le règne des empereurs Flaviens.',
      latitude: 41.8902,
      longitude: 12.4922,
      date: '0080-01-01',
    ),
    Landmark(
      id: '3',
      title: 'Taj Mahal',
      imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80',
      description: 'Le Taj Mahal, qui signifie « le palais de la couronne », est situé à Agra, dans l\'État de l\'Uttar Pradesh, en Inde. C\'est un mausolée de marbre blanc construit par l\'empereur moghol Shah Jahan en mémoire de son épouse favorite Mumtaz Mahal.',
      latitude: 27.1751,
      longitude: 78.0421,
      date: '1648-01-01',
    ),
    Landmark(
      id: '4',
      title: 'Statue de la Liberté',
      imageUrl: 'https://images.unsplash.com/photo-1605130284535-11dd9eedc58a?auto=format&fit=crop&w=800&q=80',
      description: 'La Statue de la Liberté, située sur Liberty Island au sud de Manhattan à New York, est l\'un des monuments les plus célèbres des États-Unis. Offerte par le peuple français en signe d\'amitié, elle fut inaugurée en 1886.',
      latitude: 40.6892,
      longitude: -74.0445,
      date: '1886-10-28',
    ),
    Landmark(
      id: '5',
      title: 'Machu Picchu',
      imageUrl: 'https://images.unsplash.com/photo-1507629221898-506a36b5d711?auto=format&fit=crop&w=800&q=80',
      description: 'Machu Picchu est une ancienne cité inca du XVe siècle perchée sur un promontoire rocheux des Andes péruviennes. Abandonnée lors de l\'effondrement de l\'Empire inca, elle a été révélée au monde entier par l\'historien américain Hiram Bingham en 1911.',
      latitude: -13.1631,
      longitude: -72.5450,
      date: '1450-01-01',
    ),
  ];

  Future<List<String>> getVisitedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('visited_landmark_ids') ?? [];
  }

  Future<void> savePhotoPath(String id, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('landmark_photo_$id', path);
  }

  Future<String?> getPhotoPath(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('landmark_photo_$id');
  }

  Future<void> markAsVisited(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> visited = prefs.getStringList('visited_landmark_ids') ?? [];
    if (!visited.contains(id)) {
      visited.add(id);
      await prefs.setStringList('visited_landmark_ids', visited);
    }
  }

  Future<List<Landmark>> fetchLandmarks() async {
    List<Landmark> landmarks;
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        landmarks = data.map((json) => Landmark.fromJson(json)).toList();
      } else {
        landmarks = List.from(fallbackLandmarks);
      }
    } catch (e) {
      landmarks = List.from(fallbackLandmarks);
    }

    final prefs = await SharedPreferences.getInstance();
    final visitedIds = await getVisitedIds();
    for (var landmark in landmarks) {
      if (visitedIds.contains(landmark.id)) {
        landmark.isVisited = true;
        final localPhoto = prefs.getString('landmark_photo_${landmark.id}');
        if (localPhoto != null && localPhoto.isNotEmpty) {
          landmark.imageUrl = localPhoto;
        }
      }
    }
    return landmarks;
  }
}

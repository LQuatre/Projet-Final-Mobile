class Landmark {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final double latitude;
  final double longitude;
  final String date;
  bool isVisited;

  Landmark({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.date,
    this.isVisited = false,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? '',
      isVisited: json['isVisited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': imageUrl,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'date': date,
      'isVisited': isVisited,
    };
  }
}

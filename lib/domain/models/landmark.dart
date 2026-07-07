class Landmark {
  final String id;
  final String title;
  String imageUrl;
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

  String get formattedDate {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return date;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year == null || month == null || day == null) return date;

      if (year < 100) {
        return "An $year";
      }

      if (month == 1 && day == 1) {
        return "$year";
      }

      final monthsFr = [
        "janvier",
        "février",
        "mars",
        "avril",
        "mai",
        "juin",
        "juillet",
        "août",
        "septembre",
        "octobre",
        "novembre",
        "décembre"
      ];

      if (month >= 1 && month <= 12) {
        return "$day ${monthsFr[month - 1]} $year";
      }
    } catch (_) {}
    return date;
  }
}

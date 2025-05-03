class Post {
  final String id;
  final String title;
  final String message;
  final String weather;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.title,
    required this.message,
    required this.weather,
    required this.timestamp,
  });

  Post copyWith({
    String? id,
    String? title,
    String? message,
    String? weather,
    DateTime? timestamp,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      weather: weather ?? this.weather,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
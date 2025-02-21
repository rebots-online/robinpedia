class Article {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;

  Article({
    required this.id,
    required this.title,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

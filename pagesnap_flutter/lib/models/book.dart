class LocalBook {
  final String id;
  final String title;
  double progress;
  int wordIndex;
  final int totalWords;
  int lastRead;
  final List<String> words;

  LocalBook({
    required this.id,
    required this.title,
    required this.progress,
    required this.wordIndex,
    required this.totalWords,
    required this.lastRead,
    required this.words,
  });

  factory LocalBook.fromJson(Map<String, dynamic> json) {
    return LocalBook(
      id: json['id'],
      title: json['title'],
      progress: (json['progress'] as num).toDouble(),
      wordIndex: json['wordIndex'],
      totalWords: json['totalWords'],
      lastRead: json['lastRead'],
      words: List<String>.from(json['words']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'progress': progress,
      'wordIndex': wordIndex,
      'totalWords': totalWords,
      'lastRead': lastRead,
      'words': words,
    };
  }
}

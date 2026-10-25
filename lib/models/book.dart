class Book {
  final int? id;
  final String title;
  final String category;
  final String fileName;
  final String filePath;
  final String remoteUrl;
  final String date;
  final int fileSize;

  Book({
    this.id,
    required this.title,
    required this.category,
    required this.fileName,
    required this.filePath,
    required this.remoteUrl,
    required this.date,
    this.fileSize = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'fileName': fileName,
    'filePath': filePath,
    'remoteUrl': remoteUrl,
    'date': date,
    'fileSize': fileSize,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'fileName': fileName,
    'remoteUrl': remoteUrl,
    'date': date,
    'fileSize': fileSize,
  };

  factory Book.fromMap(Map<String, dynamic> m) => Book(
    id: m['id'],
    title: m['title'],
    category: m['category'],
    fileName: m['fileName'],
    filePath: m['filePath'] ?? '',
    remoteUrl: m['remoteUrl'] ?? '',
    date: m['date'],
    fileSize: m['fileSize'] ?? 0,
  );

  factory Book.fromJson(Map<String, dynamic> m) => Book(
    title: m['title'],
    category: m['category'],
    fileName: m['fileName'],
    filePath: '',
    remoteUrl: m['remoteUrl'] ?? '',
    date: m['date'],
    fileSize: m['fileSize'] ?? 0,
  );
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'fadnia.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          fileName TEXT NOT NULL,
          filePath TEXT NOT NULL,
          remoteUrl TEXT NOT NULL,
          date TEXT NOT NULL,
          fileSize INTEGER DEFAULT 0
        )
      ''');
    });
    return _db!;
  }

  static Future<List<Book>> getBooks() async {
    final db = await database;
    final rows = await db.query('books', orderBy: 'id DESC');
    return rows.map((e) => Book.fromMap(e)).toList();
  }

  static Future<int> insertBook(Book b) async {
    final db = await database;
    return db.insert('books', b.toMap());
  }

  static Future<void> deleteBook(int id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }
}

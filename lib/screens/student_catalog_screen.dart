import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/book.dart';
import '../services/database_service.dart';

class StudentCatalogScreen extends StatefulWidget {
  final String studentName;
  final String serverUrl;
  StudentCatalogScreen({required this.studentName, required this.serverUrl});

  @override
  _StudentCatalogScreenState createState() => _StudentCatalogScreenState();
}

class _StudentCatalogScreenState extends State<StudentCatalogScreen> {
  List<Book> remoteBooks = [];
  Set<String> downloadedKeys = {};
  bool loading = true;
  String? error;

  final primary = ['الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي'];
  final middle = ['الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط'];
  final general = ['مراجع وعام'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(Book b) => '${b.category}::${b.title}';

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await http
          .get(Uri.parse('${widget.serverUrl}/api/books'))
          .timeout(Duration(seconds: 8));
      final list = (jsonDecode(res.body) as List)
          .map((e) => Book.fromJson(e)).toList();
      remoteBooks = list;
      final local = await DatabaseService.getBooks();
      downloadedKeys = local.map(_key).toSet();
    } catch (e) {
      error = 'تعذّر الاتصال بسيرفر المشرف. تأكد من:\n'
          '• تشغيل السيرفر على هاتف المشرف.\n'
          '• الاتصال بنفس شبكة الواي فاي.';
    }
    setState(() => loading = false);
  }

  Future<void> _download(Book b) async {
    try {
      final url = '${widget.serverUrl}/files/${b.fileName}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('فشل التحميل');

      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${dir.path}/downloaded_books');
      if (!await booksDir.exists()) await booksDir.create(recursive: true);
      final file = File('${booksDir.path}/${b.fileName}');
      await file.writeAsBytes(res.bodyBytes);

      final book = Book(
        title: b.title,
        category: b.category,
        fileName: b.fileName,
        filePath: file.path,
        remoteUrl: url,
        date: b.date,
        fileSize: res.bodyBytes.length,
      );
      await DatabaseService.insertBook(book);

      setState(() => downloadedKeys.add(_key(b)));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل: ${b.title} ✅')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحميل: $e')));
    }
  }

  Future<void> _openDownloaded(Book b) async {
    final local = await DatabaseService.getBooks();
    final found = local.firstWhere(
        (x) => x.title == b.title && x.category == b.category,
        orElse: () => Book(title: '', category: '', fileName: '',
            filePath: '', remoteUrl: '', date: ''));
    if (found.filePath.isEmpty) return;
    await OpenFilex.open(found.filePath);
  }

  void _showGrade(String grade) {
    final books = remoteBooks.where((b) => b.category == grade).toList();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.7, maxChildSize: 0.95,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.all(16),
          children: [
            Text('كتب: $grade',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Divider(),
            if (books.isEmpty)
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('لا توجد كتب في هذا الصف',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            ...books.map((b) {
              final downloaded = downloadedKeys.contains(_key(b));
              return Card(
                child: ListTile(
                  leading: Icon(Icons.menu_book, color: Colors.blue.shade700),
                  title: Text(b.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${b.date} • ${(b.fileSize / 1024).toStringAsFixed(0)} KB'),
                  trailing: downloaded
                      ? IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'مفتوح',
                          onPressed: () => _openDownloaded(b),
                        )
                      : IconButton(
                          icon: Icon(Icons.download, color: Colors.blue),
                          tooltip: 'تحميل',
                          onPressed: () => _download(b),
                        ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _gradeCard(String name, Color color) {
    final count = remoteBooks.where((b) => b.category == name).length;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(name.substring(0, 1),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$count كتاب متاح'),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => _showGrade(name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المكتبة - ${widget.studentName}'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 64, color: Colors.red.shade300),
                        SizedBox(height: 16),
                        Text(error!, textAlign: TextAlign.center),
                        SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _sectionTitle('المرحلة الابتدائية', Colors.blue),
                    ...primary.map((g) => _gradeCard(g, Colors.blue)),
                    _sectionTitle('المرحلة المتوسطة', Colors.indigo),
                    ...middle.map((g) => _gradeCard(g, Colors.indigo)),
                    _sectionTitle('المراجع العامة', Colors.purple),
                    ...general.map((g) => _gradeCard(g, Colors.purple)),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String t, Color c) => Padding(
    padding: EdgeInsets.fromLTRB(0, 20, 0, 8),
    child: Text(t, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c)),
  );
}

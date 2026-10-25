import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import '../services/local_server.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final server = LocalServer();
  final titleCtrl = TextEditingController();
  String category = 'الرابع الابتدائي';
  String serverUrl = '';
  bool busy = false;

  final cats = ['الرابع الابتدائي', 'الخامس الابتدائي', 'السادس الابتدائي',
                'الأول المتوسط', 'الثاني المتوسط', 'الثالث المتوسط', 'مراجع وعام'];

  Future<void> _toggleServer() async {
    setState(() => busy = true);
    if (server.isRunning) {
      await server.stop();
      setState(() => serverUrl = '');
    } else {
      final books = await DatabaseService.getBooks();
      await server.start(books);
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      setState(() => serverUrl = 'http://$ip:8080');
    }
    setState(() => busy = false);
  }

  Future<void> _upload() async {
    if (titleCtrl.text.trim().isEmpty) {
      _msg('أدخل عنوان المادة');
      return;
    }
    final res = await FilePicker.platform.pickFiles();
    if (res == null) return;
    final source = File(res.files.single.path!);
    final fileName = res.files.single.name;

    final path = await server.copyToLibrary(source, fileName);

    final book = Book(
      title: titleCtrl.text.trim(),
      category: category,
      fileName: fileName,
      filePath: path,
      remoteUrl: '/files/$fileName',
      date: DateTime.now().toLocal().toString().split(' ')[0],
      fileSize: await source.length(),
    );
    await DatabaseService.insertBook(book);
    titleCtrl.clear();
    _msg('تم الرفع بنجاح ✅');
    setState(() {});
    if (server.isRunning) {
      final books = await DatabaseService.getBooks();
      await server.stop();
      await server.start(books);
    }
  }

  void _msg(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لوحة المشرف')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            color: server.isRunning ? Colors.green.shade50 : Colors.grey.shade100,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    Icon(server.isRunning ? Icons.wifi : Icons.wifi_off,
                        color: server.isRunning ? Colors.green : Colors.grey),
                    SizedBox(width: 8),
                    Text(server.isRunning ? 'السيرفر يعمل' : 'السيرفر متوقف',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  if (serverUrl.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('اكتب هذا العنوان في هاتف الطالب:',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    SelectableText(serverUrl,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                  SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: server.isRunning ? Colors.red : Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 14)),
                    icon: Icon(server.isRunning ? Icons.stop : Icons.play_arrow,
                        color: Colors.white),
                    label: Text(server.isRunning ? 'إيقاف السيرفر' : 'تشغيل السيرفر',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    onPressed: busy ? null : _toggleServer,
                  )),
                ],
              ),
            ),
          ),
          Divider(height: 32),
          Text('رفع كتاب / مذكرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          TextField(controller: titleCtrl,
              decoration: InputDecoration(labelText: 'عنوان المادة', border: OutlineInputBorder())),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: category,
            items: cats.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => category = v!),
            decoration: InputDecoration(labelText: 'الصف', border: OutlineInputBorder()),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.upload_file),
            label: Text('اختيار ملف ورفعه'),
            onPressed: _upload,
          ),
          Divider(height: 32),
          Text('الكتب المرفوعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          FutureBuilder<List<Book>>(
            future: DatabaseService.getBooks(),
            builder: (_, snap) {
              if (!snap.hasData) return CircularProgressIndicator();
              final books = snap.data!;
              if (books.isEmpty) return Text('لا توجد كتب بعد');
              return Column(
                children: books.map((b) => ListTile(
                  title: Text(b.title),
                  subtitle: Text(b.category),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseService.deleteBook(b.id!);
                      final f = File(b.filePath);
                      if (await f.exists()) await f.delete();
                      setState(() {});
                    },
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

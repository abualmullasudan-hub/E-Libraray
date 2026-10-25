import 'package:flutter/material.dart';
import 'student_catalog_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final ipCtrl = TextEditingController(text: '192.168.1.');
  final portCtrl = TextEditingController(text: '8080');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('دخول الطالب')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('بياناتك:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            TextField(controller: nameCtrl,
                decoration: InputDecoration(labelText: 'اسمك', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: codeCtrl,
                decoration: InputDecoration(labelText: 'رقم العضوية', border: OutlineInputBorder())),
            SizedBox(height: 24),
            Text('عنوان سيرفر المشرف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('(يظهر على شاشة هاتف المشرف)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 8),
            Row(children: [
              Expanded(flex: 3, child: TextField(
                  controller: ipCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'IP', border: OutlineInputBorder()))),
              SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(
                  controller: portCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'منفذ', border: OutlineInputBorder()))),
            ]),
            SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, padding: EdgeInsets.symmetric(vertical: 16)),
              icon: Icon(Icons.wifi),
              label: Text('اتصال بالمكتبة'),
              onPressed: () {
                final ip = ipCtrl.text.trim();
                final port = portCtrl.text.trim();
                if (ip.isEmpty || nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('أكمل البيانات')));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentCatalogScreen(
                      studentName: nameCtrl.text.trim(),
                      serverUrl: 'http://$ip:$port',
                    )));
              },
            ),
          ],
        ),
      ),
    );
  }
}

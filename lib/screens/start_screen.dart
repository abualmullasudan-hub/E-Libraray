import 'package:flutter/material.dart';
import 'student_login_screen.dart';
import 'admin_screen.dart';

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.library_books, size: 80, color: Colors.blue.shade800),
              SizedBox(height: 16),
              Text('مدرسة الفادنية شرق',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text('المكتبة الرقمية - عبر الواي فاي',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 48),
              _btn(icon: Icons.school, label: 'دخول الطالب',
                color: Colors.blue, onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StudentLoginScreen()))),
              SizedBox(height: 16),
              _btn(icon: Icons.admin_panel_settings, label: 'دخول المشرف',
                color: Colors.deepPurple, onTap: () => _askAdminPass(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn({required IconData icon, required String label,
      required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: TextStyle(fontSize: 17, color: Colors.white)),
        onPressed: onTap,
      ),
    );
  }

  void _askAdminPass(BuildContext context) async {
    final c = TextEditingController();
    final pass = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: Text('كلمة سر المشرف'),
      content: TextField(controller: c, obscureText: true, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(context, c.text), child: Text('دخول')),
      ],
    ));
    if (pass == '1234') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()));
    } else if (pass != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('كلمة السر غير صحيحة')));
    }
  }
}

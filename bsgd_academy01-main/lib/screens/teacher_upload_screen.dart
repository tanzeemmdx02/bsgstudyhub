import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeacherUploadScreen extends StatelessWidget {
  final bool embedded;

  const TeacherUploadScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Upload Center',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'Upload courses, videos, notices, and suggestions for students.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Upload forms and file pickers can be placed here.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Upload')),
      body: body,
    );
  }
}
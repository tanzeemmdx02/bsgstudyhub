import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeacherManagementScreen extends StatelessWidget {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Academy Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'Manage uploaded items, active courses, exams, and student records.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Management tools and content lists appear here.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
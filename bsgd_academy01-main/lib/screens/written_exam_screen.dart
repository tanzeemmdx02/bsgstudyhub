import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'student_dashboard_screen.dart';

class WrittenExamScreen extends StatelessWidget {
  const WrittenExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Written Examination Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Physics 1st Paper - Newtonian Mechanics Written Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Total Marks: 30 • Class 12 Science', style: TextStyle(color: AppTheme.textMuted)),
                    const Divider(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading official question paper PDF...')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Question Paper (.PDF)'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Answer Script Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withOpacity(0.05),
                        border: Border.all(color: AppTheme.royalBlue.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.royalBlue),
                          SizedBox(height: 8),
                          Text('Select Handwritten Solution Photos or PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('Maximum file size: 25 MB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.academicGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Written paper submitted for teacher review and grading.')),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
                      },
                      child: const Text('Submit Written Exam for Evaluation', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
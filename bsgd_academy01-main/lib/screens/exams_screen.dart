import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'student_take_exam_screen.dart';

class ExamsScreen extends StatelessWidget {
  final bool embedded;

  const ExamsScreen({super.key, this.embedded = false});

  bool _matchesStudentProfile(Map<String, dynamic> examData, Map<String, dynamic>? studentData) {
    if (studentData == null) return false;

    final examClass = examData['class']?.toString().trim();
    final examGroup = examData['group']?.toString().trim();
    final examSubject = examData['subject']?.toString().trim();

    final studentClass = studentData['class']?.toString().trim();
    final studentGroup = studentData['group']?.toString().trim();
    final studentSubject = studentData['subject']?.toString().trim();

    if (examClass != null && examClass.isNotEmpty && examClass != 'General' && examClass != studentClass) {
      return false;
    }
    if (examGroup != null && examGroup.isNotEmpty && examGroup != 'General' && examGroup != studentGroup) {
      return false;
    }
    if (examSubject != null && examSubject.isNotEmpty && examSubject != 'General' && examSubject != studentSubject) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final body = StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : const Stream.empty(),
      builder: (context, userSnap) {
        final studentData = userSnap.data?.data() as Map<String, dynamic>?;
        final autoEnrollFree = studentData?['autoEnrollFree'] ?? true;

        return StreamBuilder<QuerySnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('saved_exams')
                  .snapshots()
              : const Stream.empty(),
          builder: (context, savedSnap) {
            final savedExamIds = (savedSnap.data?.docs ?? []).map((e) => e.id).toSet();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exams')
                  .where('published', isEqualTo: true)
                  .snapshots(),
              builder: (context, examSnap) {
                if (examSnap.hasError) {
                  return Center(child: Text('Error: ${examSnap.error}'));
                }
                if (examSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = examSnap.data?.docs ?? [];

                // Filter exams that are either explicitly saved OR auto-enrolled (free + match profile)
                final docs = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final isFree = d['isFree'] ?? true;
                  final isSaved = savedExamIds.contains(doc.id);
                  final matches = _matchesStudentProfile(d, studentData);

                  return isSaved || (autoEnrollFree && isFree && matches);
                }).toList();

                docs.sort((a, b) {
                  final ta = (a.data() as Map<String, dynamic>)['createdAt'];
                  final tb = (b.data() as Map<String, dynamic>)['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No exams in your dashboard yet.\nBrowse and add exams from the Public MCQ feed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final title = d['title']?.toString() ?? 'Exam';
                    final qCount = d['questionCount'] ?? 0;
                    final marks = d['fullMarks'] ?? '20';
                    final time = d['durationMinutes'] ?? 30;
                    final klass = d['class']?.toString() ?? '';
                    final subject = d['subject']?.toString() ?? '';
                    final isFree = d['isFree'] ?? true;
                    final price = d['price'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
                          child: const Icon(Icons.quiz, color: AppTheme.royalBlue),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isFree ? Colors.green : Colors.deepOrange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFree ? 'FREE' : '৳$price',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            [
                              if (klass.isNotEmpty) 'Class $klass',
                              if (subject.isNotEmpty) subject,
                              '$qCount Q',
                              '$marks marks',
                              '$time min',
                            ].join(' • '),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        trailing: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentTakeExamScreen(
                                  examId: doc.id,
                                  examTitle: title,
                                  durationMinutes: int.tryParse('$time') ?? 30,
                                ),
                              ),
                            );
                          },
                          child: const Text('Start'),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('My Exams')),
      body: body,
    );
  }
}
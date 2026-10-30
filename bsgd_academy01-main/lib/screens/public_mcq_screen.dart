import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/student_login_screen.dart';
import '../services/bkash_payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/bkash_payment_modal.dart';
import 'student_take_exam_screen.dart'; // Exam conducting screen

class PublicMcqScreen extends StatefulWidget {
  const PublicMcqScreen({super.key});

  @override
  State<PublicMcqScreen> createState() => _PublicMcqScreenState();
}

class _PublicMcqScreenState extends State<PublicMcqScreen> {
  bool _autoEnrollFree = true;

  @override
  void initState() {
    super.initState();
    _loadAutoEnrollPreference();
  }

  Future<void> _loadAutoEnrollPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('autoEnrollFree')) {
        setState(() {
          _autoEnrollFree = data['autoEnrollFree'] == true;
        });
      }
    }
  }

  Future<void> _toggleAutoEnroll(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _autoEnrollFree = value);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'autoEnrollFree': value,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto-enroll enabled: Matching free MCQ exams will automatically appear in your dashboard.'
                : 'Auto-enroll disabled.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _cols(double w) {
    if (w < 600) return 1;
    if (w < 900) return 2;
    if (w < 1200) return 3;
    return 4;
  }

  void _showLoginPrompt(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text('You must be logged in to take or save "$title".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  /// Adds exam to student's dashboard (exams_screen sync target)
  Future<void> _addToDashboard(String examId, String examTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt(examTitle);
      return;
    }

    // Saving to user's saved_exams / saved items or marking as enrolled
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_exams')
        .doc(examId)
        .set({
      'examId': examId,
      'title': examTitle,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$examTitle" added to your dashboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Handles payment verification if paid, then starts the exam directly
  Future<void> _takeExamNow(BuildContext context, String docId, Map<String, dynamic> d) async {
    final user = FirebaseAuth.instance.currentUser;
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;
    final title = d['title']?.toString() ?? 'MCQ Exam';
    final duration = d['durationMinutes'] ?? 30;

    if (user == null) {
      _showLoginPrompt(title);
      return;
    }

    // If paid item, check payment unlock status first
    if (!isFree && price > 0) {
      final unlocked = await BkashPaymentService.hasPurchasedItem(docId);
      if (!unlocked) {
        if (!context.mounted) return;
        final paid = await BkashPaymentModal.show(
          context,
          itemId: docId,
          itemType: 'exam',
          itemTitle: title,
          price: (price as num).toDouble(),
        );
        if (paid != true) return;
      }
    }

    if (!context.mounted) return;

    // Navigate directly to the exam-taking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentTakeExamScreen(
          examId: docId,
          examTitle: title,
          durationMinutes: int.tryParse('$duration') ?? 30,
        ),
      ),
    );
  }

  /// Interactive Modal offering choice: Take Now or Add to Dash
  void _showExamOptionsDialog(BuildContext context, String docId, Map<String, dynamic> d, bool isSaved) {
    final title = d['title']?.toString() ?? 'MCQ Exam';
    final questionCount = d['questionCount'] ?? 0;
    final marks = d['fullMarks'] ?? '20';
    final time = d['durationMinutes'] ?? 30;
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isFree ? Colors.green : Colors.deepOrange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFree ? 'FREE' : 'PRICE: ৳$price',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$questionCount Q • $marks marks • $time min',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Would you like to take this exam right now or save it to your dashboard for later?',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (!isSaved)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _addToDashboard(docId, title);
              },
              icon: const Icon(Icons.add_to_photos_outlined, size: 16),
              label: const Text('Add to Dash'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _takeExamNow(context, docId, d);
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Take Exam Now'),
          ),
        ],
      ),
    );
  }

  bool _matchesStudentProfile(Map<String, dynamic> examData, Map<String, dynamic>? studentData) {
    if (studentData == null) return false;

    final examClass = examData['class']?.toString().trim();
    final examGroup = examData['group']?.toString().trim();
    final examSubDept = examData['subDepartment']?.toString().trim();
    final examSubject = examData['subject']?.toString().trim();

    final studentClass = studentData['class']?.toString().trim();
    final studentGroup = studentData['group']?.toString().trim();
    final studentSubDept = studentData['subDepartment']?.toString().trim();
    final studentSubject = studentData['subject']?.toString().trim();

    if (examClass != null && examClass.isNotEmpty && examClass != 'General' && examClass != studentClass) {
      return false;
    }
    if (examGroup != null && examGroup.isNotEmpty && examGroup != 'General' && examGroup != studentGroup) {
      return false;
    }
    if (examSubDept != null && examSubDept.isNotEmpty && examSubDept != 'General' && examSubDept != studentSubDept) {
      return false;
    }
    if (examSubject != null && examSubject.isNotEmpty && examSubject != 'General' && examSubject != studentSubject) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
        builder: (context, userSnap) {
          final studentData = userSnap.data?.data() as Map<String, dynamic>?;

          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = _cols(constraints.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Public MCQ Exams',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Take exams right away or add them to your dashboard for later practice.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (user != null) ...[
                            Row(
                              children: [
                                const Text(
                                  'Auto Add Free',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: _autoEnrollFree,
                                  activeColor: Colors.green,
                                  onChanged: _toggleAutoEnroll,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Published Exams Feed Grid
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('exams')
                            .where('published', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final docs = List<DocumentSnapshot>.from(snap.data?.docs ?? []);

                          docs.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>?;
                            final bData = b.data() as Map<String, dynamic>?;
                            final aTime = aData?['createdAt'] as Timestamp?;
                            final bTime = bData?['createdAt'] as Timestamp?;
                            if (aTime == null || bTime == null) return 0;
                            return bTime.compareTo(aTime);
                          });

                          if (docs.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No published MCQ exams available yet.'),
                              ),
                            );
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: user != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('saved_exams')
                                    .snapshots()
                                : const Stream.empty(),
                            builder: (context, savedSnap) {
                              final savedIds = (savedSnap.data?.docs ?? [])
                                  .map((e) => e.id)
                                  .toSet();

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: cols == 1 ? 1.5 : 0.70,
                                ),
                                itemBuilder: (ctx, i) {
                                  final docId = docs[i].id;
                                  final d = docs[i].data() as Map<String, dynamic>;
                                  final isFree = d['isFree'] ?? true;
                                  final price = d['price'] ?? 0;
                                  final targetClass = d['class'];
                                  final title = d['title'] ?? 'Untitled Exam';
                                  final questionCount = d['questionCount'] ?? 0;

                                  final matchesProfile = _matchesStudentProfile(d, studentData);
                                  final isSaved = savedIds.contains(docId) ||
                                      (_autoEnrollFree && isFree && matchesProfile);

                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 1,
                                    child: InkWell(
                                      onTap: () => _showExamOptionsDialog(context, docId, d, isSaved),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Icon(
                                                  Icons.quiz_outlined,
                                                  size: 28,
                                                  color: Colors.orange,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (isFree
                                                            ? Colors.green
                                                            : Colors.deepOrange)
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isFree ? 'FREE' : '৳$price',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isFree
                                                          ? Colors.green.shade800
                                                          : Colors.deepOrange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (targetClass != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                '$targetClass • ${d['group'] ?? ''} • ${d['subject'] ?? 'General'}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.royalBlue,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.help_outline, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$questionCount Questions',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                                      side: BorderSide(color: isSaved ? Colors.grey.shade400 : AppTheme.royalBlue),
                                                    ),
                                                    onPressed: isSaved
                                                        ? null
                                                        : () => _addToDashboard(docId, title),
                                                    child: Text(
                                                      isSaved ? 'Saved' : 'Add to Dash',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSaved ? Colors.grey : AppTheme.royalBlue,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.royalBlue,
                                                      foregroundColor: Colors.white,
                                                      elevation: 1,
                                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                                    ),
                                                    onPressed: () => _takeExamNow(context, docId, d),
                                                    child: const Text(
                                                      'Take Exam',
                                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
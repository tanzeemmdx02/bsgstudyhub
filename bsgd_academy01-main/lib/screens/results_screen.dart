import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final bool embedded;

  const ResultsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    Widget body;
    if (uid == null) {
      body = const Center(child: Text('Please log in to see results.'));
    } else {
      body = StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exam_attempts')
            .where('studentId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);
          docs.sort((a, b) {
            final ta = (a.data() as Map)['createdAt'];
            final tb = (b.data() as Map)['createdAt'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return 0;
          });

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: AppTheme.royalBlue,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No results yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Finish a published MCQ exam to see your score here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Exam Results & Merit Standings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Instant automated scores from your MCQ attempts.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(docs.length, (i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final title = d['examTitle']?.toString() ?? 'Exam';
                    final score = (d['score'] is num)
                        ? (d['score'] as num).toInt()
                        : 0;
                    final total = (d['total'] is num)
                        ? (d['total'] as num).toInt()
                        : 0;
                    final pct =
                        total == 0 ? 0 : ((score * 100) / total).round();

                    String dateStr = '';
                    final ca = d['createdAt'];
                    if (ca is Timestamp) {
                      dateStr = DateFormat('dd MMM yyyy, hh:mm a')
                          .format(ca.toDate());
                    }

                    final isLast = i == docs.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                'Score: $score / $total',
                                if (dateStr.isNotEmpty) dateStr,
                              ].join('  •  '),
                              style: const TextStyle(
                                color: AppTheme.royalBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: pct >= 80
                                  ? Colors.green.withOpacity(0.12)
                                  : pct >= 50
                                      ? AppTheme.royalBlue.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: pct >= 80
                                    ? Colors.green.shade800
                                    : pct >= 50
                                        ? AppTheme.royalBlue
                                        : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        },
      );
    }

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Exam Results & Merit')),
      body: body,
    );
  }
}
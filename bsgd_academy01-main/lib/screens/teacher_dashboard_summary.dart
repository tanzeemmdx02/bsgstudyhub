import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'teacher_exams_screen.dart';

/// Summary cards / home content for the teacher dashboard.
class TeacherDashboardSummary extends StatelessWidget {
  const TeacherDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Teacher Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Overview of your exams and activity.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Stats
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('exams')
              .where('teacherId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final total = docs.length;
            var published = 0;
            var draft = 0;
            var questions = 0;
            for (final d in docs) {
              final m = d.data() as Map<String, dynamic>;
              if (m['published'] == true) {
                published++;
              } else {
                draft++;
              }
              questions += (m['questionCount'] as int?) ?? 0;
            }

            return LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 600;
                final cards = [
                  _StatCard(
                    label: 'Total exams',
                    value: '$total',
                    icon: Icons.quiz_outlined,
                    color: AppTheme.royalBlue,
                  ),
                  _StatCard(
                    label: 'Published',
                    value: '$published',
                    icon: Icons.cloud_done_outlined,
                    color: AppTheme.accentEmerald,
                  ),
                  _StatCard(
                    label: 'Drafts',
                    value: '$draft',
                    icon: Icons.edit_note,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Questions',
                    value: '$questions',
                    icon: Icons.help_outline,
                    color: AppTheme.academicGold,
                  ),
                ];

                if (wide) {
                  return Row(
                    children: cards
                        .map(
                          (w) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: w,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: cards,
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quick actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherExamsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.quiz, size: 18),
              label: const Text('Manage exams'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent exams
        const Text(
          'Your recent MCQ exams',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('exams')
              .where('type', isEqualTo: 'mcq')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Error: ${snap.error}');
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = List<QueryDocumentSnapshot>.from(
              snap.data?.docs ?? [],
            );
            // Prefer this teacher's exams if teacherId is set
            final mine = docs.where((d) {
              final m = d.data() as Map<String, dynamic>;
              final tid = m['teacherId']?.toString() ?? '';
              return tid.isEmpty || tid == uid;
            }).toList();

            mine.sort((a, b) {
              final ta = (a.data() as Map)['createdAt'];
              final tb = (b.data() as Map)['createdAt'];
              if (ta is Timestamp && tb is Timestamp) {
                return tb.compareTo(ta);
              }
              return 0;
            });

            final show = mine.take(8).toList();
            if (show.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No exams yet. Create one from Manage exams.'),
                ),
              );
            }

            return Column(
              children: show.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final published = d['published'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.quiz,
                      color: published
                          ? AppTheme.accentEmerald
                          : Colors.orange,
                    ),
                    title: Text(
                      d['title']?.toString() ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        if (d['studentClass'] != null)
                          'Class ${d['studentClass']}',
                        d['subject'] ?? '',
                        '${d['questionCount'] ?? 0} Q',
                        published ? 'Published' : 'Draft',
                      ].where((e) => e.toString().isNotEmpty).join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherExamsScreen(),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
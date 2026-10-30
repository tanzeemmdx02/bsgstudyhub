import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'public_suggestion_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_message_screen.dart';

class TeacherNotificationScreen extends StatelessWidget {
  const TeacherNotificationScreen({super.key});

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleRedirection(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final title = data['title']?.toString() ?? 'Notification Details';
    final body = data['body']?.toString() ?? '';
    final itemId = data['itemId']?.toString();
    final examId = data['examId']?.toString();

    if (type == 'note' || type.contains('note')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    if (type == 'mcq_exam' || type.contains('mcq') || type.contains('exam')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
                  if (examId != null) ...[
                    const SizedBox(height: 8),
                    Text('Exam ID: $examId', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;

    if (type.contains('course')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherCoursesScreen()),
      );
    } else if (type.contains('message')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherMessageScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PublicSuggestionScreen()),
      );
    }
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Teacher Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error loading notifications.\n${snap.error}'));
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);
          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications found.', style: TextStyle(color: AppTheme.textMuted)));
          }

          final hasUnread = docs.any((d) => (d.data() as Map<String, dynamic>)['isRead'] != true);

          return Column(
            children: [
              if (hasUnread)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Faculty Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.royalBlue)),
                      TextButton(onPressed: () => _markAllAsRead(docs), child: const Text('Mark all as read', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data() as Map<String, dynamic>;
                    
                    final title = d['title'] ?? 'New Notification';
                    final body = d['body'] ?? '';
                    final type = d['type']?.toString().toLowerCase() ?? '';
                    final isRead = d['isRead'] == true;
                    final createdAt = d['createdAt'] as Timestamp?;

                    IconData iconData = Icons.notifications_outlined;
                    Color iconColor = AppTheme.royalBlue;
                    if (type == 'mcq_exam' || type.contains('mcq') || type.contains('exam')) {
                      iconData = Icons.quiz_outlined;
                      iconColor = Colors.orange;
                    } else if (type.contains('course')) {
                      iconData = Icons.play_circle_fill;
                      iconColor = Colors.green;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : AppTheme.royalBlue.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRead ? Colors.grey.shade200 : AppTheme.royalBlue.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey.shade100 : iconColor.withOpacity(0.12),
                          child: Icon(iconData, color: isRead ? Colors.grey : iconColor, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14))),
                            Text(_formatTimeAgo(createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                        ),
                        trailing: !isRead
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
                            : null,
                        onTap: () async {
                          await FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({'isRead': true});
                          if (!context.mounted) return;
                          _handleRedirection(context, d);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
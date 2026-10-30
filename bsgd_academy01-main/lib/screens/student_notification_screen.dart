import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'public_suggestion_screen.dart';
import 'student_courses_screen.dart';
import 'student_message_screen.dart';

class StudentNotificationScreen extends StatelessWidget {
  const StudentNotificationScreen({super.key});

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
    final title = data['title']?.toString().toLowerCase() ?? '';
    final itemId = data['itemId']?.toString();

    if ((type.contains('suggestion') ||
            type.contains('note') ||
            title.contains('suggestion') ||
            title.contains('note')) &&
        itemId != null &&
        itemId.isNotEmpty) {
      final collectionName = type.contains('note') ? 'notes' : 'suggestions';
      final itemDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(itemId)
          .get();

      if (!context.mounted) return;

      if (itemDoc.exists && itemDoc.data() != null) {
        final itemData = itemDoc.data() as Map<String, dynamic>;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              itemData['title'] ?? 'Notification Details',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (itemData['class'] != null)
                      Chip(
                        label: Text('${itemData['class']}'),
                        backgroundColor: AppTheme.royalBlue.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppTheme.royalBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      itemData['body'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
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
                    MaterialPageRoute(
                      builder: (_) => const PublicSuggestionScreen(),
                    ),
                  );
                },
                child: const Text('View Feed'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;

    if (type.contains('course')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentCoursesScreen()),
      );
    } else if (type.contains('message')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentMessageScreen()),
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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Student Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: uid == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final classDocId = userData?['classDocId']?.toString();
                final Timestamp? studentCreatedAt = userData?['createdAt'] as Timestamp?;

                final List<String> targetFilters = [
                  'all_students',
                  'all',
                  uid,
                ];
                if (classDocId != null && classDocId.isNotEmpty) {
                  targetFilters.add(classDocId);
                }

                return StreamBuilder<QuerySnapshot>(
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

                    final allDocs = snap.data?.docs ?? [];
                    final filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final target = data['targetUserId']?.toString();
                      final Timestamp? notifCreatedAt = data['createdAt'] as Timestamp?;

                      // 1. Exclude notifications targeted specifically to teachers
                      if (target == 'all_teachers') return false;

                      // 2. Strict Target Filter: Must match student filters or general broadcast
                      bool matchesTarget = (target != null && targetFilters.contains(target)) ||
                                           (target == 'all_students' || target == 'all');

                      if (!matchesTarget) return false;

                      // 3. Timestamp Filter: Hide notifications created BEFORE the student registered
                      if (studentCreatedAt != null && notifCreatedAt != null) {
                        if (notifCreatedAt.toDate().isBefore(studentCreatedAt.toDate())) {
                          return false; 
                        }
                      }

                      return true;
                    }).toList();

                    filteredDocs.sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 12),
                            Text('No notifications yet.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    final hasUnread = filteredDocs.any((d) => (d.data() as Map<String, dynamic>)['isRead'] != true);

                    return Column(
                      children: [
                        if (hasUnread)
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Unread Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.royalBlue)),
                                TextButton(onPressed: () => _markAllAsRead(filteredDocs), child: const Text('Mark all as read', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final d = doc.data() as Map<String, dynamic>;
                              final title = d['title'] ?? 'Notice';
                              final body = d['body'] ?? '';
                              final type = d['type']?.toString().toLowerCase() ?? '';
                              final isRead = d['isRead'] == true;
                              final createdAt = d['createdAt'] as Timestamp?;

                              IconData iconData = Icons.notifications_outlined;
                              Color iconColor = AppTheme.royalBlue;
                              if (type.contains('course')) {
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
                );
              },
            ),
    );
  }
}
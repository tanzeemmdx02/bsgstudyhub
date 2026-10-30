import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StudentPage { summary, exams, notifications }

class StudentRightBar extends StatelessWidget {
  final StudentPage selected;
  final ValueChanged<StudentPage> onSelect;
  final VoidCallback onVisitSite;
  final Future<void> Function() onLogout;
  final VoidCallback onOpenResults;
  final VoidCallback onOpenCourses;
  final VoidCallback onOpenSuggestions;
  final VoidCallback onOpenExamsScreen;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenSettings;

  const StudentRightBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onVisitSite,
    required this.onLogout,
    required this.onOpenResults,
    required this.onOpenCourses,
    required this.onOpenSuggestions,
    required this.onOpenExamsScreen,
    required this.onOpenMessages,
    required this.onOpenPayments,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String displayName = user?.displayName ?? 'Student';
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['name'] != null && (data['name'] as String).isNotEmpty) {
            displayName = data['name'];
          }
        }

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryNavy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _item(
                      Icons.dashboard_outlined,
                      'Summary',
                      selected == StudentPage.summary,
                      () => onSelect(StudentPage.summary),
                    ),
                    _item(
                      Icons.quiz_outlined,
                      'Exam & Result',
                      selected == StudentPage.exams,
                      () => onSelect(StudentPage.exams),
                    ),
                    _item(
                      Icons.emoji_events_outlined,
                      'Results',
                      false,
                      onOpenResults,
                    ),
                    _item(
                      Icons.notifications_outlined,
                      'Notification',
                      selected == StudentPage.notifications,
                      () => onSelect(StudentPage.notifications),
                    ),
                    _item(
                      Icons.payment_outlined,
                      'Payments',
                      false,
                      onOpenPayments,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: user != null
                          ? FirebaseFirestore.instance
                              .collection('chats')
                              .where('participants', arrayContains: user.uid)
                              .snapshots()
                          : const Stream.empty(),
                      builder: (context, chatSnap) {
                        final chats = chatSnap.data?.docs ?? [];
                        if (chats.isEmpty) {
                          return _messageListItem(0);
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collectionGroup('messages')
                              .where('senderId', isNotEqualTo: user?.uid)
                              .snapshots(),
                          builder: (context, msgSnap) {
                            int totalUnread = 0;
                            if (msgSnap.hasData && user != null) {
                              final chatIds = chats.map((c) => c.id).toSet();
                              for (final doc in msgSnap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final pathSegments = doc.reference.path.split('/');
                                if (pathSegments.length >= 2 && chatIds.contains(pathSegments[1])) {
                                  if (data['status'] != 'read') {
                                    totalUnread++;
                                  }
                                }
                              }
                            }

                            return _messageListItem(totalUnread);
                          },
                        );
                      },
                    ),
                    _item(
                      Icons.menu_book_outlined,
                      'Courses',
                      false,
                      onOpenCourses,
                    ),
                    _item(
                      Icons.lightbulb_outline,
                      'Suggestions',
                      false,
                      onOpenSuggestions,
                    ),
                    _item(
                      Icons.settings_outlined,
                      'Settings',
                      false,
                      onOpenSettings,
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.public, size: 20),
                      title: const Text(
                        'Visit Site',
                        style: TextStyle(fontSize: 13.5),
                      ),
                      onTap: onVisitSite,
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.logout,
                        size: 20,
                        color: AppTheme.accentRose,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.accentRose,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messageListItem(int badgeCount) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.chat_bubble_outline, size: 20),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Message',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onOpenMessages,
    );
  }

  Widget _item(IconData icon, String label, bool active, VoidCallback onTap) {
    return ListTile(
      dense: true,
      selected: active,
      selectedTileColor: AppTheme.royalBlue.withOpacity(0.1),
      leading: Icon(icon, size: 20, color: active ? AppTheme.royalBlue : null),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          color: active ? AppTheme.royalBlue : null,
        ),
      ),
      onTap: onTap,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/student_right_bar.dart';
import 'exams_screen.dart';
import 'home_screen.dart';
import 'notes_screen.dart';
import 'results_screen.dart';
import 'student_course_screen.dart';
import 'student_message_screen.dart';
import 'student_payment_screen.dart';
import 'student_setting_screen.dart';
import 'student_suggestion_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StudentPage _page = StudentPage.summary;
  bool _rightOpen = true;

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _openFullPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _handleSelect(StudentPage page, {required bool closeDrawer}) {
    setState(() => _page = page);
    if (closeDrawer) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      endDrawer: isWide
          ? null
          : Drawer(
              child: StudentRightBar(
                selected: _page,
                onSelect: (p) => _handleSelect(p, closeDrawer: true),
                onVisitSite: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                onLogout: () async {
                  Navigator.pop(context);
                  await _logout();
                },
                onOpenResults: () {
                  Navigator.pop(context);
                  _openFullPage(const ResultsScreen());
                },
                onOpenCourses: () {
                  Navigator.pop(context);
                  _openFullPage(const StudentCourseScreen());
                },
                onOpenSuggestions: () {
                  Navigator.pop(context);
                  _openFullPage(const StudentSuggestionScreen());
                },
                onOpenExamsScreen: () {
                  Navigator.pop(context);
                  _openFullPage(const ExamsScreen());
                },
                onOpenMessages: () {
                  Navigator.pop(context);
                  _openFullPage(const StudentMessageScreen());
                },
                onOpenPayments: () {
                  Navigator.pop(context);
                  _openFullPage(const StudentPaymentScreen());
                },
                onOpenSettings: () {
                  Navigator.pop(context);
                  _openFullPage(const StudentSettingScreen());
                },
              ),
            ),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: Row(
        children: [
          Expanded(child: _buildPage()),
          if (isWide && _rightOpen)
            SizedBox(
              width: 240,
              child: Material(
                elevation: 2,
                child: StudentRightBar(
                  selected: _page,
                  onSelect: (p) => _handleSelect(p, closeDrawer: false),
                  onVisitSite: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  onLogout: _logout,
                  onOpenResults: () => _openFullPage(const ResultsScreen()),
                  onOpenCourses: () => _openFullPage(const StudentCourseScreen()),
                  onOpenSuggestions: () =>
                      _openFullPage(const StudentSuggestionScreen()),
                  onOpenExamsScreen: () => _openFullPage(const ExamsScreen()),
                  onOpenMessages: () => _openFullPage(const StudentMessageScreen()),
                  onOpenPayments: () => _openFullPage(const StudentPaymentScreen()),
                  onOpenSettings: () => _openFullPage(const StudentSettingScreen()),
                ),
              ),
            ),
          if (isWide)
            InkWell(
              onTap: () => setState(() => _rightOpen = !_rightOpen),
              child: Container(
                width: 18,
                color: AppTheme.royalBlue.withOpacity(0.08),
                child: Center(
                  child: Icon(
                    _rightOpen ? Icons.chevron_right : Icons.chevron_left,
                    size: 16,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.small(
              backgroundColor: AppTheme.royalBlue,
              tooltip: 'Student menu',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: const Icon(Icons.menu_open, color: Colors.white),
            ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case StudentPage.summary:
        return const _SummaryPage();
      case StudentPage.exams:
        return _ExamsResultsPage(
          onOpenExams: () => _openFullPage(const ExamsScreen()),
          onOpenResults: () => _openFullPage(const ResultsScreen()),
        );
      case StudentPage.notifications:
        return const _NotificationsPage();
    }
  }
}

class _SummaryPage extends StatelessWidget {
  const _SummaryPage();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final name = auth.currentUserName.isNotEmpty
        ? auth.currentUserName
        : 'Student';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, $name',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your learning overview',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: const [
                _KpiCard(
                  icon: Icons.menu_book,
                  label: 'Courses',
                  value: '—',
                  color: AppTheme.royalBlue,
                ),
                _KpiCard(
                  icon: Icons.quiz,
                  label: 'Exams',
                  value: '—',
                  color: AppTheme.academicGold,
                ),
                _KpiCard(
                  icon: Icons.notifications,
                  label: 'Notices',
                  value: '—',
                  color: AppTheme.accentEmerald,
                ),
                _KpiCard(
                  icon: Icons.chat,
                  label: 'Messages',
                  value: '—',
                  color: AppTheme.accentRose,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Latest notices',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notes')
              .orderBy('createdAt', descending: true)
              .limit(6)
              .snapshots(),
          builder: (context, snap) {
            final docs = (snap.data?.docs ?? []).where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return d['archived'] != true;
            }).toList();
            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No notices yet.'),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.campaign_outlined,
                      color: AppTheme.royalBlue,
                    ),
                    title: Text(
                      d['title'] ?? 'Notice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      d['body'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NoticeScreen()),
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamsResultsPage extends StatelessWidget {
  final VoidCallback onOpenExams;
  final VoidCallback onOpenResults;

  const _ExamsResultsPage({
    required this.onOpenExams,
    required this.onOpenResults,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Exam & Result',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Open exams or view published results.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: onOpenExams,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          color: AppTheme.royalBlue,
                          size: 28,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Exams',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'MCQ & written tests',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: onOpenResults,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: AppTheme.academicGold,
                          size: 28,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Results',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Published scores',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  void _handleRedirection(BuildContext context, Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final title = data['title']?.toString().toLowerCase() ?? '';

    // If notification type or title matches suggestion, open StudentSuggestionScreen
    if (type.contains('suggestion') || title.contains('suggestion') || title.contains('uploaded')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentSuggestionScreen()),
      );
    } else if (type.contains('course')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentCourseScreen()),
      );
    } else if (type.contains('message')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentMessageScreen()),
      );
    } else if (type.contains('payment')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentPaymentScreen()),
      );
    } else {
      // Default fallback
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentSuggestionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Notices and updates from teachers.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('targetUserId', whereIn: [user?.uid, 'all_students', 'all'])
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No notifications yet.'),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final title = d['title'] ?? 'Notice';
                final body = d['body'] ?? '';
                final isRead = d['isRead'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isRead ? Colors.white : AppTheme.royalBlue.withOpacity(0.04),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.royalBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(doc.id)
                          .update({'isRead': true});

                      if (!context.mounted) return;
                      _handleRedirection(context, d);
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
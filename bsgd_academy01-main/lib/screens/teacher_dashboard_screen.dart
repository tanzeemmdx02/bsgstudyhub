import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'admission_screen.dart';
import 'contact_screen.dart';
import 'courses_screen.dart';
import 'home_screen.dart';
import 'live_class_screen.dart';
import 'teacher_attendance_page.dart';
import 'teacher_contact_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_dashboard_summary.dart';
import 'teacher_exams_screen.dart';
import 'teacher_live_class_screen.dart';
import 'teacher_message_screen.dart';
import 'teacher_notes_screen.dart';
import 'teacher_payment_screen.dart';
import 'teacher_setting_screen.dart';
import 'teacher_students_screen.dart';
import 'teacher_suggestion_screen.dart';
import 'teacher_notification_screen.dart' as notification_screen;

enum TeacherMenu {
  dashboard,
  notes,
  suggestion,
  message,
  students,
  attendance,
  courses,
  liveClass,
  exams,
  settings,
  contactSetting,
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  TeacherMenu _selected = TeacherMenu.dashboard;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _viewSite() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _selectMenu(TeacherMenu menu) {
    setState(() => _selected = menu);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildContent() {
    switch (_selected) {
      case TeacherMenu.dashboard:
        return const TeacherDashboardSummary();
      case TeacherMenu.notes:
        return const TeacherNotesScreen();
      case TeacherMenu.suggestion:
        return const TeacherSuggestionScreen();
      case TeacherMenu.message:
        return const TeacherMessageScreen();
      case TeacherMenu.students:
        return const TeacherStudentsScreen();
      case TeacherMenu.attendance:
        return const TeacherAttendancePage();
      case TeacherMenu.courses:
        return const TeacherCoursesScreen();
      case TeacherMenu.exams:
        return const TeacherExamsScreen();
      case TeacherMenu.liveClass:
        return const TeacherLiveClassScreen();
      case TeacherMenu.settings:
        return const TeacherSettingScreen();
      case TeacherMenu.contactSetting:
        return const TeacherContactScreen();
    }
  }

  String _menuTitle(TeacherMenu m) {
    switch (m) {
      case TeacherMenu.dashboard:
        return 'Dashboard';
      case TeacherMenu.notes:
        return 'Notes';
      case TeacherMenu.suggestion:
        return 'Suggestions';
      case TeacherMenu.message:
        return 'Messages';
      case TeacherMenu.students:
        return 'Students';
      case TeacherMenu.attendance:
        return 'Attendance';
      case TeacherMenu.courses:
        return 'Courses';
      case TeacherMenu.liveClass:
        return 'Live Class';
      case TeacherMenu.exams:
        return 'Exams';
      case TeacherMenu.settings:
        return 'Settings';
      case TeacherMenu.contactSetting:
        return 'Contact Setting';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String displayName = user?.displayName ?? 'Teacher';
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['name'] != null && (data['name'] as String).isNotEmpty) {
            displayName = data['name'];
          }
        }

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 260, child: _leftPanel(showClose: false)),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(displayName),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
                SizedBox(width: 240, child: _rightPanel(showClose: false)),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(child: _leftPanel(showClose: true)),
          endDrawer: Drawer(
            backgroundColor: AppTheme.primaryNavy,
            child: _rightPanel(showClose: true),
          ),
          appBar: AppBar(
            backgroundColor: Theme.of(context).cardColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0.5,
            title: Text(
              _menuTitle(_selected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.royalBlue,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Teacher Tools',
                icon: const Icon(Icons.view_sidebar_outlined),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          body: _buildContent(),
        );
      },
    );
  }

  Widget _topBar(String name) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              _menuTitle(_selected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.royalBlue,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftPanel({required bool showClose}) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(
                  bottom: BorderSide(color: AppTheme.academicGold, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BSGD Academy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Coaching Management Suite',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _section('PUBLIC NAVIGATION'),
                  _navItem(Icons.home_outlined, 'Home', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }),
                  _navItem(Icons.menu_book_outlined, 'Courses & Batches', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursesScreen()),
                    );
                  }),
                  _navItem(Icons.videocam_outlined, 'Live Classroom', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveClassScreen(),
                      ),
                    );
                  }),
                  _navItem(Icons.mail_outline, 'Contact & Support', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactScreen()),
                    );
                  }),
                  _navItem(Icons.how_to_reg_outlined, 'Online Admission', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdmissionScreen(),
                      ),
                    );
                  }, highlight: true),
                  const Divider(height: 20),
                  _section('TEACHER TOOLS'),
                  _navItem(Icons.dashboard_outlined, 'Dashboard', () {
                    _selectMenu(TeacherMenu.dashboard);
                  }),
                  _navItem(Icons.fact_check_outlined, 'Attendance', () {
                    _selectMenu(TeacherMenu.attendance);
                  }),
                  _navItem(Icons.groups_outlined, 'Students', () {
                    _selectMenu(TeacherMenu.students);
                  }),
                  _navItem(Icons.quiz_outlined, 'Exams', () {
                    _selectMenu(TeacherMenu.exams);
                  }),
                  _navItem(Icons.contacts_outlined, 'Contact Setting', () {
                    _selectMenu(TeacherMenu.contactSetting);
                  }),
                  _navItem(Icons.settings_outlined, 'Settings', () {
                    _selectMenu(TeacherMenu.settings);
                  }),
                  const Divider(height: 20),
                  _navItem(
                    Icons.language,
                    'View Site',
                    _viewSite,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightPanel({required bool showClose}) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Material(
      color: AppTheme.primaryNavy,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.academicGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Teacher Tools',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _toolItem(
                    Icons.dashboard_outlined,
                    'Dashboard',
                    onTap: () => _selectMenu(TeacherMenu.dashboard),
                    selected: _selected == TeacherMenu.dashboard,
                  ),
                  _toolItem(
                    Icons.notifications_outlined,
                    'Notification',
                    onTap: () {
                      if (showClose) Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => notification_screen.TeacherNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _toolItem(
                    Icons.payment_outlined,
                    'Payments',
                    onTap: () {
                      if (showClose) Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherPaymentScreen()),
                      );
                    },
                  ),
                  _toolItem(
                    Icons.note_alt_outlined,
                    'Notes',
                    onTap: () => _selectMenu(TeacherMenu.notes),
                    selected: _selected == TeacherMenu.notes,
                  ),
                  _toolItem(
                    Icons.lightbulb_outline,
                    'Suggestion',
                    onTap: () => _selectMenu(TeacherMenu.suggestion),
                    selected: _selected == TeacherMenu.suggestion,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: teacherId)
                        .snapshots(),
                    builder: (context, chatSnap) {
                      final chats = chatSnap.data?.docs ?? [];
                      if (chats.isEmpty) {
                        return _toolItem(
                          Icons.chat_outlined,
                          'Message',
                          onTap: () => _selectMenu(TeacherMenu.message),
                          selected: _selected == TeacherMenu.message,
                        );
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('messages')
                            .where('senderId', isNotEqualTo: teacherId)
                            .snapshots(),
                        builder: (context, msgSnap) {
                          int totalUnread = 0;
                          if (msgSnap.hasData) {
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

                          return _toolItem(
                            Icons.chat_outlined,
                            'Message',
                            onTap: () => _selectMenu(TeacherMenu.message),
                            selected: _selected == TeacherMenu.message,
                            badgeCount: totalUnread,
                          );
                        },
                      );
                    },
                  ),
                  _toolItem(
                    Icons.groups_outlined,
                    'Students',
                    onTap: () => _selectMenu(TeacherMenu.students),
                    selected: _selected == TeacherMenu.students,
                  ),
                  _toolItem(
                    Icons.fact_check_outlined,
                    'Attendance',
                    onTap: () => _selectMenu(TeacherMenu.attendance),
                    selected: _selected == TeacherMenu.attendance,
                  ),
                  _toolItem(
                    Icons.play_circle_outline,
                    'Courses',
                    onTap: () => _selectMenu(TeacherMenu.courses),
                    selected: _selected == TeacherMenu.courses,
                  ),
                  _toolItem(
                    Icons.quiz_outlined,
                    'Exams',
                    onTap: () => _selectMenu(TeacherMenu.exams),
                    selected: _selected == TeacherMenu.exams,
                  ),
                  _toolItem(
                    Icons.live_tv_outlined,
                    'Live Class',
                    onTap: () => _selectMenu(TeacherMenu.liveClass),
                    selected: _selected == TeacherMenu.liveClass,
                  ),
                  _toolItem(
                    Icons.contacts_outlined,
                    'Contact Setting',
                    onTap: () => _selectMenu(TeacherMenu.contactSetting),
                    selected: _selected == TeacherMenu.contactSetting,
                  ),
                  _toolItem(
                    Icons.settings_outlined,
                    'Settings',
                    onTap: () => _selectMenu(TeacherMenu.settings),
                    selected: _selected == TeacherMenu.settings,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.public,
                color: Colors.white70,
                size: 18,
              ),
              title: const Text(
                'View Site',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              onTap: _viewSite,
            ),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.logout,
                color: AppTheme.accentRose,
                size: 18,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.accentRose,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool highlight = false,
    bool locked = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18,
        color: highlight ? AppTheme.academicGold : null,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          color: highlight ? AppTheme.academicGold : null,
        ),
      ),
      trailing: locked
          ? const Icon(Icons.lock, size: 13, color: AppTheme.textMuted)
          : null,
      onTap: onTap,
    );
  }

  Widget _toolItem(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool selected = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
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
      ),
    );
  }
}
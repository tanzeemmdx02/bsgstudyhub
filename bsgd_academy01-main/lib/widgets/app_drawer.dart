import 'package:flutter/material.dart';

import '../screens/admission_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_class_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/public_mcq_screen.dart';
import '../screens/public_suggestion_screen.dart';
import '../screens/results_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student_login_screen.dart';
import '../screens/student_setting_screen.dart';
import '../screens/teacher_attendance_page.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/teacher_exams_screen.dart';
import '../screens/teacher_login_screen.dart';
import '../screens/teacher_students_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _openSecured(BuildContext context, UserRole role, Widget destination) {
    Navigator.pop(context);
    final auth = AuthService();

    if (role == UserRole.student) {
      if (auth.isStudentLoggedIn || auth.isTeacherLoggedIn) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in with your student account to continue.'),
            backgroundColor: AppTheme.royalBlue,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentLoginScreen(targetScreen: destination),
          ),
        );
      }
    } else if (role == UserRole.teacher) {
      if (auth.isTeacherLoggedIn) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherLoginScreen(targetScreen: destination),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
                border: Border(
                  bottom: BorderSide(color: AppTheme.academicGold, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Coaching Management Suite',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('Public Navigation'),
                  _buildItem(
                    context,
                    Icons.home_outlined,
                    'Home',
                    const HomeScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.menu_book_outlined,
                    'Courses & Batches',
                    const CoursesScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.videocam_outlined,
                    'Live Classroom',
                    const LiveClassScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.mail_outline,
                    'Contact & Support',
                    const ContactScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.how_to_reg_outlined,
                    'Online Admission',
                    const AdmissionScreen(),
                    highlight: true,
                  ),
                  _buildItem(
                    context,
                    Icons.campaign_outlined,
                    'Notices & Notes',
                    const NoticeScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.lightbulb_outline,
                    'Teacher Suggestions',
                    PublicSuggestionScreen(),
                  ),
                  _buildItem(
                    context,
                    Icons.quiz_outlined,
                    'MCQ Exam',
                    PublicMcqScreen(),
                  ),
                  const Divider(height: 24),
                  _buildSectionHeader('Student Portals'),
                  _buildProtectedItem(
                    context,
                    Icons.lock_outline,
                    'Student LMS Portal',
                    () {
                      _openSecured(
                        context,
                        UserRole.student,
                        StudentDashboardScreen(),
                      );
                    },
                  ),
                  _buildProtectedItem(
                    context,
                    Icons.quiz_outlined,
                    'Model Test Exam Center',
                    () {
                      _openSecured(
                        context,
                        UserRole.student,
                        PublicMcqScreen(),
                      );
                    },
                  ),
                  _buildItem(
                    context,
                    Icons.emoji_events_outlined,
                    'Results & Merit Board',
                    const ResultsScreen(),
                  ),
                  _buildProtectedItem(
                    context,
                    Icons.settings_outlined,
                    'Account Settings',
                    () {
                      _openSecured(
                        context,
                        UserRole.student,
                        const StudentSettingScreen(),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildSectionHeader('Faculty & Staff Only'),
                  _buildProtectedItem(
                    context,
                    Icons.security,
                    'Teacher Command Hub',
                    () {
                      _openSecured(
                        context,
                        UserRole.teacher,
                        TeacherDashboardScreen(),
                      );
                    },
                  ),
                  _buildProtectedItem(
                    context,
                    Icons.fact_check_outlined,
                    'Daily Attendance Register',
                    () {
                      _openSecured(
                        context,
                        UserRole.teacher,
                        const TeacherAttendancePage(),
                      );
                    },
                  ),
                  _buildProtectedItem(
                    context,
                    Icons.groups_outlined,
                    'Student Roster',
                    () {
                      _openSecured(
                        context,
                        UserRole.teacher,
                        const TeacherStudentsScreen(),
                      );
                    },
                  ),
                  _buildProtectedItem(
                    context,
                    Icons.grading_outlined,
                    'Exam & Grade Evaluator',
                    () {
                      _openSecured(
                        context,
                        UserRole.teacher,
                        const TeacherExamsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen, {
    bool highlight = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: highlight ? AppTheme.academicGold : null,
        size: 20,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          color: highlight ? AppTheme.academicGold : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  Widget _buildProtectedItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppTheme.royalBlue, size: 20),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.lock, size: 14, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
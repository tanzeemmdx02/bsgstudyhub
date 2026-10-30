import 'package:flutter/material.dart';

import '../screens/admission_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_class_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/public_suggestion_screen.dart';
import '../screens/public_mcq_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student_login_screen.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/teacher_login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const AppNavBar({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _navigateToStudent(BuildContext context) {
    final auth = AuthService();
    if (auth.isStudentLoggedIn) {
      _go(context, const StudentDashboardScreen());
    } else {
      _go(context, const StudentLoginScreen());
    }
  }

void _navigateToTeacher(BuildContext context) {
    final auth = AuthService();
    if (auth.isTeacherLoggedIn) {
      _go(context, TeacherDashboardScreen()); // Fixed the dot typo here
    } else {
      _go(context, const TeacherLoginScreen());
    }
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final auth = AuthService();

    return AppBar(
      elevation: 0.5,
      centerTitle: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'BSGD Online Academy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isDesktop) ...[
          _link(context, 'Home', const HomeScreen()),
          _link(context, 'Courses', const CoursesScreen()),
          _link(context, 'Notices', const NoticeScreen()),
          _link(context, 'Suggestions', PublicSuggestionScreen()),
          _link(context, 'Live Class', const LiveClassScreen()),
          _link(context, 'Contact', const ContactScreen()),
          _link(context, 'MCQ Exam', const PublicMcqScreen()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => _go(context, const AdmissionScreen()),
              child: const Text(
                'Admission',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ],

        if (!isDesktop)
          PopupMenuButton<String>(
            tooltip: 'Pages',
            icon: const Icon(Icons.apps_outlined),
            onSelected: (v) {
              switch (v) {
                case 'home':
                  _go(context, const HomeScreen());
                  break;
                case 'courses':
                  _go(context, const CoursesScreen());
                  break;
                case 'notices':
                  _go(context, const NoticeScreen());
                  break;
                case 'suggestions':
                  _go(context, PublicSuggestionScreen());
                  break;
                case 'live':
                  _go(context, const LiveClassScreen());
                  break;
                case 'contact':
                  _go(context, const ContactScreen());
                  break;
                case 'admission':
                  _go(context, const AdmissionScreen());
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'home', child: Text('Home')),
              PopupMenuItem(value: 'courses', child: Text('Courses')),
              PopupMenuItem(value: 'notices', child: Text('Notices')),
              PopupMenuItem(value: 'suggestions', child: Text('Suggestions')),
              PopupMenuItem(value: 'live', child: Text('Live Class')),
              PopupMenuItem(value: 'contact', child: Text('Contact')),
              PopupMenuItem(value: 'admission', child: Text('Admission')),
            ],
          ),

        IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_outlined),
          onPressed: onToggleTheme,
        ),

        PopupMenuButton<String>(
          tooltip: 'Account',
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.royalBlue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              (auth.isStudentLoggedIn || auth.isTeacherLoggedIn)
                  ? Icons.verified_user
                  : Icons.lock_outline,
              color: AppTheme.royalBlue,
              size: 18,
            ),
          ),
          onSelected: (value) async {
            final authService = AuthService();

            if (value == 'student') {
              _navigateToStudent(context);
            } else if (value == 'teacher') {
              _navigateToTeacher(context);
            } else if (value == 'logout_student') {
              await authService.signOut();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out of Student Portal.')),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            } else if (value == 'logout_teacher') {
              await authService.signOut();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out of Teacher Dashboard.'),
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'student',
              child: Text(
                auth.isStudentLoggedIn
                    ? 'Student Portal (Logged In)'
                    : 'Student Portal',
              ),
            ),
            if (auth.isStudentLoggedIn)
              const PopupMenuItem(
                value: 'logout_student',
                child: Text(
                  'Logout Student',
                  style: TextStyle(color: AppTheme.accentRose),
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'teacher',
              child: Text(
                auth.isTeacherLoggedIn ? 'Teacher Hub (Logged In)' : 'Teacher Hub',
              ),
            ),
            if (auth.isTeacherLoggedIn)
              const PopupMenuItem(
                value: 'logout_teacher',
                child: Text(
                  'Logout Teacher',
                  style: TextStyle(color: AppTheme.accentRose),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _link(BuildContext context, String title, Widget screen) {
    return TextButton(
      onPressed: () => _go(context, screen),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }
}
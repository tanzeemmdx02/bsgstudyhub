import os
import zipfile

BASE_DIR = "bsgd_academy_flutter"
DIRS = [
    "lib/models",
    "lib/theme",
    "lib/widgets",
    "lib/screens",
]

for d in DIRS:
    os.makedirs(os.path.join(BASE_DIR, d), exist_ok=True)

# -------------------------------------------------------------------------
# 1. PUBSPEC.YAML
# -------------------------------------------------------------------------

PUBSPEC_YAML = """name: bsgd_online_academy
description: "A premier Coaching Management System and Online Academy mobile and web application."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
"""

# -------------------------------------------------------------------------
# 2. THEME & DESIGN SYSTEM (lib/theme/app_theme.dart)
# -------------------------------------------------------------------------

APP_THEME_DART = """import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color navySurface = Color(0xFF112240);
  static const Color royalBlue = Color(0xFF1E40AF);
  static const Color royalBlueHover = Color(0xFF1D4ED8);
  static const Color academicGold = Color(0xFFD4AF37);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFEF4444);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Light Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Dark Palette
  static const Color bgDark = Color(0xFF070F1E);
  static const Color surfaceDark = Color(0xFF0D1B33);
  static const Color borderDark = Color(0xFF1E2E4A);
  static const Color textLight = Color(0xFFF1F5F9);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: royalBlue,
      secondary: academicGold,
      surface: surfaceLight,
      background: bgLight,
      error: accentRose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceLight,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryNavy),
      titleTextStyle: TextStyle(
        color: primaryNavy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderLight),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: royalBlueHover,
      secondary: academicGold,
      surface: surfaceDark,
      background: bgDark,
      error: accentRose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderDark),
      ),
    ),
  );
}
"""

# -------------------------------------------------------------------------
# 3. DATA MODELS (lib/models/models.dart)
# -------------------------------------------------------------------------

MODELS_DART = """class Student {
  final String roll;
  final String name;
  final String studentClass;
  final String group;
  final String shift;
  final String phone;
  final String status;
  final double attendance;
  String currentStatus; // 'P', 'A', 'L'

  Student({
    required this.roll,
    required this.name,
    required this.studentClass,
    required this.group,
    required this.shift,
    required this.phone,
    required this.status,
    required this.attendance,
    this.currentStatus = 'P',
  });
}

class ExamQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  ExamQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class ExamResult {
  final String title;
  final String date;
  final double score;
  final double totalMarks;
  final int correct;
  final int wrong;
  final String rank;

  ExamResult({
    required this.title,
    required this.date,
    required this.score,
    required this.totalMarks,
    required this.correct,
    required this.wrong,
    required this.rank,
  });
}
"""

# -------------------------------------------------------------------------
# 4. COLLAPSIBLE SIDEBAR / DRAWER (lib/widgets/app_drawer.dart)
# -------------------------------------------------------------------------

APP_DRAWER_DART = """import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/live_class_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/admission_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/exams_screen.dart';
import '../screens/results_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/teacher_attendance_screen.dart';
import '../screens/teacher_students_screen.dart';
import '../screens/teacher_exams_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
                border: Border(bottom: BorderSide(color: AppTheme.academicGold, width: 2)),
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
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BSGD Academy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Coaching Management Suite',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Menu Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('Core Navigation'),
                  _buildDrawerItem(context, Icons.home_outlined, 'Home', const HomeScreen()),
                  _buildDrawerItem(context, Icons.menu_book_outlined, 'Courses & Batches', const CoursesScreen()),
                  _buildDrawerItem(context, Icons.videocam_outlined, 'Live Classroom', const LiveClassScreen()),
                  _buildDrawerItem(context, Icons.mail_outline, 'Contact & Support', const ContactScreen()),
                  _buildDrawerItem(context, Icons.person_add_alt_1_outlined, 'Online Admission', const AdmissionScreen(), highlight: true),

                  const Divider(height: 24),
                  _buildSectionHeader('Student Learning Portals'),
                  _buildDrawerItem(context, Icons.dashboard_outlined, 'Student LMS Portal', const StudentDashboardScreen()),
                  _buildDrawerItem(context, Icons.assignment_turned_in_outlined, 'Model Test Exam Center', const ExamsScreen()),
                  _buildDrawerItem(context, Icons.emoji_events_outlined, 'Results & Merit Board', const ResultsScreen()),
                  _buildDrawerItem(context, Icons.picture_as_pdf_outlined, 'PDF Lecture Notes', const NotesScreen()),

                  const Divider(height: 24),
                  _buildSectionHeader('Teacher & Admin Controls'),
                  _buildDrawerItem(context, Icons.admin_panel_settings_outlined, 'Teacher Command Hub', const TeacherDashboardScreen()),
                  _buildDrawerItem(context, Icons.fact_check_outlined, 'Daily Attendance Register', const TeacherAttendanceScreen()),
                  _buildDrawerItem(context, Icons.groups_outlined, 'Student Roster (Class/Shift)', const TeacherStudentsScreen()),
                  _buildDrawerItem(context, Icons.grade_outlined, 'Exam & Grade Evaluator', const TeacherExamsScreen()),
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

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen, {
    bool highlight = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: highlight ? AppTheme.academicGold : null, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          color: highlight ? AppTheme.academicGold : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close Drawer
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
"""

# -------------------------------------------------------------------------
# 5. TOP NAVBAR (lib/widgets/app_nav_bar.dart)
# -------------------------------------------------------------------------

APP_NAV_BAR_DART = """import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/live_class_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/admission_screen.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const AppNavBar({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Open Navigation Drawer',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: InkWell(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'BSGD Online Academy',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        if (isDesktop) ...[
          _buildNavAction(context, 'Home', const HomeScreen()),
          _buildNavAction(context, 'Courses', const CoursesScreen()),
          _buildNavAction(context, 'Live Class', const LiveClassScreen()),
          _buildNavAction(context, 'Contact', const ContactScreen()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdmissionScreen()),
              ),
              child: const Text('Admission', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
          ),
        ],
        // Theme Toggle Button
        IconButton(
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_outlined),
          onPressed: onToggleTheme,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNavAction(BuildContext context, String title, Widget screen) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: null,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
"""

# -------------------------------------------------------------------------
# 6. ALL APP SCREENS (lib/screens/...)
# -------------------------------------------------------------------------

SCREENS = {
    # Main Landing / Introduction Screen
    "home_screen.dart": """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'courses_screen.dart';
import 'live_class_screen.dart';
import 'admission_screen.dart';
import 'exams_screen.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Live Announcement Ticker
            Container(
              color: AppTheme.royalBlue,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, color: AppTheme.academicGold, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'HSC 2026 Special Model Test Series Admissions Active! Morning and Day shift batches open.',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Intro Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryNavy.withOpacity(0.04),
                    AppTheme.royalBlue.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.royalBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: AppTheme.royalBlue),
                            SizedBox(width: 6),
                            Text(
                              'PREMIER COACHING & LMS INFRASTRUCTURE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.royalBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Smart Digital Coaching for Board Exams & Admissions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Attend live interactive classes, download chapter-wise lecture sheets, give auto-graded MCQ tests, and track attendance by Class, Group, and Shift.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.academicGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdmissionScreen())),
                            icon: const Icon(Icons.how_to_reg, size: 18),
                            label: const Text('Student Admission', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.royalBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassScreen())),
                            icon: const Icon(Icons.live_tv, size: 18),
                            label: const Text('Join Live Class', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamsScreen())),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Take Model Test', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Academy Pillars
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      const Text(
                        'Core Academy Capabilities',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _buildFeatureCard(Icons.videocam, 'Live Classroom', 'Attend high-definition broadcasts with live teacher whiteboard and Q&A.')),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildFeatureCard(Icons.quiz, 'Instant MCQ Exams', 'Timed testing with instant score calculation, negative marks, and answer review.')),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildFeatureCard(Icons.picture_as_pdf, 'PDF Lecture Notes', 'Complete chapter formula cards, question banks, and handouts.')),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildFeatureCard(Icons.videocam, 'Live Classroom', 'Attend high-definition broadcasts with live teacher whiteboard and Q&A.'),
                                    const SizedBox(height: 12),
                                    _buildFeatureCard(Icons.quiz, 'Instant MCQ Exams', 'Timed testing with instant score calculation, negative marks, and answer review.'),
                                    const SizedBox(height: 12),
                                    _buildFeatureCard(Icons.picture_as_pdf, 'PDF Lecture Notes', 'Complete chapter formula cards, question banks, and handouts.'),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.royalBlue, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
"""
}

# Add Courses, Live Class, Contact, Admission screens
SCREENS["courses_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'admission_screen.dart';
import '../main.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final courses = [
      {'title': 'HSC Higher Math 1st & 2nd Paper', 'class': 'Class 12', 'group': 'Science', 'fee': '৳ 3,000 / Mo'},
      {'title': 'Physics Mechanics & Electromagnetism', 'class': 'Class 12', 'group': 'Science', 'fee': '৳ 3,000 / Mo'},
      {'title': 'SSC Special Model Test Series', 'class': 'Class 10', 'group': 'All Groups', 'fee': '৳ 2,500 / Full'},
      {'title': 'University Engineering Admission Care', 'class': 'Admission', 'group': 'Science', 'fee': '৳ 8,500 / Full'},
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Academic Batches & Courses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Enroll in academic batches organized by Class, Group, and Shift.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final c = courses[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.royalBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.menu_book, color: AppTheme.royalBlue),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['title']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('${c['class']} • Group: ${c['group']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(c['fee']!, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.royalBlue, fontSize: 14)),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.academicGold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdmissionScreen())),
                                  child: const Text('Enroll', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["live_class_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  final List<String> _chatMessages = [
    'Nusrat (Roll 1002): Sir, could you re-explain problem 3?',
    'Rahim (Roll 1003): Formula is clear now sir!',
    'Sir Tanzeem (Instructor): Check formula 4 on your lecture notes sheet.',
  ];
  final TextEditingController _chatCtrl = TextEditingController();

  void _sendChat() {
    if (_chatCtrl.text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add('You (Student): ${_chatCtrl.text.trim()}');
      _chatCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simulated Stream Frame
                Container(
                  width: double.infinity,
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.academicGold, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.live_tv, size: 54, color: AppTheme.accentRose),
                          SizedBox(height: 12),
                          Text(
                            'Calculus Master Problem Clinic Live Stream',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          SizedBox(height: 4),
                          Text('Instructor: Sir Tanzeem • Morning Shift Batch', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRose,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 6),
                              Text('LIVE (84 Students)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Chat Box
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: AppTheme.royalBlue, size: 18),
                            SizedBox(width: 8),
                            Text('Live Classroom Discussion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        ),
                        const Divider(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _chatMessages.length,
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(_chatMessages[i], style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Ask a question in class...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _sendChat(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                              icon: const Icon(Icons.send, size: 18),
                              onPressed: _sendChat,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["contact_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact & Coaching Helpline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Have inquiries regarding batches, timings, or technical assistance?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    const ListTile(
                      dense: true,
                      leading: Icon(Icons.phone, color: AppTheme.royalBlue),
                      title: Text('+880 1711-223344', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Morning & Evening Support Shifts'),
                    ),
                    const ListTile(
                      dense: true,
                      leading: Icon(Icons.email, color: AppTheme.royalBlue),
                      title: Text('academy@bsgdigita.com', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Official Academic Inquiries'),
                    ),
                    const Divider(height: 30),
                    const Text('Send Us a Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Student / Guardian Name', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Your Inquiry Details', border: OutlineInputBorder())),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inquiry dispatched to BSGD Academy academic coordinator.')),
                        );
                      },
                      child: const Text('Submit Message', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["admission_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'student_dashboard_screen.dart';
import '../main.dart';

class AdmissionScreen extends StatefulWidget {
  const AdmissionScreen({super.key});

  @override
  State<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends State<AdmissionScreen> {
  String _selectedClass = 'Class 12';
  String _selectedGroup = 'Science';
  String _selectedShift = 'Morning';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.academicGold.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('ADMISSIONS ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.academicGold)),
                    ),
                    const SizedBox(height: 10),
                    const Text('Student Admission Form', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Register your academic profile to enter scheduled batches.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    const TextField(decoration: InputDecoration(labelText: 'Full Student Name *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(labelText: 'Academic Class *', border: OutlineInputBorder()),
                      items: ['Class 9', 'Class 10', 'Class 11', 'Class 12', 'Admission Unit']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedClass = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(labelText: 'Academic Group *', border: OutlineInputBorder()),
                      items: ['Science', 'Commerce / Business Studies', 'Humanities / Arts']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGroup = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedShift,
                      decoration: const InputDecoration(labelText: 'Batch Shift *', border: OutlineInputBorder()),
                      items: ['Morning', 'Day', 'Evening']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedShift = val!),
                    ),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Student Mobile Phone *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Guardian Mobile Phone *', border: OutlineInputBorder())),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.academicGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admission registered successfully! Welcome to BSGD Academy.')),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
                      },
                      child: const Text('Complete Registration & Enter LMS', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""

# Exams Center & Interactive MCQ Engine Screen
SCREENS["exams_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'mcq_exam_screen.dart';
import 'written_exam_screen.dart';
import '../main.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Examination Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Take auto-graded MCQ tests with negative marking or submit handwritten CQ written papers.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.accentEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Text('LIVE MCQ EXAM', style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.w800, fontSize: 11)),
                            ),
                            const Spacer(),
                            const Text('Duration: 15 Mins', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('HSC Higher Math 1st Paper - Calculus Special Model Test', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('4 Questions • Negative Marking: 0.25 • Instant score calculation & answer key.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.academicGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const McqExamScreen())),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Start MCQ Test Now', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.royalBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Text('WRITTEN EXAM', style: TextStyle(color: AppTheme.royalBlue, fontWeight: FontWeight.w800, fontSize: 11)),
                            ),
                            const Spacer(),
                            const Text('Duration: 45 Mins', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Physics 1st Paper - Newtonian Mechanics Written Test', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Total Marks: 30 • Download Question Paper & upload answer sheet photo.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrittenExamScreen())),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Enter Written Test', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["mcq_exam_screen.dart"] = """import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class McqExamScreen extends StatefulWidget {
  const McqExamScreen({super.key});

  @override
  State<McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends State<McqExamScreen> {
  int _secondsLeft = 900;
  Timer? _timer;
  final Map<int, int> _selectedAnswers = {};

  final questions = [
    {
      'q': 'What is the derivative of f(x) = sin(3x)?',
      'options': ['3cos(3x)', '-3cos(3x)', 'cos(3x)', '-cos(3x)'],
      'correct': 0,
      'explanation': 'Chain rule: d/dx[sin(u)] = cos(u)*du/dx. Since u=3x, du/dx=3. Answer: 3cos(3x).'
    },
    {
      'q': 'Evaluate: lim (x->0) [sin(x) / x]',
      'options': ['0', 'Infinity', '1', 'Does not exist'],
      'correct': 2,
      'explanation': 'Standard fundamental trigonometric limit: lim(x->0)[sin(x)/x] = 1.'
    },
    {
      'q': 'What is the integral of e^(2x) dx?',
      'options': ['e^(2x) + C', '(1/2)e^(2x) + C', '2e^(2x) + C', 'e^x + C'],
      'correct': 1,
      'explanation': '∫e^(ax) dx = (1/a)e^(ax) + C. For a=2: (1/2)e^(2x) + C.'
    },
    {
      'q': 'If y = ln(x^2), what is dy/dx?',
      'options': ['1/x^2', '2/x', '2x', 'x/2'],
      'correct': 1,
      'explanation': 'ln(x^2) = 2*ln(x). Derivative of 2*ln(x) is 2/x.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _submitExam(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitExam({bool auto = false}) {
    _timer?.cancel();
    int correctCount = 0;
    int wrongCount = 0;

    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        if (_selectedAnswers[i] == questions[i]['correct']) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    }

    double rawScore = (correctCount * 5.0) - (wrongCount * 0.25);
    if (rawScore < 0) rawScore = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Result Evaluated!', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Score: ${rawScore.toStringAsFixed(2)} / 20.00', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.royalBlue)),
            const SizedBox(height: 8),
            Text('Correct Answers: $correctCount', style: const TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.w700)),
            Text('Incorrect Answers: $wrongCount (-0.25 penalty)', style: const TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('Your result has been registered to the merit board and teacher gradebook.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
            },
            child: const Text('View Merit Board'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live MCQ Assessment'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentRose.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.accentRose, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (ctx, i) {
                    final q = questions[i];
                    final opts = q['options'] as List<String>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q${i + 1}: ${q['q']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 12),
                            ...List.generate(opts.length, (optIdx) {
                              return RadioListTile<int>(
                                dense: true,
                                title: Text(opts[optIdx]),
                                value: optIdx,
                                groupValue: _selectedAnswers[i],
                                onChanged: (val) => setState(() => _selectedAnswers[i] = val!),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.academicGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _submitExam(auto: false),
                  child: const Text('Submit Exam & Calculate Score', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["written_exam_screen.dart"] = """import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'student_dashboard_screen.dart';

class WrittenExamScreen extends StatelessWidget {
  const WrittenExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Written Examination Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Physics 1st Paper - Newtonian Mechanics Written Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Total Marks: 30 • Class 12 Science', style: TextStyle(color: AppTheme.textMuted)),
                    const Divider(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading official question paper PDF...')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Question Paper (.PDF)'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Answer Script Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withOpacity(0.05),
                        border: Border.all(color: AppTheme.royalBlue.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.royalBlue),
                          SizedBox(height: 8),
                          Text('Select Handwritten Solution Photos or PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('Maximum file size: 25 MB', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.academicGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Written paper submitted for teacher review and grading.')),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
                      },
                      child: const Text('Submit Written Exam for Evaluation', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["results_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam Results & Merit Standings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Instant automated scores and teacher-evaluated written grades.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildResultRow('HSC Higher Math 1st Paper - Calculus Special', '18.75 / 20.00', 'Rank #1 (93.7%)', AppTheme.accentEmerald),
                        const Divider(height: 24),
                        _buildResultRow('Physics 1st Paper - Newtonian Mechanics', '26.00 / 30.00', 'Graded by Sir', AppTheme.royalBlue),
                        const Divider(height: 24),
                        _buildResultRow('Organic Chemistry Mechanism Test', '22.50 / 25.00', 'Rank #3 (90.0%)', AppTheme.accentEmerald),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String score, String badge, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Score: $score', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(badge, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ],
    );
  }
}
"""

SCREENS["notes_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final notes = [
      {'title': 'Calculus Complete Formula & Shortcut Sheet', 'class': 'Class 12', 'pages': '32 Pages', 'size': '3.4 MB'},
      {'title': 'Newtonian Mechanics Vector Derivation Bank', 'class': 'Class 11', 'pages': '48 Pages', 'size': '5.1 MB'},
      {'title': 'Organic Chemistry Reactions Summary Handout', 'class': 'Class 12', 'pages': '24 Pages', 'size': '2.8 MB'},
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PDF Lecture Notes & Handouts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Chapter-wise study notes, formula compendiums, and model questions.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final n = notes[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: AppTheme.accentRose, size: 30),
                        title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text('${n['class']} • ${n['pages']} • ${n['size']}', style: const TextStyle(fontSize: 12)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalBlue, foregroundColor: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Downloading: ${n['title']}')),
                            );
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

# Student Dashboard (Detailed LMS view)
SCREENS["student_dashboard_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'live_class_screen.dart';
import 'exams_screen.dart';
import '../main.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Profile Greeting Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primaryNavy, AppTheme.royalBlue]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.academicGold,
                        child: Text('TA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanzeem Ahmed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('Roll: #1001 • Class 12 Science (Morning Shift)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.academicGold, foregroundColor: Colors.black),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassScreen())),
                        child: const Text('Live Class', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Metrics
                Row(
                  children: [
                    Expanded(child: _buildMetric('Attendance', '94.2%', Icons.check_circle_outline, AppTheme.accentEmerald)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetric('Merit Rank', '4th / 142', Icons.emoji_events_outlined, AppTheme.royalBlue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetric('GPA Standing', '5.00 (A+)', Icons.star_border, AppTheme.academicGold)),
                  ],
                ),
                const SizedBox(height: 24),

                // Syllabus Progress
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subject Syllabus Completion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 16),
                        _buildProgress('Higher Mathematics', 0.82),
                        const SizedBox(height: 10),
                        _buildProgress('Physics (1st & 2nd Paper)', 0.74),
                        const SizedBox(height: 10),
                        _buildProgress('Chemistry', 0.68),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(String subject, double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Text(subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${(pct * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: AppTheme.borderLight,
          color: AppTheme.royalBlue,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
"""

# Teacher Dashboard & Management Screens
SCREENS["teacher_dashboard_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_students_screen.dart';
import 'live_class_screen.dart';
import '../main.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Faculty Command Center', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('Manage enrolled cohorts, attendance sheets, and examinations.', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose, foregroundColor: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassScreen())),
                      icon: const Icon(Icons.broadcast_on_home, size: 16),
                      label: const Text('Go Live Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Faculty KPIs
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('Total Students', '428', '6 Batches', Icons.groups, AppTheme.royalBlue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Today Attendance', '92.4%', '395 Present', Icons.how_to_reg, AppTheme.accentEmerald)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCard('Tuition Collected', '৳3,45,000', '94% Cleared', Icons.payments, AppTheme.academicGold)),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Management Links
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quick Administrative Tools', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAttendanceScreen())),
                              icon: const Icon(Icons.fact_check),
                              label: const Text('Take Attendance (Class/Group/Shift)'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherStudentsScreen())),
                              icon: const Icon(Icons.person_search),
                              label: const Text('Filter Student Directory'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String val, String sub, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text(sub, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
"""

SCREENS["teacher_attendance_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  String _filterClass = '12';
  String _filterGroup = 'Science';
  String _filterShift = 'Morning';

  final List<Student> _students = [
    Student(roll: '1001', name: 'Tanzeem Ahmed', studentClass: '12', group: 'Science', shift: 'Morning', phone: '01711-223344', status: 'Active', attendance: 94.2),
    Student(roll: '1002', name: 'Nusrat Jahan', studentClass: '12', group: 'Science', shift: 'Morning', phone: '01822-334455', status: 'Active', attendance: 98.0),
    Student(roll: '1003', name: 'Rahim Chowdhury', studentClass: '12', group: 'Science', shift: 'Morning', phone: '01933-445566', status: 'Active', attendance: 88.5),
    Student(roll: '1004', name: 'Sadia Islam', studentClass: '11', group: 'Science', shift: 'Day', phone: '01744-556677', status: 'Active', attendance: 91.0),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    final filtered = _students.where((s) {
      final matchC = _filterClass == 'All' || s.studentClass == _filterClass;
      final matchG = _filterGroup == 'All' || s.group == _filterGroup;
      final matchS = _filterShift == 'All' || s.shift == _filterShift;
      return matchC && matchG && matchS;
    }).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('Filter attendance by Class, Group, and Shift.', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose, foregroundColor: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SMS Dispatched: "Respected Guardian, your ward was absent from today\\'s class."')),
                        );
                      },
                      icon: const Icon(Icons.sms, size: 16),
                      label: const Text('Send SMS to Absentees'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Batch Filters
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterClass,
                            decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder(), isDense: true),
                            items: ['All', '10', '11', '12'].map((v) => DropdownMenuItem(value: v, child: Text('Class $v'))).toList(),
                            onChanged: (v) => setState(() => _filterClass = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterGroup,
                            decoration: const InputDecoration(labelText: 'Group', border: OutlineInputBorder(), isDense: true),
                            items: ['All', 'Science', 'Commerce', 'Humanities'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) => setState(() => _filterGroup = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterShift,
                            decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                            items: ['All', 'Morning', 'Day', 'Evening'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) => setState(() => _filterShift = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final s = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.royalBlue,
                          child: Text(s.roll, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text('Guardian: ${s.phone} • Class ${s.studentClass} (${s.shift})', style: const TextStyle(fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAttBtn('P', AppTheme.accentEmerald, s.currentStatus == 'P', () => setState(() => s.currentStatus = 'P')),
                            const SizedBox(width: 4),
                            _buildAttBtn('A', AppTheme.accentRose, s.currentStatus == 'A', () => setState(() => s.currentStatus = 'A')),
                            const SizedBox(width: 4),
                            _buildAttBtn('L', AppTheme.accentAmber, s.currentStatus == 'L', () => setState(() => s.currentStatus = 'L')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttBtn(String label, Color color, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    );
  }
}
"""

SCREENS["teacher_students_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class TeacherStudentsScreen extends StatelessWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Roster Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('View students filtered by Class, Group, and Shift.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 20),
                Card(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ListTile(
                        leading: CircleAvatar(child: Text('1001')),
                        title: Text('Tanzeem Ahmed', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Class 12 • Science (Morning Shift) • Guardian: 01711-223344'),
                        trailing: Text('94.2% Att.', style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.w700)),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(child: Text('1002')),
                        title: Text('Nusrat Jahan', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Class 12 • Science (Morning Shift) • Guardian: 01822-334455'),
                        trailing: Text('98.0% Att.', style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

SCREENS["teacher_exams_screen.dart"] = """import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class TeacherExamsScreen extends StatelessWidget {
  const TeacherExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(onToggleTheme: appState.toggleTheme, isDark: appState.isDarkMode),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam & Written Script Evaluator', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Inspect student submissions and assign marks.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Written Script for Grading', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Divider(height: 20),
                        ListTile(
                          title: const Text('Nusrat Jahan (Roll 1002)', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('Physics 1st Paper - Newtonian Mechanics • 3 Pages PDF'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.academicGold, foregroundColor: Colors.black),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Grade Written Script'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(decoration: InputDecoration(labelText: 'Award Marks (Out of 30)')),
                                      SizedBox(height: 10),
                                      TextField(maxLines: 2, decoration: InputDecoration(labelText: 'Teacher Feedback')),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Grade released to student.')),
                                        );
                                      },
                                      child: const Text('Publish Grade'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Grade Paper', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

# -------------------------------------------------------------------------
# 7. APP ENTRY POINT (lib/main.dart)
# -------------------------------------------------------------------------

MAIN_DART = """import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BsgdOnlineAcademyApp());
}

class BsgdOnlineAcademyApp extends StatefulWidget {
  const BsgdOnlineAcademyApp({super.key});

  @override
  State<BsgdOnlineAcademyApp> createState() => _BsgdOnlineAcademyAppState();
}

class _BsgdOnlineAcademyAppState extends State<BsgdOnlineAcademyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      isDarkMode: _isDarkMode,
      toggleTheme: toggleTheme,
      child: MaterialApp(
        title: 'BSGD Online Academy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
      ),
    );
  }
}

class AppStateScope extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const AppStateScope({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static AppStateScope of(BuildContext context) {
    final AppStateScope? result = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(result != null, 'No AppStateScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) => isDarkMode != oldWidget.isDarkMode;
}
"""

# -------------------------------------------------------------------------
# 8. WRITE ALL FILES TO DISK
# -------------------------------------------------------------------------

files_to_write = {
    "pubspec.yaml": PUBSPEC_YAML,
    "lib/main.dart": MAIN_DART,
    "lib/theme/app_theme.dart": APP_THEME_DART,
    "lib/models/models.dart": MODELS_DART,
    "lib/widgets/app_drawer.dart": APP_DRAWER_DART,
      "lib/widgets/app_nav_bar.dart": APP_NAV_BAR_DART,
}

for name, content in SCREENS.items():
    files_to_write[f"lib/screens/{name}"] = content

for rel_path, content in files_to_write.items():
    full_path = os.path.join(BASE_DIR, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content.strip())
    print(f"Generated Dart File: {rel_path}")
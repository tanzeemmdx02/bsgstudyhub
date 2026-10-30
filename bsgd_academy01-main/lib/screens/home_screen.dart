import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import 'admission_screen.dart';
import 'contact_screen.dart';
import 'courses_screen.dart';
import 'exams_screen.dart';
import 'live_class_screen.dart';
import 'notes_screen.dart';
import 'public_suggestion_screen.dart';
import 'results_screen.dart';

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
            _buildAnnouncementBar(),
            _buildHeroSection(context),
            _buildStatsStrip(context),
            _buildUpcomingLiveAlert(context),
            _buildCorePillars(context),
            _buildDynamicFeaturedBatches(context),
            _buildDynamicNoticesTicker(context),
            _buildInstructorSpotlight(context),
            _buildTestimonialsSection(context),
            _buildFaqSection(context),
            _buildFinalCta(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementBar() {
    return Container(
      color: AppTheme.royalBlue,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, color: AppTheme.academicGold, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              '🌟 HSC Special Model Test Series & Morning/Day Shift Admissions Are Now Open!',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 400 ? 24.0 : (w < 600 ? 30.0 : 38.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryNavy.withOpacity(0.06),
            AppTheme.royalBlue.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.royalBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.royalBlue.withOpacity(0.3)),
                ),
                child: const Text(
                  '🚀 NEXT-GEN SMART COACHING & LMS INFRASTRUCTURE',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.royalBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Empowering Your Academic Excellence & Board Success',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Join live interactive classes, download comprehensive chapter notes, evaluate progress through automated MCQ exams with negative marking, and track shifts dynamically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.academicGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdmissionScreen()),
                    ),
                    icon: const Icon(Icons.how_to_reg, size: 18),
                    label: const Text(
                      'Student Admission',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveClassScreen()),
                    ),
                    icon: const Icon(Icons.live_tv, size: 18),
                    label: const Text(
                      'Join Live Class',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NoticeScreen()),
                    ),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: const Text(
                      'Notices',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PublicSuggestionScreen()),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: const Text(
                      'Suggestions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsStrip(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, studentSnapshot) {
        final studentCount = studentSnapshot.hasData ? '${studentSnapshot.data!.docs.length}+' : '4,500+';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('exams').snapshots(),
          builder: (context, examSnapshot) {
            final examCount = examSnapshot.hasData ? '${examSnapshot.data!.docs.length}+' : '50+';

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight.withOpacity(0.6)),
                  bottom: BorderSide(color: AppTheme.borderLight.withOpacity(0.6)),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(studentCount, 'Enrolled Students', Icons.groups),
                                _buildStatItem('98.4%', 'Exam Success Rate', Icons.verified_outlined),
                                _buildStatItem(examCount, 'Active Exams & Tests', Icons.quiz_outlined),
                                _buildStatItem('100%', 'Secure Cloud LMS', Icons.cloud_done_outlined),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildStatItem(studentCount, 'Enrolled Students', Icons.groups)),
                                    Expanded(child: _buildStatItem('98.4%', 'Exam Success Rate', Icons.verified_outlined)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(child: _buildStatItem(examCount, 'Active Exams & Tests', Icons.quiz_outlined)),
                                    Expanded(child: _buildStatItem('100%', 'Secure Cloud LMS', Icons.cloud_done_outlined)),
                                  ],
                                ),
                              ],
                            );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.royalBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.royalBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppTheme.royalBlue,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLiveAlert(BuildContext context) {
    return Container(
      color: AppTheme.primaryNavy,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 640;

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '● LIVE INTERACTIVE CLASSES AVAILABLE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Join Daily Subject-Wise Problem-Solving Sessions',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Interactive Whiteboard • Live Q&A • Morning & Day Batches',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              );

              final button = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.academicGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveClassScreen()),
                ),
                icon: const Icon(Icons.meeting_room, size: 18),
                label: const Text(
                  'Enter Classroom',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textBlock,
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: button),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: textBlock),
                  const SizedBox(width: 12),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCorePillars(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'Complete Academic Coaching Ecosystem',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Built specifically for comprehensive board exam preparation and competitive admissions.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 35),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.videocam_outlined,
                                'Live Virtual Classes',
                                'Interactive digital whiteboard, real-time live chat Q&A, and lecture archives.',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.quiz_outlined,
                                'MCQ & Written Tests',
                                'Instant automated scoring, negative marking, and professional grade analysis.',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFeatureCard(
                                Icons.picture_as_pdf_outlined,
                                'PDF Lecture Sheets',
                                'Chapter-wise formula sheets, past board question banks, and teacher suggestions.',
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFeatureCard(
                              Icons.videocam_outlined,
                              'Live Virtual Classes',
                              'Interactive digital whiteboard, real-time live chat Q&A, and lecture archives.',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              Icons.quiz_outlined,
                              'MCQ & Written Tests',
                              'Instant automated scoring, negative marking, and professional grade analysis.',
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureCard(
                              Icons.picture_as_pdf_outlined,
                              'PDF Lecture Sheets',
                              'Chapter-wise formula sheets, past board question banks, and teacher suggestions.',
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.royalBlue, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFeaturedBatches(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured Batches & Courses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoursesScreen()),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('courses').limit(2).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _buildBatchCard(
                      context,
                      'HSC Accounting 1st & 2nd Paper',
                      'Class 12 • Commerce',
                      'Morning Shift (7:30 AM)',
                      '৳ 3,000 / Mo',
                      AppTheme.royalBlue,
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBatchCard(
                          context,
                          data['title']?.toString() ?? 'Academic Course',
                          'Class ${data['class'] ?? '12'} • ${data['group'] ?? 'General'}',
                          data['schedule'] ?? 'Active Shift',
                          data['price'] != null ? '৳ ${data['price']}' : 'Free / Enrolled',
                          AppTheme.royalBlue,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCard(
    BuildContext context,
    String title,
    String meta,
    String shift,
    String price,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(meta, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Enrollment Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(shift, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(price, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.academicGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdmissionScreen())),
                  child: const Text('Enroll Now', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicNoticesTicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Notices & Bulletins', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notices').orderBy('createdAt', descending: true).limit(3).snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No urgent notices posted right now. Check back soon!'),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active, color: AppTheme.academicGold),
                          title: Text(data['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['body'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen())),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorSpotlight(BuildContext context) {
    return Container(
      color: AppTheme.primaryNavy.withOpacity(0.03),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text('Expert Faculty & Mentors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Learn directly from experienced educators dedicated to your board success.', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: AppTheme.royalBlue,
                              child: Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            const Text('Main Faculty Team', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Department Heads & Examiners', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 8),
                            const Text('Specialized in conceptual clarity, shortcut techniques, and rigorous exam practice.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text('What Our Students Say', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth > 700;
                  final card1 = _buildTestimonialCard('BSGD Academy helped me structure my HSC preparation seamlessly. The daily MCQ model tests made all the difference!', 'Tanvir Ahmed', 'HSC Batch 2025');
                  final card2 = _buildTestimonialCard('The live interactive classes and digital PDF lecture notes gave me top scores in Accounting & Finance.', 'Sumaiya Islam', 'HSC Commerce');

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 16),
                        Expanded(child: card2),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      card1,
                      const SizedBox(height: 16),
                      card2,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(String quote, String name, String role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: AppTheme.academicGold, size: 32),
            const SizedBox(height: 10),
            Text('"$quote"', style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, height: 1.5)),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(role, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              const Text('Frequently Asked Questions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),
              _buildFaqItem('How do I join live classes?', 'Once registered and admitted into your batch, navigate to the Live Classroom tab or use your Student LMS Portal to join sessions directly.'),
              _buildFaqItem('Are the MCQ exams auto-graded?', 'Yes! All model tests and MCQs feature instant automated scoring alongside detailed question explanations.'),
              _buildFaqItem('How can parents check attendance?', 'Teachers maintain daily attendance registers categorized by Class, Group, and Shift, ensuring total transparency.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(a, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCta(BuildContext context) {
    return Container(
      color: AppTheme.royalBlue,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Ready to Transform Your Academic Future?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Secure your spot in our morning or day shift batches today.',
              style: TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdmissionScreen())),
              child: const Text('Apply for Admission Today', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: AppTheme.primaryNavy,
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      child: const Column(
        children: [
          Text(
            'BSGD Online Academy & Coaching Management Suite',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            '© 2026 BSGD Online Academy. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

typedef NotesScreen = NoticeScreen;
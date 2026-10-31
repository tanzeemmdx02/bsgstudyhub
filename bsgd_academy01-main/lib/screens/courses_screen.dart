import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/student_login_screen.dart';
import '../services/auth_service.dart';
import '../services/bkash_payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bkash_payment_modal.dart';
import 'video_watch_screen.dart';

class CoursesScreen extends StatefulWidget {
  final bool embedded;

  const CoursesScreen({super.key, this.embedded = false});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _autoEnrollFree = true;

  @override
  void initState() {
    super.initState();
    _loadAutoEnrollPreference();
  }

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser ?? AuthService().firebaseUser;

  Future<void> _loadAutoEnrollPreference() async {
    final user = _currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('autoEnrollFree')) {
        setState(() {
          _autoEnrollFree = data['autoEnrollFree'] == true;
        });
      }
    }
  }

  Future<void> _toggleAutoEnroll(bool value) async {
    final user = _currentUser;
    if (user == null) return;

    setState(() => _autoEnrollFree = value);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'autoEnrollFree': value,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto-enroll enabled: Matching free courses will automatically appear in your dashboard.'
                : 'Auto-enroll disabled.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToDashboard(String courseId, String courseTitle) async {
    final user = _currentUser;
    if (user == null) {
      _showLoginPrompt(courseTitle);
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrolled_courses')
        .doc(courseId)
        .set({
      'courseId': courseId,
      'title': courseTitle,
      'enrolledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$courseTitle" added to your dashboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLoginPrompt(String courseTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You must be logged in to add "$courseTitle" to your dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                  builder: (_) => const StudentLoginScreen(targetScreen: CoursesScreen()),
                ),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  bool _matchesStudentProfile(Map<String, dynamic> courseData, Map<String, dynamic>? studentData) {
    if (studentData == null) return false;

    final cClass = courseData['class']?.toString().trim();
    final cGroup = courseData['department']?.toString().trim() ?? courseData['group']?.toString().trim();
    final cSubDept = courseData['subDepartment']?.toString().trim();
    final cSubject = courseData['subject']?.toString().trim();

    final sClass = studentData['class']?.toString().trim();
    final sGroup = studentData['group']?.toString().trim();
    final sSubDept = studentData['subDepartment']?.toString().trim();
    final sSubject = studentData['subject']?.toString().trim();

    if (cClass != null && cClass.isNotEmpty && cClass != 'General' && cClass != sClass) {
      return false;
    }
    if (cGroup != null && cGroup.isNotEmpty && cGroup != 'General' && cGroup != sGroup) {
      return false;
    }
    if (cSubDept != null && cSubDept.isNotEmpty && cSubDept != 'General' && cSubDept != sSubDept) {
      return false;
    }
    if (cSubject != null && cSubject.isNotEmpty && cSubject != 'General' && cSubject != sSubject) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    final body = StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : const Stream.empty(),
      builder: (context, userSnap) {
        final studentData = userSnap.data?.data() as Map<String, dynamic>?;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Video Courses',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap a course, then select any lesson to watch.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (user != null) ...[
                      Row(
                        children: [
                          const Text(
                            'Auto Add Free',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: _autoEnrollFree,
                            activeColor: Colors.green,
                            onChanged: _toggleAutoEnroll,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No video courses yet.\nTeachers add them from the teacher dashboard.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  StreamBuilder<QuerySnapshot>(
                    stream: user != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('enrolled_courses')
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, enrolledSnap) {
                      final enrolledIds =
                          (enrolledSnap.data?.docs ?? []).map((e) => e.id).toSet();

                      return LayoutBuilder(
                        builder: (context, c) {
                          final cross = c.maxWidth > 900
                              ? 3
                              : c.maxWidth > 600
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cross,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: cross == 1 ? 1.5 : 0.88,
                            ),
                            itemBuilder: (context, i) {
                              final docId = docs[i].id;
                              final d = docs[i].data() as Map<String, dynamic>;
                              final title = d['title']?.toString() ?? 'Course';
                              final desc = d['description']?.toString() ?? '';
                              final isFree = d['isFree'] ?? true;
                              final price = (d['price'] ?? 0.0).toDouble();
                              final videoCount = d['videoCount'] ?? 0;
                              final className = d['class'];
                              final dept = d['department'] ?? d['group'];
                              final subject = d['subject'];
                              final teacherName = d['teacherName'];

                              final matchesProfile = _matchesStudentProfile(d, studentData);
                              final isEnrolled = enrolledIds.contains(docId) ||
                                  (_autoEnrollFree && isFree && matchesProfile);

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    // Paid courses require login & unlock
                                    if (!isFree && price > 0) {
                                      if (user == null) {
                                        _showLoginPrompt(title);
                                        return;
                                      }

                                      final alreadyUnlocked =
                                          await BkashPaymentService.hasPurchasedItem(docId);

                                      if (!alreadyUnlocked && !isEnrolled) {
                                        if (!context.mounted) return;

                                        final paidSuccess =
                                            await BkashPaymentModal.show(
                                          context,
                                          itemId: docId,
                                          itemType: 'course',
                                          itemTitle: title,
                                          price: price,
                                        );

                                        if (paidSuccess != true) return;
                                      }
                                    }

                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _CourseVideosSubpage(
                                          courseId: docId,
                                          title: title,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(
                                              Icons.play_circle_outline,
                                              size: 36,
                                              color: AppTheme.royalBlue,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (isFree
                                                        ? Colors.green
                                                        : Colors.deepOrange)
                                                    .withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isFree ? 'FREE' : '৳${price.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: isFree
                                                      ? Colors.green.shade800
                                                      : Colors.deepOrange.shade800,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (className != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '$className • ${dept ?? 'General'} • ${subject ?? 'General'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.royalBlue,
                                            ),
                                          ),
                                        ],
                                        if (teacherName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Instructor: $teacherName',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$videoCount video(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isEnrolled
                                                    ? Colors.grey.shade200
                                                    : AppTheme.royalBlue,
                                                foregroundColor: isEnrolled
                                                    ? Colors.black87
                                                    : Colors.white,
                                                elevation: isEnrolled ? 0 : 2,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: isEnrolled
                                                  ? null
                                                  : () => _addToDashboard(docId, title),
                                              icon: Icon(
                                                isEnrolled
                                                    ? Icons.check
                                                    : Icons.add_to_photos_outlined,
                                                size: 14,
                                              ),
                                              label: Text(
                                                isEnrolled ? 'Enrolled' : 'Add to my Dash',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: body,
    );
  }
}

class _CourseVideosSubpage extends StatelessWidget {
  final String courseId;
  final String title;

  const _CourseVideosSubpage({required this.courseId, required this.title});

  bool _isDirectVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('github.com') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.contains('objects.githubusercontent.com');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('videos')
            .orderBy('order')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snap.data?.docs ?? [];

          if (videos.isEmpty) {
            return const Center(child: Text('No videos in this course yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final vDoc = videos[i];
              final v = vDoc.data() as Map<String, dynamic>;
              final vTitle = v['title']?.toString() ?? 'Video ${i + 1}';
              final url = v['url']?.toString() ?? '';
              final duration = v['duration']?.toString() ?? '30m';
              final desc = v['description']?.toString() ?? '';
              final thumb = v['thumbnail']?.toString() ?? '';
              final isDirect = v['isDirectVideo'] == true || _isDirectVideo(url);

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: thumb.isNotEmpty
                            ? Image.network(
                                thumb,
                                width: 80,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 48,
                                  color: AppTheme.royalBlue,
                                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 48,
                                color: AppTheme.royalBlue,
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDirect ? Colors.blue.shade900 : Colors.red.shade900,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isDirect ? 'IN-APP' : 'YT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    vTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    '$duration${desc.isNotEmpty ? ' • $desc' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: url.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoWatchScreen(
                                courseId: courseId,
                                videoId: vDoc.id,
                                title: vTitle,
                                youtubeUrl: url,
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
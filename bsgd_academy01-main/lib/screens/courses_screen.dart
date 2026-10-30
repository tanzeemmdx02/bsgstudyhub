import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/student_login_screen.dart';
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

  Future<void> _loadAutoEnrollPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
    final user = FirebaseAuth.instance.currentUser;
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
                ? 'Auto-enroll enabled: New free courses will automatically appear in your dashboard.'
                : 'Auto-enroll disabled.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToDashboard(String courseId, String courseTitle) async {
    final user = FirebaseAuth.instance.currentUser;
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
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Login Required'),
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
                MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final body = StreamBuilder<QuerySnapshot>(
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
                        'Tap a course, then open a video to watch.',
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
                    'No video courses yet.\nTeachers add them from the teacher panel.',
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
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, i) {
                          final docId = docs[i].id;
                          final d = docs[i].data() as Map<String, dynamic>;
                          final title = d['title']?.toString() ?? 'Course';
                          final desc = d['description']?.toString() ?? '';
                          final isFree = d['isFree'] ?? true;
                          final price = (d['price'] ?? 0.0).toDouble();
                          final videoCount = d['videoCount'] ?? 0;

                          final isEnrolled = enrolledIds.contains(docId) ||
                              (_autoEnrollFree && isFree);

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                if (user == null) {
                                  _showLoginPrompt(title);
                                  return;
                                }

                                if (!isFree && price > 0) {
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
                                            color: isFree
                                                ? Colors.green
                                                : Colors.deepOrange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isFree ? 'FREE' : '৳${price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.white,
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
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
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
                                              borderRadius: BorderRadius.circular(8),
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
                                            style: const TextStyle(fontSize: 11),
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
            return const Center(child: Text('No videos in this course.'));
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
              final duration = v['duration']?.toString() ?? '';

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: AppTheme.royalBlue,
                    size: 36,
                  ),
                  title: Text(
                    vTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: duration.isNotEmpty
                      ? Text('Duration: $duration', style: const TextStyle(fontSize: 11))
                      : null,
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
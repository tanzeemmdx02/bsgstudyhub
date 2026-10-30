import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'video_watch_screen.dart';

class StudentCourseScreen extends StatelessWidget {
  const StudentCourseScreen({super.key});

  Future<void> _hideCourse(
      BuildContext context, String courseId, String courseTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Course'),
        content: Text('Are you sure you want to remove "$courseTitle" from your dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1. Delete if it exists in enrolled_courses
      await userRef.collection('enrolled_courses').doc(courseId).delete();

      // 2. Add to hidden/excluded list so auto-enroll free items don't bring it back
      await userRef.set({
        'hidden_courses': FieldValue.arrayUnion([courseId])
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "$courseTitle" from your dashboard.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Saved Courses')),
        body: const Center(
          child: Text('Please log in to view your enrolled courses.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Courses'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final bool autoEnrollFree = userData?['autoEnrollFree'] == true;
          final hiddenCourses = List<String>.from(userData?['hidden_courses'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('enrolled_courses')
                .snapshots(),
            builder: (context, enrolledSnap) {
              if (enrolledSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final enrolledDocs = enrolledSnap.data?.docs ?? [];
              final enrolledIds = enrolledDocs.map((doc) => doc.id).toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, coursesSnap) {
                  if (coursesSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allCourses = coursesSnap.data?.docs ?? [];

                  // Filter courses: must not be hidden, and must be either enrolled or free (with autoEnroll)
                  final savedCourses = allCourses.where((doc) {
                    if (hiddenCourses.contains(doc.id)) return false;
                    final data = doc.data() as Map<String, dynamic>;
                    final isFree = data['isFree'] ?? true;
                    return enrolledIds.contains(doc.id) ||
                        (autoEnrollFree && isFree);
                  }).toList();

                  if (savedCourses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bookmark_border_outlined,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No saved courses found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = savedCourses[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final courseId = doc.id;
                      final title = data['title']?.toString() ?? 'Course';
                      final desc = data['description']?.toString() ?? '';
                      final isFree = data['isFree'] ?? true;
                      final price = (data['price'] ?? 0.0).toDouble();
                      final videoCount = data['videoCount'] ?? 0;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _StudentCourseVideosPage(
                                  courseId: courseId,
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.royalBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.play_circle_fill,
                                        color: AppTheme.royalBlue,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              desc,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _hideCourse(context, courseId, title),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text(
                                        'Remove',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$videoCount Video(s)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFree
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.deepOrange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isFree ? 'FREE' : '৳${price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: isFree ? Colors.green : Colors.deepOrange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
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
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentCourseVideosPage extends StatelessWidget {
  final String courseId;
  final String title;

  const _StudentCourseVideosPage({required this.courseId, required this.title});

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
                  leading: const Icon(Icons.play_circle_fill, color: AppTheme.royalBlue, size: 36),
                  title: Text(vTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: duration.isNotEmpty ? Text('Duration: $duration', style: const TextStyle(fontSize: 11)) : null,
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: url.isEmpty ? null : () {
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
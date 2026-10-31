import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'video_watch_screen.dart';

class StudentCourseScreen extends StatelessWidget {
  const StudentCourseScreen({super.key});

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser ?? AuthService().firebaseUser;

  Future<void> _hideCourse(
      BuildContext context, String courseId, String courseTitle) async {
    final user = _currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Course', style: TextStyle(fontWeight: FontWeight.bold)),
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

      // 2. Add to hidden list so auto-enroll does not bring it back
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

                  // Filter courses: must not be hidden, and must be either enrolled or free matching profile
                  final savedCourses = allCourses.where((doc) {
                    if (hiddenCourses.contains(doc.id)) return false;
                    final data = doc.data() as Map<String, dynamic>;
                    final isFree = data['isFree'] ?? true;
                    final matchesProfile = _matchesStudentProfile(data, userData);
                    return enrolledIds.contains(doc.id) ||
                        (autoEnrollFree && isFree && matchesProfile);
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
                      final className = data['class'];
                      final dept = data['department'] ?? data['group'];
                      final subject = data['subject'];
                      final teacherName = data['teacherName'];

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
                                          if (className != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Class: $className • Dept: ${dept ?? 'General'} • Subject: ${subject ?? 'General'}',
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
                                                color: Colors.black87,
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
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 8),
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
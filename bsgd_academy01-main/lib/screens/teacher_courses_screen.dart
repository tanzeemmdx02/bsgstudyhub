import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'video_watch_screen.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  String? _openCourseId;
  String? _openCourseTitle;
  String? _openCourseClassDocId; // Stored to notify students of this specific class/subject

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_teacher_id';

    if (_openCourseId != null) {
      return _CoursePlaylistView(
        courseId: _openCourseId!,
        courseTitle: _openCourseTitle ?? 'Course',
        classDocId: _openCourseClassDocId,
        onBack: () => setState(() {
          _openCourseId = null;
          _openCourseTitle = null;
          _openCourseClassDocId = null;
        }),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Courses & Video Manager',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _showCreateCourseDialog(uid),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create Course',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('teacherId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No courses created yet.\nPress "Create Course" to add your first batch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title = d['title'] ?? 'Untitled Course';
                      final desc = d['description'] ?? '';
                      final videoCount = d['videoCount'] ?? 0;
                      final className = d['class'];
                      final subject = d['subject'];
                      final classDocId = d['classDocId']?.toString();
                      final isFree = d['isFree'] ?? true;
                      final price = d['price'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.royalBlue.withOpacity(
                              0.12,
                            ),
                            child: const Icon(
                              Icons.play_circle_fill,
                              color: AppTheme.royalBlue,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isFree ? Colors.green : Colors.deepOrange).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isFree ? 'FREE' : '৳$price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (className != null) ...[
                                  Text(
                                    'Class: $className • Dept: ${d['department'] ?? ''} • Subject: ${subject ?? ''}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.royalBlue),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  '$desc\n$videoCount video(s)',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => setState(() {
                            _openCourseId = id;
                            _openCourseTitle = title;
                            _openCourseClassDocId = classDocId;
                          }),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCourseDialog(String uid) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    bool dialogIsFree = true;
    String? dialogClass;
    String? dialogGroup;
    String? dialogSubDept;
    String? dialogClassDocId;
    String? dialogSubjectName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Create New Course',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Course title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Pricing Options *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Free'),
                                selected: dialogIsFree,
                                onSelected: (val) => setDialogState(() => dialogIsFree = true),
                                selectedColor: Colors.green.shade100,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Paid'),
                                selected: !dialogIsFree,
                                onSelected: (val) => setDialogState(() => dialogIsFree = false),
                                selectedColor: Colors.deepOrange.shade100,
                              ),
                            ),
                          ],
                        ),
                        if (!dialogIsFree) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            decoration: const InputDecoration(
                              labelText: 'Price (৳) *',
                              hintText: 'e.g. 500',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Class Classification:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                    builder: (context, snap) {
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No classes found in Daily Attendance.', style: TextStyle(color: Colors.red, fontSize: 12));
                      }

                      final List<String> classesList = docs
                          .map((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() ?? '')
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList();

                      List<String> groupsList = [];
                      if (dialogClass != null) {
                        groupsList = docs
                            .where((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() == dialogClass)
                            .map((d) => (d.data() as Map<String, dynamic>)['department']?.toString().trim() ?? '')
                            .where((g) => g.isNotEmpty)
                            .toSet()
                            .toList();
                      }

                      List<String> subDeptsList = [];
                      if (dialogClass != null && dialogGroup != null) {
                        subDeptsList = docs
                            .where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return data['name']?.toString().trim() == dialogClass &&
                                  data['department']?.toString().trim() == dialogGroup;
                            })
                            .map((d) => (d.data() as Map<String, dynamic>)['subDepartment']?.toString().trim() ?? 'General')
                            .where((sd) => sd.isNotEmpty)
                            .toSet()
                            .toList();
                      }

                      List<QueryDocumentSnapshot> matchingDocs = [];
                      if (dialogClass != null && dialogGroup != null && dialogSubDept != null) {
                        matchingDocs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final sd = data['subDepartment']?.toString().trim() ?? 'General';
                          return data['name']?.toString().trim() == dialogClass &&
                              data['department']?.toString().trim() == dialogGroup &&
                              sd == dialogSubDept;
                        }).toList();
                      }

                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: dialogClass,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder(), isDense: true),
                            items: classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                dialogClass = val;
                                dialogGroup = null;
                                dialogSubDept = null;
                                dialogClassDocId = null;
                                dialogSubjectName = null;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: dialogGroup,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Department / Group *', border: OutlineInputBorder(), isDense: true),
                            items: groupsList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: dialogClass == null ? null : (val) {
                              setDialogState(() {
                                dialogGroup = val;
                                dialogSubDept = null;
                                dialogClassDocId = null;
                                dialogSubjectName = null;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: dialogSubDept,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Sub-Department / Section *', border: OutlineInputBorder(), isDense: true),
                            items: subDeptsList.map((sd) => DropdownMenuItem(value: sd, child: Text(sd))).toList(),
                            onChanged: dialogGroup == null ? null : (val) {
                              setDialogState(() {
                                dialogSubDept = val;
                                dialogClassDocId = null;
                                dialogSubjectName = null;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: dialogClassDocId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder(), isDense: true),
                            items: matchingDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final subj = data['subject']?.toString().trim() ?? 'Subject';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(subj),
                              );
                            }).toList(),
                            onChanged: dialogSubDept == null ? null : (docId) {
                              if (docId != null) {
                                final matchDoc = matchingDocs.firstWhere((d) => d.id == docId);
                                final data = matchDoc.data() as Map<String, dynamic>;
                                setDialogState(() {
                                  dialogClassDocId = docId;
                                  dialogSubjectName = data['subject']?.toString().trim();
                                });
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || dialogClassDocId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course title and subject classification are required.')),
                  );
                  return;
                }
                if (!dialogIsFree) {
                  final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
                  if (p <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid price greater than 0.')),
                    );
                    return;
                  }
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    double parsedPrice = 0.0;
    if (!dialogIsFree) {
      parsedPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    }

    await FirebaseFirestore.instance.collection('courses').add({
      'title': title,
      'description': descCtrl.text.trim(),
      'isFree': dialogIsFree,
      'price': dialogIsFree ? 0.0 : parsedPrice,
      'class': dialogClass,
      'group': dialogGroup,
      'department': dialogGroup,
      'subDepartment': dialogSubDept,
      'classDocId': dialogClassDocId,
      'subject': dialogSubjectName,
      'teacherId': uid,
      'teacherName': AuthService().currentUserName,
      'videoCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course created, priced, and classified successfully.'),
        ),
      );
    }
  }
}

class _CoursePlaylistView extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? classDocId;
  final VoidCallback onBack;

  const _CoursePlaylistView({
    required this.courseId,
    required this.courseTitle,
    required this.classDocId,
    required this.onBack,
  });

  @override
  State<_CoursePlaylistView> createState() => _CoursePlaylistViewState();
}

class _CoursePlaylistViewState extends State<_CoursePlaylistView> {
  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.queryParameters['v'] != null) return uri.queryParameters['v'];
    if (uri.pathSegments.isNotEmpty) {
      final i = uri.pathSegments.indexWhere(
        (s) => s == 'embed' || s == 'shorts' || s == 'v',
      );
      if (i != -1 && i + 1 < uri.pathSegments.length) {
        return uri.pathSegments[i + 1];
      }
    }
    return null;
  }

  void _openWatchPage(String videoDocId, String title, String url) {
    final id = _extractYoutubeId(url);
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not a valid YouTube URL.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoWatchScreen(
          courseId: widget.courseId,
          videoId: videoDocId,
          title: title,
          youtubeUrl: url,
        ),
      ),
    );
  }

  Future<void> _addDocument(String videoId) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > 700 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File max ~700 KB.')));
        return;
      }

      final ext = file.name.split('.').last.toLowerCase();
      final type = ext == 'pdf' ? 'pdf' : 'image';

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('videos')
          .doc(videoId)
          .collection('documents')
          .add({
            'name': file.name,
            'type': type,
            'base64': base64Encode(bytes),
            'createdAt': FieldValue.serverTimestamp(),
            'teacherId': FirebaseAuth.instance.currentUser?.uid,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Document added: ${file.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _addVideoByUrl() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45m');
    final thumbCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Add YouTube Video',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Video title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL *',
                  hintText: 'https://youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Video Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (e.g. 45m)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thumbCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom Thumbnail URL (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add Video'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final title = titleCtrl.text.trim();
    final url = urlCtrl.text.trim();

    if (title.isEmpty || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and YouTube URL required.')),
        );
      }
      return;
    }

    final ytId = _extractYoutubeId(url);
    if (ytId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste a valid YouTube link.')),
        );
      }
      return;
    }

    final customThumb = thumbCtrl.text.trim();
    final finalThumbnail = customThumb.isNotEmpty
        ? customThumb
        : 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_teacher_id';

    // Add video to course collection
    final videoRef = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('videos')
        .add({
          'title': title,
          'url': url,
          'description': descCtrl.text.trim(),
          'duration': durationCtrl.text.trim(),
          'thumbnail': finalThumbnail,
          'teacherId': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'order': DateTime.now().millisecondsSinceEpoch,
        });

    await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .update({'videoCount': FieldValue.increment(1)});

    // Automatically send notification to students for this new video upload
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Video Uploaded: $title',
        'body': 'Added to course "${widget.courseTitle}". Check it out now!',
        'type': 'course',
        'itemId': widget.courseId,
        'videoId': videoRef.id,
        'targetUserId': widget.classDocId ?? 'all_students',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to send video notification: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video added & students notified!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _addVideoByUrl,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add YouTube Video'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap a video to open the watch page (player, comments, docs).\n'
                'Use the paperclip to attach image/PDF to that video.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Course Playlist',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .doc(widget.courseId)
                    .collection('videos')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'No videos yet.\nClick "Add YouTube Video".',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final videoDocId = docs[i].id;
                      final title = d['title'] ?? 'Video ${i + 1}';
                      final url = d['url'] ?? '';
                      final desc = d['description'] ?? '';
                      final duration = d['duration'] ?? '45m';
                      final thumb = d['thumbnail'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: thumb.isNotEmpty
                                ? Image.network(
                                    thumb,
                                    width: 75,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 75,
                                      height: 45,
                                      color: AppTheme.royalBlue,
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 75,
                                    height: 45,
                                    color: AppTheme.royalBlue,
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            '$duration${desc.isNotEmpty ? ' • $desc' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Add PDF / image',
                                icon: const Icon(Icons.attach_file, size: 20),
                                onPressed: () => _addDocument(videoDocId),
                              ),
                              IconButton(
                                tooltip: 'Delete video',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await docs[i].reference.delete();
                                  await FirebaseFirestore.instance
                                      .collection('courses')
                                      .doc(widget.courseId)
                                      .update({
                                        'videoCount': FieldValue.increment(-1),
                                      });
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openWatchPage(videoDocId, title, url),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
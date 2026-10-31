import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import 'courses_screen.dart';

class VideoWatchScreen extends StatefulWidget {
  final String courseId;
  final String videoId;
  final String title;
  final String youtubeUrl;

  const VideoWatchScreen({
    super.key,
    required this.courseId,
    required this.videoId,
    required this.title,
    required this.youtubeUrl,
  });

  @override
  State<VideoWatchScreen> createState() => _VideoWatchScreenState();
}

class _VideoWatchScreenState extends State<VideoWatchScreen> {
  // YouTube Controller
  YoutubePlayerController? _ytController;

  // Native MP4 Controller (for Android APK / iOS)
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;

  final _commentCtrl = TextEditingController();
  bool _sending = false;

  bool get _isDirectVideo {
    final lower = widget.youtubeUrl.toLowerCase().trim();
    if (_extractId(lower) != null) return false;
    return lower.contains('github.com') ||
        lower.contains('objects.githubusercontent.com') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.contains('.mp4?');
  }

  String? _extractId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.queryParameters['v'] != null) return uri.queryParameters['v'];
    final i = uri.pathSegments.indexWhere((s) => s == 'embed' || s == 'shorts');
    if (i != -1 && i + 1 < uri.pathSegments.length) {
      return uri.pathSegments[i + 1];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initAppropriatePlayer();
  }

  void _initAppropriatePlayer() {
    final url = widget.youtubeUrl.trim();

    if (_isDirectVideo) {
      // On mobile APK, use native VideoPlayerController
      if (!kIsWeb && url.isNotEmpty) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoPlayerController?.play();
            }
          }).catchError((error) {
            debugPrint('VideoPlayer error: $error');
            if (mounted) {
              setState(() {
                _isVideoError = true;
              });
            }
          });
      }
    } else {
      // YouTube Player
      final id = _extractId(url);
      if (id != null) {
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: id,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true, // rel=0: No external recommendations
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    _videoPlayerController?.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  CollectionReference get _commentsRef => FirebaseFirestore.instance
      .collection('courses')
      .doc(widget.courseId)
      .collection('videos')
      .doc(widget.videoId)
      .collection('comments');

  Future<void> _postComment({String? parentId}) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty && parentId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final name = AuthService().currentUserName.isNotEmpty
        ? AuthService().currentUserName
        : (user?.email ?? 'Student');

    setState(() => _sending = true);
    try {
      if (parentId == null) {
        await _commentsRef.add({
          'text': text,
          'userName': name,
          'userId': user?.uid ?? '',
          'replyCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('videos')
            .doc(widget.videoId)
            .set({
          'commentCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _postReply(String parentId, String text) async {
    if (text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final name = AuthService().currentUserName.isNotEmpty
        ? AuthService().currentUserName
        : (user?.email ?? 'Student');

    await _commentsRef.doc(parentId).collection('replies').add({
      'text': text.trim(),
      'userName': name,
      'userId': user?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _commentsRef.doc(parentId).update({
      'replyCount': FieldValue.increment(1),
    });
  }

  /// Student anti-theft watermark (stamps their Name & Roll on the video)
  Widget _buildStudentWatermark() {
    final auth = AuthService();
    final name = auth.currentUserName;
    final roll = auth.currentUserRoll;
    if (name.isEmpty && roll.isEmpty) return const SizedBox.shrink();

    final label = roll.isNotEmpty ? '$name ($roll)' : name;

    return IgnorePointer(
      child: Container(
        alignment: Alignment.topRight,
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Direct Video Player engine (HTML5 on Web with anti-download, Native VideoPlayer on APK)
  Widget _buildDirectVideoPlayer() {
    if (kIsWeb) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black,
                child: HtmlElementView.fromTagName(
                  key: ValueKey(widget.youtubeUrl),
                  tagName: 'video',
                  onElementCreated: (element) {
                    final el = element as dynamic;
                    el.src = widget.youtubeUrl;
                    el.controls = true;
                    el.autoplay = false;
                    el.playsInline = true;
                    // Anti-Theft: disable download button & right click save
                    el.setAttribute('controlsList', 'nodownload');
                    el.setAttribute('disablePictureInPicture', 'true');
                    el.oncontextmenu = (e) => false;

                    el.style.width = '100%';
                    el.style.height = '100%';
                    el.style.objectFit = 'contain';
                    el.style.backgroundColor = '#000000';
                    el.load();
                  },
                ),
              ),
            ),
            _buildStudentWatermark(),
          ],
        ),
      );
    }

    // Android APK / iOS Engine
    if (_isVideoError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 36),
              SizedBox(height: 8),
              Text(
                'Video failed to play on device',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized || _videoPlayerController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: VideoPlayer(_videoPlayerController!),
          ),
          _buildStudentWatermark(),
          // Mobile In-App Controls
          _buildMobileControls(),
        ],
      ),
    );
  }

  Widget _buildMobileControls() {
    final controller = _videoPlayerController;
    if (controller == null) return const SizedBox.shrink();

    final isPlaying = controller.value.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                isPlaying ? controller.pause() : controller.play();
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppTheme.royalBlue,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(controller.value.position),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final isDirect = _isDirectVideo;
    final ytId = _extractId(widget.youtubeUrl);

    Widget playerWidget;
    if (isDirect) {
      playerWidget = _buildDirectVideoPlayer();
    } else if (ytId != null && _ytController != null) {
      playerWidget = AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: YoutubePlayer(controller: _ytController!),
            ),
            _buildStudentWatermark(),
          ],
        ),
      );
    } else {
      playerWidget = Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Unable to load video',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.youtubeUrl.isEmpty ? 'Empty URL' : widget.youtubeUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        playerWidget,
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDirect
                    ? Colors.blue.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDirect ? Colors.blue.shade300 : Colors.red.shade300,
                ),
              ),
              child: Text(
                isDirect ? 'IN-APP SECURE VIDEO' : 'UNLISTED VIDEO',
                style: TextStyle(
                  color: isDirect ? Colors.blue.shade900 : Colors.red.shade900,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        StreamBuilder<QuerySnapshot>(
          stream: _commentsRef.snapshots(),
          builder: (context, snap) {
            final n = snap.data?.docs.length ?? 0;
            return Text(
              '$n comment${n == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Related materials',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        _RelatedDocs(courseId: widget.courseId, videoId: widget.videoId),
        const SizedBox(height: 20),
        const Text(
          'Comments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a comment…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
              onPressed: _sending ? null : () => _postComment(),
              child: const Text('Post'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CommentsList(commentsRef: _commentsRef, onReply: _postReply),
        const SizedBox(height: 28),
        const Text(
          'More from this course',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _SameCourseVideos(
          courseId: widget.courseId,
          currentVideoId: widget.videoId,
        ),
        const SizedBox(height: 28),
        const Text(
          'Other courses',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _OtherCourses(currentCourseId: widget.courseId),
        const SizedBox(height: 40),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: mainColumn,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Playlist',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        _SameCourseVideos(
                          courseId: widget.courseId,
                          currentVideoId: widget.videoId,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Other courses',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        _OtherCourses(currentCourseId: widget.courseId),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: mainColumn,
            ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  final CollectionReference commentsRef;
  final Future<void> Function(String parentId, String text) onReply;

  const _CommentsList({required this.commentsRef, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No comments yet. Be the first.',
            style: TextStyle(color: Colors.black45),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final replyCount = d['replyCount'] ?? 0;
            return _CommentTile(
              commentId: doc.id,
              userName: d['userName'] ?? 'User',
              text: d['text'] ?? '',
              replyCount: replyCount is int ? replyCount : 0,
              commentsRef: commentsRef,
              onReply: onReply,
            );
          }).toList(),
        );
      },
    );
  }
}

class _CommentTile extends StatefulWidget {
  final String commentId;
  final String userName;
  final String text;
  final int replyCount;
  final CollectionReference commentsRef;
  final Future<void> Function(String parentId, String text) onReply;

  const _CommentTile({
    required this.commentId,
    required this.userName,
    required this.text,
    required this.replyCount,
    required this.commentsRef,
    required this.onReply,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;
  bool _showReplyBox = false;
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.royalBlue.withOpacity(0.15),
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.text),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _showReplyBox = !_showReplyBox),
                  child: const Text('Reply', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => setState(() => _showReplies = !_showReplies),
                  child: Text(
                    '${widget.replyCount} repl${widget.replyCount == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_showReplyBox) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Write a reply…',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.royalBlue),
                    onPressed: () async {
                      await widget.onReply(widget.commentId, _replyCtrl.text);
                      _replyCtrl.clear();
                      setState(() {
                        _showReplyBox = false;
                        _showReplies = true;
                      });
                    },
                  ),
                ],
              ),
            ],
            if (_showReplies)
              StreamBuilder<QuerySnapshot>(
                stream: widget.commentsRef
                    .doc(widget.commentId)
                    .collection('replies')
                    .orderBy('createdAt')
                    .snapshots(),
                builder: (context, snap) {
                  final replies = snap.data?.docs ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(left: 24, top: 4),
                    child: Column(
                      children: replies.map((r) {
                        final rd = r.data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            rd['userName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(rd['text'] ?? ''),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RelatedDocs extends StatelessWidget {
  final String courseId;
  final String videoId;
  const _RelatedDocs({required this.courseId, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('videos')
          .doc(videoId)
          .collection('documents')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No related documents.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final isPdf = d['type'] == 'pdf';
            return ListTile(
              dense: true,
              leading: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.image,
                color: isPdf ? Colors.red : AppTheme.royalBlue,
              ),
              title: Text(
                d['name'] ?? 'File',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () {
                      if (d['base64'] == null) return;
                      viewBase64File(
                        context: context,
                        base64Data: d['base64'],
                        type: d['type'] ?? 'image',
                        fileName: d['name'] ?? 'file',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: () {
                      if (d['base64'] == null) return;
                      downloadBase64File(
                        context: context,
                        base64Data: d['base64'],
                        fileName: d['name'] ?? 'file',
                        type: d['type'] ?? 'image',
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SameCourseVideos extends StatelessWidget {
  final String courseId;
  final String currentVideoId;
  const _SameCourseVideos({
    required this.courseId,
    required this.currentVideoId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('videos')
          .orderBy('order')
          .snapshots(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? [])
            .where((d) => d.id != currentVideoId)
            .toList();
        if (docs.isEmpty) {
          return const Text(
            'No other videos in this course.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          );
        }
        return Column(
          children: docs.map((v) {
            final d = v.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
                color: AppTheme.royalBlue,
              ),
              title: Text(
                d['title'] ?? 'Video',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(d['duration']?.toString() ?? ''),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoWatchScreen(
                      courseId: courseId,
                      videoId: v.id,
                      title: d['title'] ?? 'Video',
                      youtubeUrl: d['url'] ?? '',
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _OtherCourses extends StatelessWidget {
  final String currentCourseId;
  const _OtherCourses({required this.currentCourseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .limit(15)
          .snapshots(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? [])
            .where((d) => d.id != currentCourseId)
            .toList();
        if (docs.isEmpty) {
          return const Text(
            'No other courses.',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          );
        }
        return Column(
          children: docs.map((c) {
            final d = c.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(
                d['title'] ?? 'Course',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${d['videoCount'] ?? 0} videos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoursesScreen()),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
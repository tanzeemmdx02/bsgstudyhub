import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../main.dart';
import '../screens/student_login_screen.dart';
import '../services/auth_service.dart';
import '../services/bkash_payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_stub.if_not_web.dart'
    if (dart.library.html) '../utils/url_launcher_web.dart' as web_launcher;
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/bkash_payment_modal.dart';

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  String? _activeLiveId;
  Map<String, dynamic>? _activeLiveClass;
  YoutubePlayerController? _ytController;
  final TextEditingController _chatCtrl = TextEditingController();

  String? _extractYtId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.queryParameters['v'] != null) return uri.queryParameters['v'];
    if (uri.pathSegments.contains('live')) {
      final i = uri.pathSegments.indexOf('live');
      if (i + 1 < uri.pathSegments.length) return uri.pathSegments[i + 1];
    }
    return null;
  }

  Future<void> _selectLiveClass(String id, Map<String, dynamic> data) async {
    final isFree = data['isFree'] ?? true;
    final price = (data['price'] ?? 0.0).toDouble();

    if (!isFree && price > 0) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first to access paid live classes.')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
        );
        return;
      }

      final alreadyUnlocked = await BkashPaymentService.hasPurchasedItem(id);

      if (!alreadyUnlocked) {
        if (!context.mounted) return;

        final paidSuccess = await BkashPaymentModal.show(
          context,
          itemId: id,
          itemType: 'live_class',
          itemTitle: data['className'] ?? 'Paid Live Class',
          price: price,
        );

        if (paidSuccess != true) {
          return;
        }
      }
    }

    final platform = data['platform'] ?? 'youtube';
    if (platform == 'meet') {
      final meetUrl = data['meetUrl'] ?? '';
      if (meetUrl.isNotEmpty) {
        if (kIsWeb) {
          web_launcher.openExternalUrl(meetUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Meet Link: $meetUrl')),
          );
        }
      }
      return;
    }

    final ytUrl = data['youtubeUrl'] ?? '';
    final ytId = _extractYtId(ytUrl);
    if (ytId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube Live URL.')),
      );
      return;
    }

    _ytController?.close();
    setState(() {
      _activeLiveId = id;
      _activeLiveClass = data;
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    });
  }

  Future<void> _sendChatMessage() async {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty || _activeLiveId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final userName = AuthService().currentUserName.isNotEmpty
        ? AuthService().currentUserName
        : (user?.email?.split('@').first ?? 'Student');

    await FirebaseFirestore.instance
        .collection('live_classes')
        .doc(_activeLiveId)
        .collection('chats')
        .add({
      'senderName': userName,
      'senderId': user?.uid ?? '',
      'message': msg,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _chatCtrl.clear();
  }

  @override
  void dispose() {
    _ytController?.close();
    _chatCtrl.dispose();
    super.dispose();
  }

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
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Interactive Classroom',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Join live lectures by faculty or view scheduled sessions.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),

                if (_activeLiveClass != null) ...[
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _ytController?.close();
                          setState(() {
                            _activeLiveId = null;
                            _activeLiveClass = null;
                            _ytController = null;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          _activeLiveClass!['className'] ?? 'Live Stream',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.academicGold, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _ytController != null
                          ? YoutubePlayer(controller: _ytController!)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chat Module for active live stream
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: AppTheme.royalBlue,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Live Classroom Discussion',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          SizedBox(
                            height: 220,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('live_classes')
                                  .doc(_activeLiveId)
                                  .collection('chats')
                                  .orderBy('createdAt', descending: false)
                                  .snapshots(),
                              builder: (context, snap) {
                                final chats = snap.data?.docs ?? [];
                                if (chats.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No messages yet. Say hello to the class!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  itemCount: chats.length,
                                  itemBuilder: (ctx, i) {
                                    final data = chats[i].data()
                                        as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${data['senderName'] ?? 'Student'}: ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.royalBlue,
                                              ),
                                            ),
                                            TextSpan(
                                              text: data['message'] ?? '',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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
                                  onSubmitted: (_) => _sendChatMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.royalBlue,
                                ),
                                icon: const Icon(Icons.send, size: 18),
                                onPressed: _sendChatMessage,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Grid List of Live Classes
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('live_classes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No live classes or meet sessions currently scheduled.',
                              ),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.25,
                        ),
                        itemBuilder: (context, i) {
                          final docId = docs[i].id;
                          final d = docs[i].data() as Map<String, dynamic>;
                          final isLive = d['status'] == 'live';
                          final isFree = d['isFree'] ?? true;
                          final price = d['price'] ?? 0;
                          final platform = d['platform'] ?? 'youtube';

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              onTap: () => _selectLiveClass(docId, d),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    color: isLive
                                        ? AppTheme.accentRose
                                        : AppTheme.royalBlue,
                                    child: Row(
                                      children: [
                                        Icon(
                                          platform == 'youtube'
                                              ? Icons.smart_display
                                              : Icons.video_call,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isLive ? 'LIVE NOW' : 'UPCOMING',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isFree
                                                ? Colors.green
                                                : Colors.deepOrange,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isFree ? 'FREE' : '৳$price',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d['className'] ?? 'Live Class',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Class: ${d['class'] ?? 'General'} • Subj: ${d['subject'] ?? 'General'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.royalBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
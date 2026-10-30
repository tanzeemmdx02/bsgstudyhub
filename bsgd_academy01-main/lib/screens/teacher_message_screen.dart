import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class TeacherTheme {
  static const Color primaryNavy = Color(0xFF1E293B);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color incomingBubble = Color(0xFFE2E8F0);
}

class TeacherMessageScreen extends StatefulWidget {
  const TeacherMessageScreen({super.key});

  @override
  State<TeacherMessageScreen> createState() => _TeacherMessageScreenState();
}

class _TeacherMessageScreenState extends State<TeacherMessageScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;

  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _searchQuery = '';
  bool _sending = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastMessages = [];
  String? _lastChatId;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    list.sort((a, b) {
      final ta = a.data()['createdAt'];
      final tb = b.data()['createdAt'];
      if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
      final ma = a.data()['createdAtMs'] as int? ?? 0;
      final mb = b.data()['createdAtMs'] as int? ?? 0;
      if (ma != 0 || mb != 0) return ma.compareTo(mb);
      return a.id.compareTo(b.id);
    });
    return list;
  }

  Future<void> _markMessagesAsRead(String chatId, String myUid) async {
    final col = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final snapshot = await col.get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['senderId'] != myUid && data['status'] != 'read') {
        doc.reference.update({'status': 'read'});
      }
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _selectedStudentId == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    final targetId = _selectedStudentId!;
    final teacherName = AuthService().currentUserName.isNotEmpty
        ? AuthService().currentUserName
        : 'Teacher';

    final ids = [currentUid, targetId]..sort();
    final chatId = ids.join('_');
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    setState(() => _sending = true);

    try {
      await chatRef.set({
        'participants': [currentUid, targetId],
        'teacherId': currentUid,
        'studentId': targetId,
        'studentName': _selectedStudentName ?? 'Student',
        'teacherName': teacherName,
        'lastMessage': text,
        'lastAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        'text': text,
        'senderId': currentUid,
        'senderRole': 'teacher',
        'status': 'delivered',
        'reaction': null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) _msgCtrl.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (isMobile) {
      if (_selectedStudentId != null) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: TeacherTheme.surface,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => setState(() {
                      _selectedStudentId = null;
                      _selectedStudentName = null;
                      _lastMessages = [];
                      _lastChatId = null;
                    }),
                  ),
                  Text(_selectedStudentName ?? 'Student',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _buildChatArea(teacherId)),
          ],
        );
      }
      return _buildStudentSidebar(teacherId);
    }

    return Container(
      color: TeacherTheme.background,
      child: Row(
        children: [
          Container(
              width: 320,
              color: TeacherTheme.surface,
              child: _buildStudentSidebar(teacherId)),
          Expanded(
              child: _selectedStudentId == null
                  ? const Center(child: Text('Select student to chat'))
                  : _buildChatArea(teacherId)),
        ],
      ),
    );
  }

  Widget _buildStudentSidebar(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, studentSnap) {
        final studentDocs = studentSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: teacherId)
              .snapshots(),
          builder: (context, chatSnap) {
            final chatMap = <String, Map<String, dynamic>>{};
            for (final c in (chatSnap.data?.docs ?? [])) {
              final data = c.data() as Map<String, dynamic>;
              final participants = (data['participants'] as List?)
                      ?.whereType<String>()
                      .toList() ??
                  <String>[];
              final otherId = participants.firstWhere((id) => id != teacherId,
                  orElse: () => '');
              if (otherId.isNotEmpty) {
                chatMap[otherId] = data;
              }
            }

            final filtered = studentDocs.where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final name = (d['name'] ?? 'Student').toString().toLowerCase();
              final roll = (d['roll'] ?? '').toString().toLowerCase();
              if (_searchQuery.isEmpty) return true;
              return name.contains(_searchQuery) || roll.contains(_searchQuery);
            }).toList();

            filtered.sort((a, b) {
              final timeA =
                  (chatMap[a.id]?['lastAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0;
              final timeB =
                  (chatMap[b.id]?['lastAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0;
              return timeB.compareTo(timeA);
            });

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search student...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: TeacherTheme.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      isDense: true,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (ctx, i) {
                      final doc = filtered[i];
                      final d = doc.data() as Map<String, dynamic>;
                      final sid = doc.id;
                      final sname = d['name'] ?? 'Student';
                      final isSelected = sid == _selectedStudentId;
                      final chatData = chatMap[sid];
                      final lastMessage = chatData?['lastMessage'] as String?;

                      final chatIdsList = [teacherId, sid]..sort();
                      final computedChatId = chatIdsList.join('_');

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(computedChatId)
                            .collection('messages')
                            .snapshots(),
                        builder: (context, unreadSnap) {
                          int unreadCount = 0;
                          if (unreadSnap.hasData) {
                            unreadCount = unreadSnap.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['senderId'] != teacherId &&
                                  data['status'] != 'read';
                            }).length;
                          }

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                TeacherTheme.primaryNavy.withOpacity(0.08),
                            leading: CircleAvatar(
                              backgroundColor: TeacherTheme.primaryNavy,
                              child: Text(sname[0],
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(sname,
                                style: TextStyle(
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w900
                                        : FontWeight.bold)),
                            subtitle: Text(
                              lastMessage ?? 'Student',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: unreadCount > 0
                                    ? TeacherTheme.textDark
                                    : TeacherTheme.textMuted,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: TeacherTheme.emeraldAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedStudentId = sid;
                                _selectedStudentName = sname;
                                _lastMessages = [];
                                _lastChatId = null;
                              });
                              _markMessagesAsRead(computedChatId, teacherId);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageList(String myUid, String chatId,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> messages) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final doc = messages[i];
        final m = doc.data();
        final isMe = m['senderId'] == myUid;
        final text = '${m['text'] ?? ''}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: TeacherTheme.primaryNavy.withOpacity(0.15),
                  child: Text(
                    (_selectedStudentName ?? 'S')[0],
                    style: const TextStyle(
                        fontSize: 10, color: TeacherTheme.primaryNavy),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? TeacherTheme.primaryNavy
                        : TeacherTheme.incomingBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : TeacherTheme.textDark,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatArea(String teacherId) {
    final ids = [teacherId, _selectedStudentId!]..sort();
    final chatId = ids.join('_');

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: ValueKey('msg_$chatId'),
            stream: _messagesStream(chatId),
            builder: (context, snap) {
              if (snap.hasData) {
                _lastMessages = _sortMessages(snap.data!.docs);
                _lastChatId = chatId;
                _markMessagesAsRead(chatId, teacherId);
              }
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> messages =
                  _lastChatId == chatId
                      ? _lastMessages
                      : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (messages.isEmpty) {
                return const Center(child: Text('Start conversation'));
              }
              _scrollToBottom();
              return _buildMessageList(teacherId, chatId, messages);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type message...',
                    filled: true,
                    fillColor: TeacherTheme.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: TeacherTheme.primaryNavy),
                  onPressed: _send),
            ],
          ),
        ),
      ],
    );
  }
}
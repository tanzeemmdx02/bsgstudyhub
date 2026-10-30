import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class StudentTheme {
  static const Color primary = Color(0xFF5B67EA);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF8A94A6);
  static const Color incomingBubble = Color(0xFFF1F3F9);
}

String authIdOf(Map<String, dynamic> data, String docId) {
  final u = (data['uid'] ?? '').toString().trim();
  return u.isNotEmpty ? u : docId;
}

class StudentMessageScreen extends StatefulWidget {
  const StudentMessageScreen({super.key});

  @override
  State<StudentMessageScreen> createState() => _StudentMessageScreenState();
}

class _StudentMessageScreenState extends State<StudentMessageScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedTeacherId;
  String? _selectedTeacherName;

  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _searchQuery = '';
  bool _sending = false;

  final List<_TeacherContact> _teachers = [];
  bool _teachersLoading = true;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastMessages = [];
  String? _lastChatId;

  StreamSubscription? _teachersSub;
  StreamSubscription? _usersSub;

  @override
  void initState() {
    super.initState();
    _listenTeachers();
  }

  @override
  void dispose() {
    _teachersSub?.cancel();
    _usersSub?.cancel();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _listenTeachers() {
    final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _teachersSub = FirebaseFirestore.instance
        .collection('teachers')
        .snapshots()
        .listen((snap) {
      _mergeTeachers(snap.docs, studentId);
    }, onError: (_) {
      if (mounted) setState(() => _teachersLoading = false);
    });

    _usersSub = FirebaseFirestore.instance.collection('users').snapshots().listen(
      (snap) {
        final onlyTeachers = snap.docs.where((doc) {
          final d = doc.data();
          final role = (d['role'] ?? '').toString().toLowerCase();
          return role.contains('teacher') ||
              role.contains('admin') ||
              role.contains('instructor');
        }).toList();
        _mergeTeachers(onlyTeachers, studentId);
      },
      onError: (_) {},
    );
  }

  void _mergeTeachers(List<QueryDocumentSnapshot> docs, String studentId) {
    final map = <String, _TeacherContact>{};
    for (final t in _teachers) {
      map[t.id] = t;
    }
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final id = authIdOf(d, doc.id);
      if (id.isEmpty || id == studentId) continue;
      final name = (d['name'] ?? d['fullName'] ?? d['userName'] ?? 'Teacher').toString();
      map[id] = _TeacherContact(id: id, name: name);
    }

    if (!mounted) return;
    setState(() {
      _teachers
        ..clear()
        ..addAll(map.values);
      _teachersLoading = false;
    });
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
    if (text.isEmpty || _selectedTeacherId == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    final targetId = _selectedTeacherId!;
    final studentName = AuthService().currentUserName.isNotEmpty
        ? AuthService().currentUserName
        : 'Student';

    final ids = [targetId, currentUid]..sort();
    final chatId = ids.join('_');
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    setState(() => _sending = true);

    try {
      await chatRef.set({
        'participants': [targetId, currentUid],
        'teacherId': targetId,
        'studentId': currentUid,
        'studentName': studentName,
        'teacherName': _selectedTeacherName ?? 'Teacher',
        'lastMessage': text,
        'lastAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        'text': text,
        'senderId': currentUid,
        'senderRole': 'student',
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
    super.build(context);
    final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    // Wrapped in Material to satisfy TextField requirement when embedded in dashboard
    return Material(
      color: StudentTheme.background,
      child: Builder(
        builder: (context) {
          if (isMobile) {
            if (_selectedTeacherId != null) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: StudentTheme.surface,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          onPressed: () => setState(() {
                            _selectedTeacherId = null;
                            _selectedTeacherName = null;
                            _lastMessages = [];
                            _lastChatId = null;
                          }),
                        ),
                        Text(_selectedTeacherName ?? 'Teacher',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(child: _buildChatArea(studentId)),
                ],
              );
            }
            return _buildTeacherSidebar(studentId);
          }

          return Row(
            children: [
              Container(
                  width: 320,
                  color: StudentTheme.surface,
                  child: _buildTeacherSidebar(studentId)),
              Expanded(
                  child: _selectedTeacherId == null
                      ? const Center(child: Text('Select a teacher to chat'))
                      : _buildChatArea(studentId)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeacherSidebar(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: studentId)
          .snapshots(),
      builder: (context, chatSnap) {
        final chatMap = <String, Map<String, dynamic>>{};

        for (final c in (chatSnap.data?.docs ?? [])) {
          final data = c.data() as Map<String, dynamic>;
          final participants = (data['participants'] as List?)
                  ?.whereType<String>()
                  .toList() ??
              <String>[];
          final otherId =
              participants.firstWhere((id) => id != studentId, orElse: () => '');
          if (otherId.isNotEmpty) {
            chatMap[otherId] = data;
          }
        }

        final filtered = _teachers
            .where((t) => t.name.toLowerCase().contains(_searchQuery))
            .toList();

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
                  hintText: 'Search teacher...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: StudentTheme.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  isDense: true,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: _teachersLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: StudentTheme.primary))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (ctx, i) {
                        final t = filtered[i];
                        final isSelected = t.id == _selectedTeacherId;
                        final chatData = chatMap[t.id];
                        final lastMessage = chatData?['lastMessage'] as String?;

                        final chatIdsList = [t.id, studentId]..sort();
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
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                return data['senderId'] != studentId &&
                                    data['status'] != 'read';
                              }).length;
                            }

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: StudentTheme.primaryLight,
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? StudentTheme.primary
                                    : StudentTheme.primaryLight,
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : StudentTheme.primary,
                                child: Text(t.name[0].toUpperCase()),
                              ),
                              title: Text(t.name,
                                  style: TextStyle(
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w900
                                          : FontWeight.w600)),
                              subtitle: Text(
                                lastMessage ?? 'Instructor',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unreadCount > 0
                                      ? StudentTheme.textDark
                                      : StudentTheme.textMuted,
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
                                        color: StudentTheme.primary,
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
                                  _selectedTeacherId = t.id;
                                  _selectedTeacherName = t.name;
                                  _lastMessages = [];
                                  _lastChatId = null;
                                });
                                _markMessagesAsRead(computedChatId, studentId);
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
                  backgroundColor: StudentTheme.primaryLight,
                  child: Text(
                    (_selectedTeacherName ?? 'T')[0],
                    style: const TextStyle(
                        fontSize: 10, color: StudentTheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? StudentTheme.primary
                        : StudentTheme.incomingBubble,
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
                      color: isMe ? Colors.white : StudentTheme.textDark,
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

  Widget _buildChatArea(String studentId) {
    final ids = [_selectedTeacherId!, studentId]..sort();
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
                _markMessagesAsRead(chatId, studentId);
              }
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> messages =
                  _lastChatId == chatId
                      ? _lastMessages
                      : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (messages.isEmpty) {
                return const Center(child: Text('Start conversation'));
              }
              _scrollToBottom();
              return _buildMessageList(studentId, chatId, messages);
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
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: StudentTheme.surface,
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
                      color: StudentTheme.primary),
                  onPressed: _send),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeacherContact {
  final String id;
  final String name;
  _TeacherContact({required this.id, required this.name});
}
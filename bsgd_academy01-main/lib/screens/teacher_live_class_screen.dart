import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_stub.if_not_web.dart'
    if (dart.library.html) '../utils/url_launcher_web.dart' as web_launcher;

class TeacherLiveClassScreen extends StatefulWidget {
  const TeacherLiveClassScreen({super.key});

  @override
  State<TeacherLiveClassScreen> createState() => _TeacherLiveClassScreenState();
}

class _TeacherLiveClassScreenState extends State<TeacherLiveClassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _previewLiveId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _platform => _tab.index == 0 ? 'youtube' : 'meet';

  Future<void> _openGoToLiveForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoToLiveSheet(platform: _platform),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _platform == 'youtube'
                ? 'YouTube Live saved & students notified.'
                : 'Google Meet session saved & students notified.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_previewLiveId != null) {
      return _LivePreviewPlayer(
        liveId: _previewLiveId!,
        onBack: () => setState(() => _previewLiveId = null),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Classes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'YouTube Live or Google Meet — pick a tab',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openGoToLiveForm,
                icon: const Icon(Icons.podcasts, size: 18),
                label: const Text(
                  'Go to Live',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_display, size: 18),
                      SizedBox(width: 6),
                      Text('YouTube Live'),
                    ],
                  ),
                ),
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_call, size: 18),
                      SizedBox(width: 6),
                      Text('Google Meet'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.royalBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _platform == 'youtube'
                  ? 'Start an Unlisted live on YouTube → copy link → Go to Live → paste URL. Plays inside the app.'
                  : 'Create a Google Meet → copy meeting link → Go to Live → paste URL. Opens Meet for teacher & students.',
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('live_classes')
                .where('teacherId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              List<QueryDocumentSnapshot> docs = [];
              if (snap.hasData) {
                docs = snap.data!.docs.where((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final p = m['platform'] ?? 'youtube';
                  return p == _platform;
                }).toList()
                  ..sort((a, b) {
                    final ta = (a.data() as Map)['createdAt'];
                    final tb = (b.data() as Map)['createdAt'];
                    if (ta is Timestamp && tb is Timestamp) {
                      return tb.compareTo(ta);
                    }
                    return 0;
                  });
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return _LiveGrid(
                docs: docs,
                platform: _platform,
                onPlay: (id, data) {
                  if (_platform == 'youtube') {
                    setState(() => _previewLiveId = id);
                  } else {
                    final url = '${data['meetUrl'] ?? data['youtubeUrl'] ?? ''}';
                    if (url.isNotEmpty) {
                      if (kIsWeb) {
                        web_launcher.openExternalUrl(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Meet Link: $url')),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LiveGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String platform;
  final void Function(String id, Map<String, dynamic> data) onPlay;

  const _LiveGrid({
    required this.docs,
    required this.platform,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              platform == 'youtube' ? Icons.smart_display : Icons.video_call,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              platform == 'youtube'
                  ? 'No YouTube Live sessions yet'
                  : 'No Google Meet sessions yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap “Go to Live” to create one',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth > 1100 ? 3 : c.maxWidth > 700 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: cross == 1 ? 1.5 : 1.32,
          ),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return _LiveCard(
              data: d,
              platform: platform,
              onPlay: () => onPlay(doc.id, d),
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete session?'),
                    content: Text(d['className'] ?? ''),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentRose,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await doc.reference.delete();
                }
              },
              onStatus: (status) async {
                await doc.reference.update({
                  'status': status,
                  if (status == 'live')
                    'startedAt': FieldValue.serverTimestamp(),
                  if (status == 'ended')
                    'endedAt': FieldValue.serverTimestamp(),
                });
              },
            );
          },
        );
      },
    );
  }
}

class _GoToLiveSheet extends StatefulWidget {
  final String platform;
  const _GoToLiveSheet({required this.platform});

  @override
  State<_GoToLiveSheet> createState() => _GoToLiveSheetState();
}

class _GoToLiveSheetState extends State<_GoToLiveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  String? _selectedClass;
  String? _selectedGroup;
  String? _selectedSubDept;
  String? _matchedClassDocId;
  String? _selectedSubjectName;

  bool _allSubjects = false;
  bool _unlimited = true;
  bool _isFree = true;
  bool _saving = false;

  bool get _isYoutube => widget.platform == 'youtube';

  @override
  void dispose() {
    _descCtrl.dispose();
    _limitCtrl.dispose();
    _priceCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  bool _validUrl(String url) {
    final u = url.trim().toLowerCase();
    if (_isYoutube) {
      return u.contains('youtube.com') || u.contains('youtu.be');
    }
    return u.contains('meet.google.com');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null ||
        _selectedGroup == null ||
        _selectedSubDept == null ||
        (_matchedClassDocId == null && !_allSubjects)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Class, Department, Sub-Department, and Subject.')),
      );
      return;
    }

    double parsedPrice = 0.0;
    if (!_isFree) {
      parsedPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      if (parsedPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid live class price greater than 0.')),
        );
        return;
      }
    }

    final url = _urlCtrl.text.trim();
    if (!_validUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isYoutube
                ? 'Enter a valid YouTube Live URL'
                : 'Enter a valid Google Meet link (meet.google.com/...)',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      await FirebaseFirestore.instance.collection('live_classes').add({
        'platform': widget.platform,
        'description': _descCtrl.text.trim(),
        'isFree': _isFree,
        'price': _isFree ? 0.0 : parsedPrice,
        'className': _selectedClass,
        'class': _selectedClass,
        'department': _selectedGroup,
        'group': _selectedGroup,
        'subDepartment': _selectedSubDept,
        'classDocId': _matchedClassDocId,
        'subject': _allSubjects ? 'All Subjects' : _selectedSubjectName,
        'allSubjects': _allSubjects,
        'studentLimit': _unlimited ? null : int.tryParse(_limitCtrl.text.trim()),
        'unlimited': _unlimited,
        'youtubeUrl': _isYoutube ? url : null,
        'meetUrl': _isYoutube ? null : url,
        'teacherId': uid,
        'teacherName': AuthService().currentUserName,
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Live Class Started / Scheduled! 🔴',
        'body': '$_selectedClass (${_allSubjects ? "All Subjects" : _selectedSubjectName}): ${_descCtrl.text.trim()}',
        'type': 'course',
        'targetUserId': _matchedClassDocId ?? 'all_students',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildClassClassifierDropdowns() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No classes found in Daily Attendance module.',
            style: TextStyle(fontSize: 12, color: Colors.red),
          );
        }

        final List<String> classesList = docs
            .map((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();

        if (_selectedClass != null && !classesList.contains(_selectedClass)) {
          _selectedClass = null;
        }

        List<String> groupsList = [];
        if (_selectedClass != null) {
          groupsList = docs
              .where((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() == _selectedClass)
              .map((d) => (d.data() as Map<String, dynamic>)['department']?.toString().trim() ?? '')
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList();
        }

        if (_selectedGroup != null && !groupsList.contains(_selectedGroup)) {
          _selectedGroup = null;
        }

        List<String> subDeptsList = [];
        if (_selectedClass != null && _selectedGroup != null) {
          subDeptsList = docs
              .where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['name']?.toString().trim() == _selectedClass &&
                    data['department']?.toString().trim() == _selectedGroup;
              })
              .map((d) => (d.data() as Map<String, dynamic>)['subDepartment']?.toString().trim() ?? 'General')
              .where((sd) => sd.isNotEmpty)
              .toSet()
              .toList();
        }

        if (_selectedSubDept != null && !subDeptsList.contains(_selectedSubDept)) {
          _selectedSubDept = null;
        }

        List<QueryDocumentSnapshot> matchingClassDocs = [];
        if (_selectedClass != null && _selectedGroup != null && _selectedSubDept != null) {
          matchingClassDocs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final sd = data['subDepartment']?.toString().trim() ?? 'General';
            return data['name']?.toString().trim() == _selectedClass &&
                data['department']?.toString().trim() == _selectedGroup &&
                sd == _selectedSubDept;
          }).toList();
        }

        if (_matchedClassDocId != null &&
            !matchingClassDocs.any((d) => d.id == _matchedClassDocId)) {
          _matchedClassDocId = null;
          _selectedSubjectName = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClass,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder(), isDense: true),
              items: classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClass = val;
                  _selectedGroup = null;
                  _selectedSubDept = null;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Department / Group *', border: OutlineInputBorder(), isDense: true),
              items: groupsList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: _selectedClass == null ? null : (val) {
                setState(() {
                  _selectedGroup = val;
                  _selectedSubDept = null;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSubDept,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sub-Department / Section *', border: OutlineInputBorder(), isDense: true),
              items: subDeptsList.map((sd) => DropdownMenuItem(value: sd, child: Text(sd))).toList(),
              onChanged: _selectedGroup == null ? null : (val) {
                setState(() {
                  _selectedSubDept = val;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _matchedClassDocId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder(), isDense: true),
                    items: matchingClassDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final subj = data['subject']?.toString().trim() ?? 'Subject';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(subj),
                      );
                    }).toList(),
                    onChanged: (_selectedSubDept == null || _allSubjects) ? null : (docId) {
                      if (docId != null) {
                        final matchDoc = matchingClassDocs.firstWhere((d) => d.id == docId);
                        final data = matchDoc.data() as Map<String, dynamic>;
                        setState(() {
                          _matchedClassDocId = docId;
                          _selectedSubjectName = data['subject']?.toString().trim();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilterChip(
                    label: const Text('All subjects'),
                    selected: _allSubjects,
                    onSelected: (v) => setState(() {
                      _allSubjects = v;
                      if (v) {
                        _matchedClassDocId = null;
                        _selectedSubjectName = 'All Subjects';
                      }
                    }),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final accent = _isYoutube ? AppTheme.accentRose : const Color(0xFF00897B);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isYoutube ? Icons.smart_display : Icons.video_call,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isYoutube ? 'Go to Live · YouTube' : 'Go to Live · Meet',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _isYoutube
                            ? 'Unlisted YouTube Live URL'
                            : 'Google Meet meeting link',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
                children: [
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'What is this class about?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
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
                                selected: _isFree,
                                onSelected: (val) => setState(() => _isFree = true),
                                selectedColor: Colors.green.shade100,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Paid'),
                                selected: !_isFree,
                                onSelected: (val) => setState(() => _isFree = false),
                                selectedColor: Colors.deepOrange.shade100,
                              ),
                            ),
                          ],
                        ),
                        if (!_isFree) ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            decoration: const InputDecoration(
                              labelText: 'Price (৳) *',
                              hintText: 'e.g. 200',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) {
                              if (_isFree) return null;
                              if (v == null || v.trim().isEmpty) return 'Enter price';
                              if ((double.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Class Classification:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(height: 8),
                  _buildClassClassifierDropdowns(),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _limitCtrl,
                          enabled: !_unlimited,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Student Limit',
                            hintText: _unlimited ? 'Unlimited' : 'e.g. 40',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (_unlimited) return null;
                            if (v == null || v.isEmpty) return 'Required';
                            if (int.tryParse(v) == null) return 'Number only';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilterChip(
                          label: const Text('Unlimited'),
                          selected: _unlimited,
                          onSelected: (v) => setState(() {
                            _unlimited = v;
                            if (v) _limitCtrl.clear();
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      labelText: _isYoutube ? 'YouTube Live URL *' : 'Google Meet URL *',
                      hintText: _isYoutube
                          ? 'https://youtube.com/live/...'
                          : 'https://meet.google.com/xxx-xxxx-xxx',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'URL is required' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.rocket_launch),
                      label: Text(
                        _saving ? 'Saving…' : 'Save Live Class',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String platform;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final void Function(String status) onStatus;

  const _LiveCard({
    required this.data,
    required this.platform,
    required this.onPlay,
    required this.onDelete,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${data['status'] ?? 'upcoming'}';
    final isLive = status == 'live';
    final color = isLive
        ? AppTheme.accentRose
        : status == 'ended'
            ? Colors.grey
            : AppTheme.royalBlue;
    final limit = data['unlimited'] == true
        ? 'Unlimited'
        : '${data['studentLimit'] ?? '—'} seats';
    final isFree = data['isFree'] ?? true;
    final price = data['price'] ?? 0;

    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.95), AppTheme.primaryNavy],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLive
                          ? 'LIVE'
                          : status == 'ended'
                              ? 'ENDED'
                              : 'UPCOMING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    platform == 'youtube'
                        ? Icons.smart_display
                        : Icons.video_call,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isFree ? Colors.green : Colors.deepOrange),
                      borderRadius: BorderRadius.circular(4),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['className'] ?? 'Live',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(data['subject'] ?? '—'),
                        _chip(data['department'] ?? '—'),
                        _chip(limit),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Row(
                children: [
                  if (status != 'live')
                    TextButton(
                      onPressed: () => onStatus('live'),
                      child: const Text('Mark Live',
                          style: TextStyle(fontSize: 11)),
                    ),
                  if (status == 'live')
                    TextButton(
                      onPressed: () => onStatus('ended'),
                      child:
                          const Text('End', style: TextStyle(fontSize: 11)),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      platform == 'youtube'
                          ? Icons.play_arrow
                          : Icons.video_call,
                      size: 20,
                    ),
                    onPressed: onPlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.royalBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(t,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _LivePreviewPlayer extends StatefulWidget {
  final String liveId;
  final VoidCallback onBack;
  const _LivePreviewPlayer({required this.liveId, required this.onBack});

  @override
  State<_LivePreviewPlayer> createState() => _LivePreviewPlayerState();
}

class _LivePreviewPlayerState extends State<_LivePreviewPlayer> {
  YoutubePlayerController? _controller;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('live_classes')
        .doc(widget.liveId)
        .get();
    if (!doc.exists || !mounted) return;
    final d = doc.data()!;
    final url = '${d['youtubeUrl'] ?? ''}';
    final id = _ytId(url);
    setState(() {
      _data = d;
      if (id != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: id,
          autoPlay: true,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
      }
    });
  }

  String? _ytId(String url) {
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

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  d?['className'] ?? 'Live',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (_controller != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: _controller!),
                  ),
                )
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
              const SizedBox(height: 16),
              if (d != null)
                Text(d['description'] ?? '',
                    style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
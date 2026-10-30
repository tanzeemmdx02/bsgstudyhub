import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/ai_mcq_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'create_mcq_screen.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).cardColor,
            elevation: 1,
            child: TabBar(
              controller: _tabs,
              labelColor: AppTheme.royalBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.royalBlue,
              tabs: const [
                Tab(text: 'MCQ Exams'),
                Tab(text: 'Written Exams'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _McqExamList(
                  onCreate: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateMcqExamForm(),
                      ),
                    );
                  },
                ),
                const _WrittenPlaceholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _McqExamList extends StatefulWidget {
  final VoidCallback onCreate;

  const _McqExamList({required this.onCreate});

  @override
  State<_McqExamList> createState() => _McqExamListState();
}

class _McqExamListState extends State<_McqExamList> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteExamWithConfirm(DocumentReference ref, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$title"?'),
        content: const Text(
          'This will permanently delete this exam and all its questions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'MCQ Examinations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
              ),
              onPressed: widget.onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create MCQ Exam'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search exams by title or subject...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('exams')
              .where('type', isEqualTo: 'mcq')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Error: ${snap.error}');
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);
            allDocs.sort((a, b) {
              final ta = (a.data() as Map)['createdAt'];
              final tb = (b.data() as Map)['createdAt'];
              if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
              return 0;
            });

            final docs = allDocs.where((d) {
              if (_search.isEmpty) return true;
              final data = d.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              final subj = (data['subject'] ?? '').toString().toLowerCase();
              return title.contains(_search) || subj.contains(_search);
            }).toList();

            if (docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      _search.isEmpty
                          ? 'No MCQ exams yet. Tap "Create MCQ Exam".'
                          : 'No exams match "$_search".',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final published = d['published'] == true;
                final title = d['title']?.toString() ?? 'Untitled';
                final isBangla = isBanglaText(title);
                final isFree = d['isFree'] ?? true;
                final price = d['price'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: published
                          ? AppTheme.accentEmerald.withOpacity(0.18)
                          : Colors.orange.withOpacity(0.18),
                      child: Icon(
                        Icons.quiz,
                        color: published ? AppTheme.accentEmerald : Colors.orange.shade800,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: isBangla ? 'Noto Sans Bengali' : null,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (d['studentClass'] != null || d['class'] != null) 'Class ${d['studentClass'] ?? d['class']}',
                        d['subject'] ?? '',
                        '${d['questionCount'] ?? 0} Questions',
                        isFree ? 'Free' : '৳$price',
                        published ? 'Published' : 'Draft',
                      ].where((e) => e.toString().isNotEmpty).join(' • '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'questions') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateMcqScreen(
                                examId: doc.id,
                                examTitle: title,
                              ),
                            ),
                          );
                        } else if (v == 'publish') {
                          await doc.reference.update({'published': true});
                        } else if (v == 'unpublish') {
                          await doc.reference.update({'published': false});
                        } else if (v == 'delete') {
                          await _deleteExamWithConfirm(doc.reference, title);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'questions',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit Questions'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: published ? 'unpublish' : 'publish',
                          child: Row(
                            children: [
                              Icon(
                                published ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: published ? Colors.orange : Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(published ? 'Unpublish' : 'Publish'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateMcqScreen(
                            examId: doc.id,
                            examTitle: title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _WrittenPlaceholder extends StatelessWidget {
  const _WrittenPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, size: 48, color: AppTheme.royalBlue),
          SizedBox(height: 12),
          Text(
            'Written Exams — Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Exam metadata creation form with dynamic cascading class selection and pricing support
class CreateMcqExamForm extends StatefulWidget {
  const CreateMcqExamForm({super.key});

  @override
  State<CreateMcqExamForm> createState() => _CreateMcqExamFormState();
}

class _CreateMcqExamFormState extends State<CreateMcqExamForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '30');
  final _markCtrl = TextEditingController(text: '20');
  final _attemptsCtrl = TextEditingController(text: '1');

  // Cascading class selection state
  String? _selectedClass;
  String? _selectedGroup;
  String? _selectedSubDept;
  String? _matchedClassDocId;
  String? _selectedSubjectName;

  // Pricing controls
  bool _isFree = true;
  final _priceCtrl = TextEditingController(text: '0');

  DateTime _start = DateTime.now();
  DateTime _expire = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _markCtrl.dispose();
    _attemptsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _expire,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d == null) return;
    setState(() {
      if (isStart) {
        _start = d;
      } else {
        _expire = d;
      }
    });
  }

  Future<void> _createAndGoQuestions() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedGroup == null || _selectedSubDept == null || _matchedClassDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fully select Class, Department, Section, and Subject.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final parsedPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

      final ref = await FirebaseFirestore.instance.collection('exams').add({
        'title': _nameCtrl.text.trim(),
        'type': 'mcq',
        'class': _selectedClass,
        'studentClass': _selectedClass,
        'department': _selectedGroup,
        'subDepartment': _selectedSubDept,
        'classDocId': _matchedClassDocId,
        'subject': _selectedSubjectName,
        'durationMinutes': int.tryParse(_timeCtrl.text.trim()) ?? 30,
        'fullMarks': int.tryParse(_markCtrl.text.trim()) ?? 20,
        'attempts': int.tryParse(_attemptsCtrl.text.trim()) ?? 1,
        'startDate': Timestamp.fromDate(_start),
        'expireDate': Timestamp.fromDate(_expire),
        'isFree': _isFree,
        'price': _isFree ? 0.0 : parsedPrice,
        'published': false,
        'questionCount': 0,
        'teacherId': uid,
        'teacherName': AuthService().currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateMcqScreen(examId: ref.id, examTitle: _nameCtrl.text.trim()),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Create MCQ Exam')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Exam Name / Title *',
                hintText: 'e.g. এইচএসসি হিসাববিজ্ঞান ১ম পত্র মডেল টেস্ট',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Dynamic Firestore Cascading Dropdowns for Classes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
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
                    return data['name']?.toString().trim() == _selectedClass &&
                        data['department']?.toString().trim() == _selectedGroup &&
                        (data['subDepartment']?.toString().trim() ?? 'General') == _selectedSubDept;
                  }).toList();
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
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
                      validator: (v) => v == null ? 'Select Class' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Department / Group *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: groupsList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: _selectedClass == null ? null : (val) {
                        setState(() {
                          _selectedGroup = val;
                          _selectedSubDept = null;
                          _matchedClassDocId = null;
                          _selectedSubjectName = null;
                        });
                      },
                      validator: (v) => v == null ? 'Select Department' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSubDept,
                      decoration: const InputDecoration(
                        labelText: 'Sub-Department / Section *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group_work_outlined),
                      ),
                      items: subDeptsList.map((sd) => DropdownMenuItem(value: sd, child: Text(sd))).toList(),
                      onChanged: _selectedGroup == null ? null : (val) {
                        setState(() {
                          _selectedSubDept = val;
                          _matchedClassDocId = null;
                          _selectedSubjectName = null;
                        });
                      },
                      validator: (v) => v == null ? 'Select Section' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _matchedClassDocId,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                      items: matchingClassDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final subj = data['subject']?.toString().trim() ?? 'Subject';
                        return DropdownMenuItem<String>(value: doc.id, child: Text(subj));
                      }).toList(),
                      onChanged: _selectedSubDept == null ? null : (docId) {
                        if (docId != null) {
                          final matchDoc = matchingClassDocs.firstWhere((d) => d.id == docId);
                          final data = matchDoc.data() as Map<String, dynamic>;
                          setState(() {
                            _matchedClassDocId = docId;
                            _selectedSubjectName = data['subject']?.toString().trim();
                          });
                        }
                      },
                      validator: (v) => v == null ? 'Select Subject' : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Time (Minutes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _markCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Full Marks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Start: ${fmt.format(_start)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event_busy, size: 16),
                    label: Text('Expire: ${fmt.format(_expire)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _attemptsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Allowed Attempts',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Pricing Selection Widget
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Exam Pricing *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        labelText: 'Exam Price (৳) *',
                        hintText: 'e.g. 100',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _saving ? null : _createAndGoQuestions,
              child: Text(
                _saving ? 'Saving…' : 'Proceed to Questions',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
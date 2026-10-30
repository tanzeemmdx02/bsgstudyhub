import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/html_pdf_printer.dart';

// ============================================================================
// 1. CLASS LIST SCREEN (WITH THUMBNAIL, ADD, EDIT & DELETE CLASS)
// ============================================================================
class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  final CollectionReference _classesCol =
      FirebaseFirestore.instance.collection('classes');

  Future<void> _openClassFormDialog({String? docId, Map<String, dynamic>? initialData}) async {
    final isEditing = docId != null;
    final nameCtrl = TextEditingController(text: initialData?['name'] ?? '');
    final deptCtrl = TextEditingController(text: initialData?['department'] ?? '');
    final subDeptCtrl = TextEditingController(text: initialData?['subDepartment'] ?? '');
    final subjectCtrl = TextEditingController(text: initialData?['subject'] ?? '');
    final imageUrlCtrl = TextEditingController(text: initialData?['imageUrl'] ?? '');
    final limitCtrl = TextEditingController(
      text: initialData?['studentLimit'] != null && initialData!['studentLimit'] > 0
          ? initialData['studentLimit'].toString()
          : '40',
    );

    bool isAllSubjects = initialData?['isAllSubjects'] ?? false;
    bool isUnlimited = initialData?['isUnlimited'] ?? false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.royalBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note : Icons.class_outlined,
                  color: AppTheme.royalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Class' : 'Add New Class',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: 490,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Class Name *',
                      hintText: 'e.g. Class 11, Class 12, HSC 2026',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Departments / Group *',
                      hintText: 'e.g. Science, Commerce, Humanities',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subDeptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sub Department / Section',
                      hintText: 'e.g. Morning Shift, Section A, Batch 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (Thumbnail)',
                      hintText: 'https://images.unsplash.com/... (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subjectCtrl,
                          enabled: !isAllSubjects,
                          decoration: InputDecoration(
                            labelText: isAllSubjects ? 'All Subjects Selected' : 'Subject *',
                            hintText: 'e.g. Accounting, Higher Math',
                            border: const OutlineInputBorder(),
                            filled: isAllSubjects,
                            fillColor: isAllSubjects ? Colors.grey.shade100 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Checkbox(
                            value: isAllSubjects,
                            activeColor: AppTheme.royalBlue,
                            onChanged: (val) {
                              setModalState(() {
                                isAllSubjects = val ?? false;
                                if (isAllSubjects) subjectCtrl.text = 'All Subjects';
                              });
                            },
                          ),
                          const Text('All Subjects', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: limitCtrl,
                          keyboardType: TextInputType.number,
                          enabled: !isUnlimited,
                          decoration: InputDecoration(
                            labelText: isUnlimited ? 'Unlimited Students' : 'Student Limit *',
                            border: const OutlineInputBorder(),
                            filled: isUnlimited,
                            fillColor: isUnlimited ? Colors.grey.shade100 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Checkbox(
                            value: isUnlimited,
                            activeColor: AppTheme.royalBlue,
                            onChanged: (val) {
                              setModalState(() {
                                isUnlimited = val ?? false;
                                if (isUnlimited) limitCtrl.text = 'Unlimited';
                              });
                            },
                          ),
                          const Text('Unlimited', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final dept = deptCtrl.text.trim();
                final subDept = subDeptCtrl.text.trim();
                final subj = isAllSubjects ? 'All Subjects' : subjectCtrl.text.trim();
                final img = imageUrlCtrl.text.trim();
                final limit = isUnlimited ? -1 : int.tryParse(limitCtrl.text.trim()) ?? 0;

                if (name.isEmpty || dept.isEmpty || subj.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields.')),
                  );
                  return;
                }

                final payload = {
                  'name': name,
                  'department': dept,
                  'subDepartment': subDept.isEmpty ? 'General' : subDept,
                  'subject': subj,
                  'imageUrl': img,
                  'isAllSubjects': isAllSubjects,
                  'studentLimit': limit,
                  'isUnlimited': isUnlimited,
                  if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
                };

                if (isEditing) {
                  await _classesCol.doc(docId).update(payload);
                } else {
                  await _classesCol.add(payload);
                }

                if (context.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text(isEditing ? 'Update Class' : 'Save Class'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    deptCtrl.dispose();
    subDeptCtrl.dispose();
    subjectCtrl.dispose();
    imageUrlCtrl.dispose();
    limitCtrl.dispose();
  }

  Future<void> _deleteClass(String docId, String className) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$className"?'),
        content: const Text(
          'This will permanently delete this class and all associated attendance records.',
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
      await _classesCol.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class "$className" deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Daily Attendance Register', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black87,
                elevation: 1,
              ),
              onPressed: () => _openClassFormDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Classes', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _classesCol.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_outlined, size: 56, color: AppTheme.royalBlue),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Classes Created Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Click "+ Add Classes" at top-right to create a class.', style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                      onPressed: () => _openClassFormDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Class Now'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Select a Class to View & Take Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : (constraints.maxWidth > 550 ? 2 : 1),
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final d = doc.data() as Map<String, dynamic>;
                      return _ClassCard(
                        docId: doc.id,
                        data: d,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassAttendanceScreen(
                                classId: doc.id,
                                classData: d,
                              ),
                            ),
                          );
                        },
                        onEdit: () => _openClassFormDialog(docId: doc.id, initialData: d),
                        onDelete: () => _deleteClass(doc.id, d['name'] ?? 'Class'),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.docId,
    required this.data,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Class';
    final dept = data['department'] ?? 'General';
    final subDept = data['subDepartment'] ?? '';
    final subject = data['subject'] ?? 'All Subjects';
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    final isUnlimited = data['isUnlimited'] == true;
    final limit = isUnlimited ? 'Unlimited' : '${data['studentLimit'] ?? 40}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 85,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withOpacity(0.08),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                          )
                        : _buildFallbackThumbnail(),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit Class',
                            onPressed: onEdit,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete Class',
                            onPressed: onDelete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dept ${subDept.isNotEmpty ? "• $subDept" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.academicGold.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7A5800),
                            ),
                          ),
                        ),
                        Text(
                          'Cap: $limit',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.royalBlue.withOpacity(0.7),
            AppTheme.primaryNavy.withOpacity(0.9),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.school, size: 38, color: Colors.white70),
      ),
    );
  }
}

// ============================================================================
// 2. CLASS DETAIL SCREEN (ATTENDANCE REGISTERS HISTORY)
// ============================================================================
class ClassAttendanceScreen extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> classData;

  const ClassAttendanceScreen({
    super.key,
    required this.classId,
    required this.classData,
  });

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  String _activeFilter = 'ALL';

  CollectionReference get _sessionsCol => FirebaseFirestore.instance
      .collection('classes')
      .doc(widget.classId)
      .collection('attendance_sessions');

  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _matchesFilter(DateTime date) {
    final today = _startOfToday;
    final now = DateTime.now();

    switch (_activeFilter) {
      case 'Today':
        return date.isAfter(today.subtract(const Duration(seconds: 1))) &&
            date.isBefore(today.add(const Duration(days: 1)));
      case 'Yesterday':
        final y = today.subtract(const Duration(days: 1));
        return date.isAfter(y.subtract(const Duration(seconds: 1))) && date.isBefore(today);
      case 'This week':
        final startWeek = today.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startWeek.subtract(const Duration(seconds: 1)));
      case 'Last week':
        final startThisWeek = today.subtract(Duration(days: now.weekday - 1));
        final startLastWeek = startThisWeek.subtract(const Duration(days: 7));
        return date.isAfter(startLastWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(startThisWeek);
      case 'This month':
        final startMonth = DateTime(now.year, now.month, 1);
        return date.isAfter(startMonth.subtract(const Duration(seconds: 1)));
      case 'Last month':
        final startLastMonth = DateTime(now.year, now.month - 1, 1);
        final endLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return date.isAfter(startLastMonth.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endLastMonth);
      case 'This Year':
        final startYear = DateTime(now.year, 1, 1);
        return date.isAfter(startYear.subtract(const Duration(seconds: 1)));
      case 'ALL':
      default:
        return true;
    }
  }

  Future<void> _openCreateAttendanceDialog({
    List<Map<String, dynamic>>? clonedStudents,
    Map<String, dynamic>? clonedDaysData,
    String? defaultSubject,
    String? defaultTeacher,
  }) async {
    DateTime pickedDate = DateTime.now();
    bool isAllSubjects = defaultSubject == 'All Subjects';
    final subjectCtrl = TextEditingController(
      text: defaultSubject ?? widget.classData['subject'] ?? 'Accounting',
    );
    final teacherCtrl = TextEditingController(
      text: defaultTeacher ?? AuthService().currentUserName.ifEmpty('Prof. A. R. Rahman'),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.royalBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  clonedStudents != null ? Icons.copy : Icons.how_to_reg,
                  color: AppTheme.royalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                clonedStudents != null ? 'Duplicate Register' : 'New Month Attendance',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setModalState(() => pickedDate = d);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'Month & Year: ${pickedDate.month}/${pickedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subjectCtrl,
                          enabled: !isAllSubjects,
                          decoration: InputDecoration(
                            labelText: isAllSubjects ? 'All Subjects' : 'Subject *',
                            border: const OutlineInputBorder(),
                            filled: isAllSubjects,
                            fillColor: isAllSubjects ? Colors.grey.shade100 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Checkbox(
                            value: isAllSubjects,
                            activeColor: AppTheme.royalBlue,
                            onChanged: (val) {
                              setModalState(() {
                                isAllSubjects = val ?? false;
                                if (isAllSubjects) subjectCtrl.text = 'All Subjects';
                              });
                            },
                          ),
                          const Text('All Subjects', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: teacherCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teacher Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
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
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
              onPressed: () {
                if (subjectCtrl.text.trim().isEmpty || teacherCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Open 31-Day Sheet'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TakeAttendanceScreen(
            classId: widget.classId,
            classData: widget.classData,
            sessionDate: pickedDate,
            subject: isAllSubjects ? 'All Subjects' : subjectCtrl.text.trim(),
            teacherName: teacherCtrl.text.trim(),
            initialStudents: clonedStudents,
            initialDaysData: clonedDaysData,
          ),
        ),
      );
    }

    subjectCtrl.dispose();
    teacherCtrl.dispose();
  }

  Future<void> _deleteSession(String sessionId, String dateStr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Register ($dateStr)?'),
        content: const Text('This will delete this monthly attendance register.'),
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

    if (ok == true) {
      await _sessionsCol.doc(sessionId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      'ALL',
      'Today',
      'Yesterday',
      'This week',
      'Last week',
      'This month',
      'Last month',
      'This Year',
    ];

    final className = widget.classData['name'] ?? 'Class';
    final subject = widget.classData['subject'] ?? '';
    final dept = widget.classData['department'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(className, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              '$dept • $subject',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _openCreateAttendanceDialog(),
              icon: const Icon(Icons.table_chart_outlined, size: 18),
              label: const Text(
                'Create Attendance',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = _activeFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppTheme.royalBlue,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _activeFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _sessionsCol.orderBy('date', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = (snap.data?.docs ?? []).where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final ts = d['date'];
                  if (ts is! Timestamp) return true;
                  return _matchesFilter(ts.toDate());
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance records found for "$_activeFilter".',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _openCreateAttendanceDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Month Sheet'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final ts = d['date'] as Timestamp?;
                    final dt = ts?.toDate() ?? DateTime.now();
                    final formattedDate = '${dt.month}/${dt.year}';
                    final total = d['totalStudents'] ?? 0;
                    final sessionSubject = d['subject'] ?? widget.classData['subject'] ?? '';
                    final teacher = d['teacherName'] ?? '';

                    final List<Map<String, dynamic>> rawStudents = [];
                    if (d['students'] is List) {
                      for (final item in d['students']) {
                        if (item is Map) {
                          rawStudents.add(Map<String, dynamic>.from(item));
                        }
                      }
                    }

                    final Map<String, dynamic> daysData =
                        d['daysData'] is Map ? Map<String, dynamic>.from(d['daysData']) : {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
                          child: const Icon(Icons.calendar_month, color: AppTheme.royalBlue, size: 22),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Month: $formattedDate',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            if (sessionSubject.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(sessionSubject, style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Enrolled Students: $total • Teacher: $teacher',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: AppTheme.royalBlue),
                              tooltip: 'Duplicate this sheet',
                              onPressed: () {
                                _openCreateAttendanceDialog(
                                  clonedStudents: rawStudents,
                                  clonedDaysData: daysData,
                                  defaultSubject: sessionSubject,
                                  defaultTeacher: teacher,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                              tooltip: 'Open & Mark Attendance',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TakeAttendanceScreen(
                                      classId: widget.classId,
                                      classData: widget.classData,
                                      sessionDate: dt,
                                      subject: sessionSubject,
                                      teacherName: teacher,
                                      existingSessionId: doc.id,
                                      initialStudents: rawStudents,
                                      initialDaysData: daysData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'Delete Sheet',
                              onPressed: () => _deleteSession(doc.id, formattedDate),
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
        ],
      ),
    );
  }
}

// ============================================================================
// 3. RESPONSIVE 31-DAY REGISTER (PINNED STUDENT COLUMN + BOTTOM SCROLL CONTROLS)
// ============================================================================
class TakeAttendanceScreen extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> classData;
  final DateTime sessionDate;
  final String subject;
  final String teacherName;
  final String? existingSessionId;
  final List<Map<String, dynamic>>? initialStudents;
  final Map<String, dynamic>? initialDaysData;

  const TakeAttendanceScreen({
    super.key,
    required this.classId,
    required this.classData,
    required this.sessionDate,
    required this.subject,
    required this.teacherName,
    this.existingSessionId,
    this.initialStudents,
    this.initialDaysData,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  late DateTime _selectedDate;
  bool _saving = false;

  // View Mode: 'sheet' = 31-day Matrix with Pinned Column, 'today' = Mobile Fast List
  String _viewMode = 'sheet';

  List<Map<String, dynamic>> _studentsList = [];
  final Map<String, Map<int, bool>> _attendanceMatrix = {};

  final ScrollController _daysScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.sessionDate;

    if (widget.initialStudents != null && widget.initialStudents!.isNotEmpty) {
      _studentsList = widget.initialStudents!.map((s) => Map<String, dynamic>.from(s)).toList();
      _initializeMatrixFromData(widget.initialDaysData);
    } else {
      _loadClassStudents();
    }
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }

  void _initializeMatrixFromData(Map<String, dynamic>? daysData) {
    for (final s in _studentsList) {
      final sId = s['id'].toString();
      _attendanceMatrix[sId] = {};
      final savedDays = daysData?[sId];

      for (var day = 1; day <= 31; day++) {
        if (savedDays is Map && savedDays[day.toString()] == true) {
          _attendanceMatrix[sId]![day] = true;
        } else {
          _attendanceMatrix[sId]![day] = false;
        }
      }
    }
  }

  Future<void> _loadClassStudents() async {
    final className = widget.classData['name'] ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .where('class', isEqualTo: className)
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'name': data['name'] ?? data['studentName'] ?? 'Student',
        'roll': data['roll']?.toString() ?? data['rollNumber']?.toString() ?? '—',
      };
    }).toList();

    list.sort((a, b) => (int.tryParse(a['roll']!) ?? 0).compareTo(int.tryParse(b['roll']!) ?? 0));

    for (final s in list) {
      final sId = s['id'].toString();
      _attendanceMatrix[sId] = {};
      for (var day = 1; day <= 31; day++) {
        _attendanceMatrix[sId]![day] = false;
      }
    }

    setState(() {
      _studentsList = list;
    });
  }

  void _toggleDayCheck(String studentId, int day) {
    setState(() {
      final current = _attendanceMatrix[studentId]?[day] ?? false;
      _attendanceMatrix[studentId]![day] = !current;
    });
  }

  void _scrollDaysBy(double delta) {
    if (_daysScrollController.hasClients) {
      final target = _daysScrollController.offset + delta;
      _daysScrollController.animateTo(
        target.clamp(0.0, _daysScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToDayIndex(int day) {
    if (_daysScrollController.hasClients) {
      final target = ((day - 1) * 40.0);
      _daysScrollController.animateTo(
        target.clamp(0.0, _daysScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToToday() {
    final today = DateTime.now().day;
    if (_daysScrollController.hasClients && today >= 1 && today <= 31) {
      final targetOffset = ((today - 1) * 40.0) - 20.0;
      _daysScrollController.animateTo(
        targetOffset.clamp(0.0, _daysScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _markTodayAllPresent() {
    final todayDay = DateTime.now().day;
    if (todayDay < 1 || todayDay > 31) return;

    setState(() {
      for (final s in _studentsList) {
        final sId = s['id'].toString();
        _attendanceMatrix[sId]?[todayDay] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked all students present for Day $todayDay (Today) ✓')),
    );
  }

  void _clearTodayAll() {
    final todayDay = DateTime.now().day;
    if (todayDay < 1 || todayDay > 31) return;

    setState(() {
      for (final s in _studentsList) {
        final sId = s['id'].toString();
        _attendanceMatrix[sId]?[todayDay] = false;
      }
    });
  }

  int _getStudentPresentCount(String studentId) {
    final days = _attendanceMatrix[studentId];
    if (days == null) return 0;
    return days.values.where((v) => v == true).length;
  }

  Future<void> _openStudentFormDialog({int? index}) async {
    final isEditing = index != null;
    final initialName = isEditing ? _studentsList[index]['name'] ?? '' : '';
    final initialRoll = isEditing ? _studentsList[index]['roll'] ?? '' : '';

    final nameCtrl = TextEditingController(text: initialName);
    final rollCtrl = TextEditingController(text: initialRoll);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Student Details' : 'Add Student to Sheet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Student Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rollCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Roll Number *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(isEditing ? 'Update' : 'Add Student'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      setState(() {
        if (isEditing) {
          _studentsList[index]['name'] = nameCtrl.text.trim();
          _studentsList[index]['roll'] = rollCtrl.text.trim().isEmpty ? '—' : rollCtrl.text.trim();
        } else {
          final newId = 'st_${DateTime.now().millisecondsSinceEpoch}';
          _studentsList.add({
            'id': newId,
            'name': nameCtrl.text.trim(),
            'roll': rollCtrl.text.trim().isEmpty ? '—' : rollCtrl.text.trim(),
          });
          _attendanceMatrix[newId] = {};
          for (var day = 1; day <= 31; day++) {
            _attendanceMatrix[newId]![day] = false;
          }
        }
      });
    }

    nameCtrl.dispose();
    rollCtrl.dispose();
  }

  void _parseAndAddStudents(String rawText) {
    final lines = const LineSplitter().convert(rawText);
    final List<Map<String, dynamic>> imported = [];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'[\t,;]')).map((e) => e.trim().replaceAll('"', '')).toList();
      if (parts.isEmpty) continue;

      if (i == 0 && (parts[0].toLowerCase().contains('name') || parts[0].toLowerCase().contains('roll'))) {
        continue;
      }

      String name = '';
      String roll = '—';

      if (parts.length >= 2) {
        if (int.tryParse(parts[0]) != null && int.tryParse(parts[1]) == null) {
          roll = parts[0];
          name = parts[1];
        } else {
          name = parts[0];
          roll = parts[1];
        }
      } else {
        name = parts[0];
      }

      if (name.isNotEmpty) {
        final newId = 'st_${DateTime.now().millisecondsSinceEpoch}_$i';
        imported.add({'id': newId, 'name': name, 'roll': roll});
        _attendanceMatrix[newId] = {};
        for (var day = 1; day <= 31; day++) {
          _attendanceMatrix[newId]![day] = false;
        }
      }
    }

    if (imported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student names found in data.')),
      );
      return;
    }

    setState(() => _studentsList.addAll(imported));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${imported.length} student(s) successfully!')),
    );
  }

  Future<void> _pickExcelCsvFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'tsv', 'txt'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('File is empty.');

      final content = utf8.decode(bytes);
      _parseAndAddStudents(content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read file: $e')),
        );
      }
    }
  }

  Future<void> _openPasteFromExcelDialog() async {
    final pasteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.content_paste, color: AppTheme.royalBlue),
            SizedBox(width: 8),
            Text('Paste from Excel / Google Sheets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy columns (Name & Roll) directly from Excel or Google Sheets, then paste them below:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pasteCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: "Example:\nEmranul Hoque\t01\nShayon Das\t02\nTanzeem Ahmed\t03",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (pasteCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Import Students'),
          ),
        ],
      ),
    );

    if (confirmed == true && pasteCtrl.text.trim().isNotEmpty) {
      _parseAndAddStudents(pasteCtrl.text.trim());
    }

    pasteCtrl.dispose();
  }

  void _openExcelImportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Import Students from Spreadsheet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.content_paste, color: Colors.green),
                ),
                title: const Text('Paste Directly from Excel / Google Sheets', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Copy columns in Excel (Ctrl+C) and paste them here'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPasteFromExcelDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.upload_file, color: Colors.blue),
                ),
                title: const Text('Upload File (.csv / .tsv / .txt)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select an exported spreadsheet file from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickExcelCsvFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_studentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one student.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final Map<String, dynamic> daysDataToSave = {};
      for (final s in _studentsList) {
        final sId = s['id'].toString();
        final sDays = _attendanceMatrix[sId] ?? {};
        final Map<String, bool> dayMap = {};
        sDays.forEach((k, v) => dayMap[k.toString()] = v);
        daysDataToSave[sId] = dayMap;
      }

      final payload = {
        'date': Timestamp.fromDate(_selectedDate),
        'month': _selectedDate.month,
        'year': _selectedDate.year,
        'subject': widget.subject,
        'teacherName': widget.teacherName,
        'totalStudents': _studentsList.length,
        'daysData': daysDataToSave,
        'students': _studentsList,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final sessionsCol = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('attendance_sessions');

      if (widget.existingSessionId != null) {
        await sessionsCol.doc(widget.existingSessionId).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await sessionsCol.add(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance Register saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportPdfSheet() async {
    if (_studentsList.isEmpty) return;

    final className = widget.classData['name'] ?? 'Class';
    final monthYear = '${_selectedDate.month}/${_selectedDate.year}';

    final daysHeaders = StringBuffer();
    for (var d = 1; d <= 31; d++) {
      daysHeaders.write('<th style="width: 22px; text-align: center; padding: 4px 1px; font-size: 9px;">$d</th>');
    }

    final rowsBuffer = StringBuffer();
    for (var i = 0; i < _studentsList.length; i++) {
      final s = _studentsList[i];
      final sId = s['id'].toString();
      final presentCount = _getStudentPresentCount(sId);

      final daysCells = StringBuffer();
      for (var d = 1; d <= 31; d++) {
        final isP = _attendanceMatrix[sId]?[d] == true;
        daysCells.write(
          '<td style="text-align: center; padding: 4px 1px; font-size: 10px; font-weight: bold; color: ${isP ? '#00875a' : '#ccc'};">${isP ? "✓" : "-"}</td>',
        );
      }

      rowsBuffer.write('''
        <tr>
          <td style="text-align: center; font-size: 10px;">${i + 1}</td>
          <td style="padding: 4px 6px; font-weight: 600; font-size: 11px;">${s['name']}</td>
          <td style="text-align: center; font-size: 10px;">${s['roll']}</td>
          $daysCells
          <td style="text-align: center; font-weight: bold; color: #00875a; font-size: 11px;">$presentCount/31</td>
        </tr>
      ''');
    }

    final html = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>31-Day Attendance Sheet - $className</title>
  <style>
    @page { size: A4 landscape; margin: 8mm 8mm; }
    body { font-family: Arial, sans-serif; margin: 0; padding: 0; color: #111; }
    .header { text-align: center; margin-bottom: 10px; border-bottom: 2px solid #1a365d; padding-bottom: 6px; }
    .inst-name { font-size: 18px; font-weight: bold; color: #1a365d; margin: 0; }
    .meta { display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 8px; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; }
    th, td { border: 1px solid #ccc; }
    th { background: #1a365d; color: white; }
  </style>
</head>
<body>
  <div class="header">
    <div class="inst-name">BSGD ACADEMY</div>
    <div>Monthly Attendance Register (31 Days)</div>
  </div>
  <div class="meta">
    <div>Class: $className | Subject: ${widget.subject}</div>
    <div>Month: $monthYear</div>
    <div>Teacher: ${widget.teacherName}</div>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width: 25px; font-size: 10px;">#</th>
        <th style="font-size: 11px;">Student Name</th>
        <th style="width: 40px; font-size: 10px;">Roll</th>
        $daysHeaders
        <th style="width: 50px; font-size: 10px;">Total</th>
      </tr>
    </thead>
    <tbody>$rowsBuffer</tbody>
  </table>
  <script>
    window.addEventListener('load', () => { setTimeout(() => { window.print(); }, 350); });
  </script>
</body>
</html>
''';

    await printOrExportHtml(html, 'Attendance_31Days_${className}_$monthYear');
  }

  @override
  Widget build(BuildContext context) {
    final todayDay = DateTime.now().day;
    final totalStudents = _studentsList.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 700;

    final studentColWidth = isMobile ? 125.0 : 220.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('31-Day Attendance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
              '${widget.subject} • Month: ${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Clear, High-Contrast Action Buttons
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
              foregroundColor: AppTheme.royalBlue,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _openExcelImportOptions,
            icon: const Icon(Icons.table_chart, size: 16),
            label: const Text('Import Excel / CSV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryNavy),
            onPressed: _exportPdfSheet,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Add Student Manually',
              icon: const Icon(Icons.person_add, color: AppTheme.primaryNavy),
              onPressed: () => _openStudentFormDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-header bar with View Mode Switcher and Quick Actions
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'sheet', label: Text('31-Day Grid', style: TextStyle(fontSize: 11.5))),
                      ButtonSegment(value: 'today', label: Text('Today Only', style: TextStyle(fontSize: 11.5))),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (set) => setState(() => _viewMode = set.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: _jumpToToday,
                    icon: const Icon(Icons.my_location, size: 14),
                    label: Text('Day $todayDay'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald.withOpacity(0.15),
                      foregroundColor: AppTheme.accentEmerald,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _markTodayAllPresent,
                    icon: const Icon(Icons.done_all, size: 15),
                    label: const Text('All Present Today'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: _clearTodayAll,
                    child: const Text('Clear Today'),
                  ),
                  const SizedBox(width: 12),
                  // Extra Quick Shortcut for Uploading File
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: _openExcelImportOptions,
                    icon: const Icon(Icons.upload_file, size: 15),
                    label: const Text('Upload Spreadsheet'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main Table Area
          Expanded(
            child: _studentsList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.royalBlue.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.group_add, size: 48, color: AppTheme.royalBlue),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No students in this sheet yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'You can add students manually or import an Excel/CSV file with Name & Roll.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                                onPressed: () => _openStudentFormDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Student'),
                              ),
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.accentEmerald.withOpacity(0.15),
                                  foregroundColor: AppTheme.accentEmerald,
                                ),
                                onPressed: _openExcelImportOptions,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Import Excel / CSV / Paste'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : _viewMode == 'today'
                    ? _buildTodayFastListView(todayDay)
                    : _buildFrozenSplitSheet(studentColWidth, todayDay, isMobile),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Text(
                    'Enrolled: $totalStudents',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.academicGold,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saving ? null : _saveAttendance,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Register',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

  // 1. FAST SINGLE-DAY VIEW
  Widget _buildTodayFastListView(int todayDay) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _studentsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final s = _studentsList[i];
        final sId = s['id'].toString();
        final isChecked = _attendanceMatrix[sId]?[todayDay] == true;

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isChecked ? AppTheme.accentEmerald : Colors.grey.shade200,
              foregroundColor: isChecked ? Colors.white : Colors.black87,
              child: Text(s['name'][0].toUpperCase()),
            ),
            title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Roll: ${s['roll']}'),
            trailing: InkWell(
              onTap: () => _toggleDayCheck(sId, todayDay),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecked ? AppTheme.accentEmerald : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isChecked ? AppTheme.accentEmerald : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isChecked ? Icons.check : Icons.close,
                      color: isChecked ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isChecked ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: isChecked ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. PINNED FROZEN SPREADSHEET WITH BOTTOM HORIZONTAL SCROLLBAR & CONTROLLER
  Widget _buildFrozenSplitSheet(double studentColWidth, int todayDay, bool isMobile) {
    return Column(
      children: [
        // Main Table (Pinned Left Column + Scrollable 31 Days)
        Expanded(
          child: Row(
            children: [
              // ==========================================
              // PINNED LEFT COLUMN: NAME & ROLL
              // ==========================================
              Container(
                width: studentColWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      color: Colors.grey.shade200,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text('Student', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _studentsList.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (ctx, i) {
                          final s = _studentsList[i];
                          return Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                Text(
                                  'Roll: ${s['roll']}',
                                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // SCROLLABLE RIGHT DAYS (DAY 1 TO 31 & TOTAL)
              // ==========================================
              Expanded(
                child: RawScrollbar(
                  controller: _daysScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 8.0,
                  thumbColor: AppTheme.royalBlue.withOpacity(0.8),
                  trackColor: Colors.grey.shade200,
                  radius: const Radius.circular(4),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: SingleChildScrollView(
                    controller: _daysScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (31 * 40.0) + 140.0,
                      child: Column(
                        children: [
                          Container(
                            height: 44,
                            color: Colors.grey.shade200,
                            child: Row(
                              children: [
                                ...List.generate(31, (index) {
                                  final day = index + 1;
                                  final isToday = day == todayDay;
                                  return Container(
                                    width: 38,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    alignment: Alignment.center,
                                    decoration: isToday
                                        ? BoxDecoration(
                                            border: Border.all(color: AppTheme.royalBlue, width: 2),
                                            borderRadius: BorderRadius.circular(4),
                                            color: AppTheme.royalBlue.withOpacity(0.12),
                                          )
                                        : null,
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                                        fontSize: 11,
                                        color: isToday ? AppTheme.royalBlue : Colors.black87,
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(
                                  width: 65,
                                  child: Center(
                                    child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: AppTheme.accentEmerald)),
                                  ),
                                ),
                                const SizedBox(width: 50),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _studentsList.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (ctx, i) {
                                final s = _studentsList[i];
                                final sId = s['id'].toString();
                                final presentCount = _getStudentPresentCount(sId);

                                return Container(
                                  height: 48,
                                  color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                                  child: Row(
                                    children: [
                                      ...List.generate(31, (dIndex) {
                                        final day = dIndex + 1;
                                        final isChecked = _attendanceMatrix[sId]?[day] == true;

                                        return InkWell(
                                          onTap: () => _toggleDayCheck(sId, day),
                                          borderRadius: BorderRadius.circular(5),
                                          child: Container(
                                            width: 38,
                                            height: 34,
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: isChecked ? AppTheme.accentEmerald : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: isChecked ? AppTheme.accentEmerald : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: isChecked
                                                ? const Icon(Icons.check, color: Colors.white, size: 19)
                                                : const SizedBox.shrink(),
                                          ),
                                        );
                                      }),
                                      SizedBox(
                                        width: 65,
                                        child: Center(
                                          child: Text(
                                            '$presentCount/31',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.accentEmerald),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                          onPressed: () => setState(() => _studentsList.removeAt(i)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // BOTTOM DAY SCRUBBER STRIP (EASY MOBILE NAVIGATION)
        // ==========================================
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white, // Placed inside decoration to prevent assertions
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios, size: 13),
                tooltip: 'Scroll Left',
                onPressed: () => _scrollDaysBy(-180),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Days 1–10', style: TextStyle(fontSize: 11)),
                        onPressed: () => _scrollToDayIndex(1),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Days 11–20', style: TextStyle(fontSize: 11)),
                        onPressed: () => _scrollToDayIndex(11),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Days 21–31', style: TextStyle(fontSize: 11)),
                        onPressed: () => _scrollToDayIndex(21),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward_ios, size: 13),
                tooltip: 'Scroll Right',
                onPressed: () => _scrollDaysBy(180),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
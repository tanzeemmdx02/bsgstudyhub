import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  /// '' = all, 'xi', 'hsc', 'honors'
  String _classFilter = '';

  String _nameOf(Map<String, dynamic> d) {
    final name = d['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = d['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Student';
  }

  String _classOf(Map<String, dynamic> d) {
    return (d['studentClass'] ?? d['classLevel'] ?? d['class'] ?? '')
        .toString()
        .trim();
  }

  /// Normalize class labels for filter chips
  bool _matchesFilter(Map<String, dynamic> d) {
    if (_classFilter.isEmpty) return true;
    final c = _classOf(d).toLowerCase();
    switch (_classFilter) {
      case 'xi':
        return c.contains('xi') ||
            c.contains('11') ||
            c.contains('একাদশ') ||
            c.contains('eleven');
      case 'hsc':
        return c.contains('hsc') ||
            c.contains('xii') ||
            c.contains('12') ||
            c.contains('দ্বাদশ') ||
            c.contains('inter');
      case 'honors':
        return c.contains('honor') ||
            c.contains('degree') ||
            c.contains('honours') ||
            c.contains('অনার্স') ||
            c.contains('ডিগ্রি') ||
            c.contains('ba') ||
            c.contains('bsc') ||
            c.contains('bba');
      default:
        return true;
    }
  }

  Future<void> _openStudentForm({
    DocumentReference? ref,
    Map<String, dynamic>? existing,
  }) async {
    final isEdit = ref != null;
    final nameCtrl =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: existing?['email']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?['phone']?.toString() ?? '');
    final rollCtrl =
        TextEditingController(text: existing?['roll']?.toString() ?? '');
    final groupCtrl =
        TextEditingController(text: existing?['group']?.toString() ?? '');
    final guardianCtrl = TextEditingController(
      text: existing?['guardian']?.toString() ??
          existing?['guardianName']?.toString() ??
          '',
    );
    final addressCtrl =
        TextEditingController(text: existing?['address']?.toString() ?? '');
    final notesCtrl =
        TextEditingController(text: existing?['notes']?.toString() ?? '');

    String studentClass = _classOf(existing ?? {});
    if (studentClass.isEmpty) studentClass = 'Class XI';

    final classOptions = [
      'Class XI',
      'HSC',
      'Honors / Degree',
      'Class X',
      'Other',
    ];
    if (!classOptions.contains(studentClass)) {
      classOptions.insert(0, studentClass);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(
            isEdit ? 'Edit student' : 'Add a student',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rollCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Roll',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: studentClass,
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            border: OutlineInputBorder(),
                          ),
                          items: classOptions
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDialog(() => studentClass = v ?? 'Class XI'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: groupCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Group (Science / Arts / Commerce…)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: guardianCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Guardian name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
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
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(isEdit ? 'Update' : 'Add student'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      rollCtrl.dispose();
      groupCtrl.dispose();
      guardianCtrl.dispose();
      addressCtrl.dispose();
      notesCtrl.dispose();
      return;
    }

    final payload = {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'roll': rollCtrl.text.trim(),
      'studentClass': studentClass,
      'group': groupCtrl.text.trim(),
      'guardian': guardianCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'notes': notesCtrl.text.trim(),
      'role': 'student',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (isEdit) {
        await ref!.update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['source'] = 'teacher_manual';
        await FirebaseFirestore.instance.collection('students').add(payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Student updated' : 'Student added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    rollCtrl.dispose();
    groupCtrl.dispose();
    guardianCtrl.dispose();
    addressCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _deleteStudent(DocumentReference ref, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('Remove “$name” from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student removed')),
      );
    }
  }

  Future<void> _setAdmissionStatus(
    DocumentReference ref,
    String status,
  ) async {
    await ref.update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (status == 'approved') {
      final snap = await ref.get();
      final d = snap.data() as Map<String, dynamic>? ?? {};
      await FirebaseFirestore.instance.collection('students').add({
        'name': (d['name'] ?? d['studentName'] ?? '').toString(),
        'email': d['email']?.toString() ?? '',
        'phone': d['phone']?.toString() ?? '',
        'roll': d['roll']?.toString() ?? '',
        'studentClass':
            (d['classLevel'] ?? d['studentClass'] ?? '').toString(),
        'group': d['group']?.toString() ?? '',
        'role': 'student',
        'source': 'admission_approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admission $status')),
      );
    }
  }

  Widget _filterChip(String label, String value) {
    final selected = _classFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : null,
            fontSize: 13,
          ),
        ),
        selected: selected,
        selectedColor: AppTheme.royalBlue,
        checkmarkColor: Colors.white,
        onSelected: (_) {
          setState(() {
            _classFilter = selected ? '' : value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header + Add button
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Students',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage registered students and admissions',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => _openStudentForm(),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text(
                'Add a Student',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Class filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', ''),
              _filterChip('Class XI', 'xi'),
              _filterChip('HSC', 'hsc'),
              _filterChip('Honors / Degree', 'honors'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // —— Students table ——
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snap.error}'),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = List<QueryDocumentSnapshot>.from(
              snap.data?.docs ?? [],
            );
            docs.sort((a, b) {
              final na = _nameOf(a.data() as Map<String, dynamic>);
              final nb = _nameOf(b.data() as Map<String, dynamic>);
              return na.toLowerCase().compareTo(nb.toLowerCase());
            });

            final filtered = docs.where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _matchesFilter(d);
            }).toList();

            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No students yet.\n\n'
                    'Tap “Add a Student” or approve an admission.',
                  ),
                ),
              );
            }

            if (filtered.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No students in this class filter.'),
                ),
              );
            }

            return Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppTheme.royalBlue.withOpacity(0.08),
                  ),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 13),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Roll')),
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Group')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Guardian')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(filtered.length, (i) {
                    final doc = filtered[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final name = _nameOf(d);
                    final roll = d['roll']?.toString() ?? '—';
                    final klass = _classOf(d).isEmpty ? '—' : _classOf(d);
                    final group = d['group']?.toString().isNotEmpty == true
                        ? d['group'].toString()
                        : '—';
                    final email = d['email']?.toString().isNotEmpty == true
                        ? d['email'].toString()
                        : '—';
                    final phone = d['phone']?.toString().isNotEmpty == true
                        ? d['phone'].toString()
                        : '—';
                    final guardian =
                        (d['guardian'] ?? d['guardianName'])?.toString();
                    final guardianText =
                        (guardian != null && guardian.isNotEmpty)
                            ? guardian
                            : '—';

                    return DataRow(
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppTheme.royalBlue.withOpacity(0.15),
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.royalBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(roll)),
                        DataCell(Text(klass)),
                        DataCell(Text(group)),
                        DataCell(Text(email)),
                        DataCell(Text(phone)),
                        DataCell(Text(guardianText)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _openStudentForm(
                                  ref: doc.reference,
                                  existing: d,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteStudent(doc.reference, name),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),
        const Text(
          'Pending admissions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'From admission form — approve to add into Students table',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admissions')
              .orderBy('createdAt', descending: true)
              .limit(40)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admissions')
                    .limit(40)
                    .snapshots(),
                builder: (context, snap2) {
                  final docs = (snap2.data?.docs ?? []).where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return d['status'] != 'approved' &&
                        d['status'] != 'rejected';
                  }).toList();
                  return _admissionList(docs);
                },
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final docs = (snap.data?.docs ?? []).where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return d['status'] != 'approved' && d['status'] != 'rejected';
            }).toList();
            return _admissionList(docs);
          },
        ),
      ],
    );
  }

  Widget _admissionList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No pending admissions.'),
        ),
      );
    }
    return Column(
      children: docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final name =
            (d['name'] ?? d['studentName'] ?? 'Applicant').toString();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.academicGold.withOpacity(0.25),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              [
                d['email'] ?? '',
                if (d['classLevel'] != null || d['studentClass'] != null)
                  'Class ${d['classLevel'] ?? d['studentClass']}',
                d['group'] ?? '',
                d['phone'] ?? '',
              ].where((e) => e.toString().isNotEmpty).join('  •  '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () =>
                      _setAdmissionStatus(doc.reference, 'rejected'),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentEmerald,
                  ),
                  onPressed: () =>
                      _setAdmissionStatus(doc.reference, 'approved'),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
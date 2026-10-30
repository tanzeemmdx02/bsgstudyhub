import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';

class AdmissionScreen extends StatefulWidget {
  const AdmissionScreen({super.key});

  @override
  State<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends State<AdmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();

  String? _selectedClass;
  String? _selectedGroup;
  String? _selectedSubDept;
  String? _matchedClassDocId;
  String? _selectedSubjectName;

  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null ||
        _selectedGroup == null ||
        _selectedSubDept == null ||
        _matchedClassDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select Class, Department, Section, and Subject fully.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1. Create Firebase Auth account
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final user = cred.user;
      if (user == null) throw Exception('Account creation failed.');

      // 2. Send email verification link
      await user.sendEmailVerification();

      final rollNo = _rollCtrl.text.trim().isEmpty ? '—' : _rollCtrl.text.trim();

      final profile = <String, dynamic>{
        'uid': user.uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'roll': rollNo,
        'class': _selectedClass,
        'studentClass': _selectedClass,
        'classDocId': _matchedClassDocId,
        'group': _selectedGroup,
        'department': _selectedGroup,
        'subDepartment': _selectedSubDept ?? 'General',
        'subject': _selectedSubjectName ?? 'General',
        'guardian': '',
        'address': '',
        'notes': '',
        'role': 'student',
        'emailVerified': false,
        'status': 'pending_verification',
        'source': 'admission_self',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Save in users/{uid}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profile, SetOptions(merge: true));

      // 4. Save in students/{uid} for Teacher Dashboard
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .set(profile, SetOptions(merge: true));

      // 5. Record admission log
      await FirebaseFirestore.instance.collection('admissions').add({
        ...profile,
        'studentName': profile['name'],
        'status': 'pending_verification',
      });

      // 5.1 Send targeted notification to teachers for new student admission[cite: 10]
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': '${_nameCtrl.text.trim()} is admitted successfully',
        'body': 'Enrolled in: $_selectedClass > $_selectedGroup > $_selectedSubDept > $_selectedSubjectName',
        'type': 'admission',
        'targetUserId': 'all_teachers',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 6. AUTO-ADD STUDENT TO ACTIVE ATTENDANCE SHEETS FOR THIS SPECIFIC CLASS/BATCH
      if (_matchedClassDocId != null) {
        final sessionsSnap = await FirebaseFirestore.instance
            .collection('classes')
            .doc(_matchedClassDocId)
            .collection('attendance_sessions')
            .get();

        for (final sessionDoc in sessionsSnap.docs) {
          final data = sessionDoc.data();
          final List<dynamic> existingStudents =
              List.from(data['students'] ?? []);
          final Map<String, dynamic> daysData =
              Map<String, dynamic>.from(data['daysData'] ?? {});

          final bool alreadyInSheet =
              existingStudents.any((s) => s['id'] == user.uid);
          if (!alreadyInSheet) {
            existingStudents.add({
              'id': user.uid,
              'name': profile['name'],
              'roll': rollNo,
            });

            final Map<String, bool> studentDays = {};
            for (var day = 1; day <= 31; day++) {
              studentDays[day.toString()] = false;
            }
            daysData[user.uid] = studentDays;

            await sessionDoc.reference.update({
              'students': existingStudents,
              'totalStudents': existingStudents.length,
              'daysData': daysData,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await user.updateDisplayName(_nameCtrl.text.trim());

      // 7. CRITICAL FIX: Sign out user immediately until they verify their email link
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 8. Show verification instruction dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Verify Your Email'),
            ],
          ),
          content: Text(
            'Admission profile created successfully!\n\n'
            'A verification link has been sent to ${_emailCtrl.text.trim()}.\n'
            'Please check your inbox, click the link to verify your email, and then log in.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK, Got It', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.academicGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMISSIONS ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.academicGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Student Admission Form',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Register your academic profile and verify your email to enter scheduled batches.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 10) {
                            return 'Enter a valid phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _rollCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Roll (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .snapshots(),
                        builder: (context, snap) {
                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No active classes found in Daily Attendance. Please add a class first.',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            );
                          }

                          final List<String> classesList = docs
                              .map((d) =>
                                  (d.data() as Map<String, dynamic>)['name']
                                      ?.toString()
                                      .trim() ??
                                  '')
                              .where((n) => n.isNotEmpty)
                              .toSet()
                              .toList();

                          if (_selectedClass != null &&
                              !classesList.contains(_selectedClass)) {
                            _selectedClass = null;
                          }

                          List<String> groupsList = [];
                          if (_selectedClass != null) {
                            groupsList = docs
                                .where((d) =>
                                    (d.data()
                                            as Map<String, dynamic>)['name']
                                        ?.toString()
                                        .trim() ==
                                    _selectedClass)
                                .map((d) =>
                                    (d.data() as Map<String, dynamic>)[
                                            'department']
                                        ?.toString()
                                        .trim() ??
                                    '')
                                .where((g) => g.isNotEmpty)
                                .toSet()
                                .toList();
                          }

                          if (_selectedGroup != null &&
                              !groupsList.contains(_selectedGroup)) {
                            _selectedGroup = null;
                          }

                          List<String> subDeptsList = [];
                          if (_selectedClass != null &&
                              _selectedGroup != null) {
                            subDeptsList = docs
                                .where((d) {
                                  final data =
                                      d.data() as Map<String, dynamic>;
                                  final cName =
                                      data['name']?.toString().trim() ?? '';
                                  final dept =
                                      data['department']?.toString().trim() ??
                                          '';
                                  return cName == _selectedClass &&
                                      dept == _selectedGroup;
                                })
                                .map((d) =>
                                    (d.data() as Map<String, dynamic>)[
                                            'subDepartment']
                                        ?.toString()
                                        .trim() ??
                                    'General')
                                .where((sd) => sd.isNotEmpty)
                                .toSet()
                                .toList();
                          }

                          if (_selectedSubDept != null &&
                              !subDeptsList.contains(_selectedSubDept)) {
                            _selectedSubDept = null;
                          }

                          List<QueryDocumentSnapshot> matchingClassDocs = [];
                          if (_selectedClass != null &&
                              _selectedGroup != null &&
                              _selectedSubDept != null) {
                            matchingClassDocs = docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final cName = data['name']?.toString().trim() ?? '';
                              final dept =
                                  data['department']?.toString().trim() ?? '';
                              final sd = data['subDepartment']
                                      ?.toString()
                                      .trim() ??
                                  'General';
                              return cName == _selectedClass &&
                                  dept == _selectedGroup &&
                                  sd == _selectedSubDept;
                            }).toList();
                          }

                          if (_matchedClassDocId != null &&
                              !matchingClassDocs
                                  .any((d) => d.id == _matchedClassDocId)) {
                            _matchedClassDocId = null;
                            _selectedSubjectName = null;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedClass,
                                decoration: const InputDecoration(
                                  labelText: 'Class *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: classesList
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedClass = val;
                                    _selectedGroup = null;
                                    _selectedSubDept = null;
                                    _matchedClassDocId = null;
                                    _selectedSubjectName = null;
                                  });
                                },
                                validator: (v) =>
                                    v == null ? 'Select Class' : null,
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: _selectedGroup,
                                decoration: const InputDecoration(
                                  labelText: 'Group / Department *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: groupsList
                                    .map((g) => DropdownMenuItem(
                                        value: g, child: Text(g)))
                                    .toList(),
                                onChanged: _selectedClass == null
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _selectedGroup = val;
                                          _selectedSubDept = null;
                                          _matchedClassDocId = null;
                                          _selectedSubjectName = null;
                                        });
                                      },
                                validator: (v) =>
                                    v == null ? 'Select Department' : null,
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                value: _selectedSubDept,
                                decoration: const InputDecoration(
                                  labelText: 'Sub Department / Section *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.group_work_outlined),
                                ),
                                items: subDeptsList
                                    .map((sd) => DropdownMenuItem(
                                        value: sd, child: Text(sd)))
                                    .toList(),
                                onChanged: _selectedGroup == null
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _selectedSubDept = val;
                                          _matchedClassDocId = null;
                                          _selectedSubjectName = null;
                                        });
                                      },
                                validator: (v) => v == null
                                    ? 'Select Sub Department / Section'
                                    : null,
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
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(subj),
                                  );
                                }).toList(),
                                onChanged: _selectedSubDept == null
                                    ? null
                                    : (docId) {
                                        if (docId != null) {
                                          final matchDoc = matchingClassDocs.firstWhere((d) => d.id == docId);
                                          final data = matchDoc.data() as Map<String, dynamic>;
                                          setState(() {
                                            _matchedClassDocId = docId;
                                            _selectedSubjectName = data['subject']?.toString().trim();
                                          });
                                        }
                                      },
                                validator: (v) =>
                                    v == null ? 'Select Subject' : null,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.academicGold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : const Text(
                                'Register & Verify Email',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
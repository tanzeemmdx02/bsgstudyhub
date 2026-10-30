import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../main.dart';

class StudentSettingScreen extends StatefulWidget {
  const StudentSettingScreen({super.key});

  @override
  State<StudentSettingScreen> createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  final _nameCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _loading = true;
  bool _updatingProfile = false;
  bool _updatingPass = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['name'] != null) {
        _nameCtrl.text = doc.data()!['name'];
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _updateProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() => _updatingProfile = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': user.email,
          'role': 'student',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student profile updated successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _newPassCtrl.text.trim();
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _updatingPass = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPass);
        _newPassCtrl.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Update your student account details and password.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Profile Card
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const Divider(height: 20),
                              TextField(
                                controller: TextEditingController(text: user?.email ?? ''),
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Your Full Name *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                                  onPressed: _updatingProfile ? null : _updateProfile,
                                  child: Text(_updatingProfile ? 'Saving...' : 'Save Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password Card
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Security Credentials',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const Divider(height: 20),
                              TextField(
                                controller: _newPassCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password *',
                                  hintText: 'At least 6 characters',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                                  onPressed: _updatingPass ? null : _updatePassword,
                                  child: Text(_updatingPass ? 'Updating...' : 'Change Password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
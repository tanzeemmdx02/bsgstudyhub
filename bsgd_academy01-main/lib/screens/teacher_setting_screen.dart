import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TeacherSettingScreen extends StatefulWidget {
  const TeacherSettingScreen({super.key});

  @override
  State<TeacherSettingScreen> createState() => _TeacherSettingScreenState();
}

class _TeacherSettingScreenState extends State<TeacherSettingScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _loading = true;
  bool _updatingProfile = false;
  bool _updatingPass = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nidCtrl.dispose();
    _addressCtrl.dispose();
    _aboutCtrl.dispose();
    _dobCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        _nameCtrl.text = d['name'] ?? _nameCtrl.text;
        _phoneCtrl.text = d['phone'] ?? '';
        _nidCtrl.text = d['nid'] ?? '';
        _addressCtrl.text = d['address'] ?? '';
        _aboutCtrl.text = d['about'] ?? '';
        _dobCtrl.text = d['dob'] ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Handles re-authentication if Firebase requires recent login for sensitive ops
  Future<bool> _reauthenticateUser(User user) async {
    final passwordCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-Authentication Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Updating sensitive information requires your current password to confirm:'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok == true && passwordCtrl.text.isNotEmpty && user.email != null) {
      try {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordCtrl.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Re-authentication failed: $e')),
          );
        }
      }
    }
    return false;
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();

    if (name.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email cannot be empty.')),
      );
      return;
    }

    setState(() => _updatingProfile = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Email if changed
        if (newEmail != user.email) {
          try {
            await user.verifyBeforeUpdateEmail(newEmail);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login') {
              final reauthed = await _reauthenticateUser(user);
              if (reauthed) {
                await user.verifyBeforeUpdateEmail(newEmail);
              } else {
                setState(() => _updatingProfile = false);
                return;
              }
            } else {
              rethrow;
            }
          }
        }

        await user.updateDisplayName(name);

        // Update Firestore User Profile
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': newEmail,
          'phone': _phoneCtrl.text.trim(),
          'nid': _nidCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'about': _aboutCtrl.text.trim(),
          'dob': _dobCtrl.text.trim(),
          'role': 'teacher',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Faculty profile updated successfully!')),
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
        try {
          await user.updatePassword(newPass);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            final reauthed = await _reauthenticateUser(user);
            if (reauthed) {
              await user.updatePassword(newPass);
            } else {
              setState(() => _updatingPass = false);
              return;
            }
          } else {
            rethrow;
          }
        }

        _newPassCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Faculty Profile & Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your personal details, credentials, and contact information.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Personal Information Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const Divider(height: 20),

                      // Name & Email
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Phone & DoB
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _dobCtrl,
                              readOnly: true,
                              onTap: _selectDob,
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // NID
                      TextField(
                        controller: _nidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'National ID (NID) / Identity No.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Address
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Full Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // About Me
                      TextField(
                        controller: _aboutCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'About Me / Biography',
                          hintText: 'Brief intro about your teaching background...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),

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

              // Change Password Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Change Password',
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
                          child: Text(_updatingPass ? 'Updating...' : 'Update Password'),
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
    );
  }
}
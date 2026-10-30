import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';

class TeacherContactScreen extends StatefulWidget {
  const TeacherContactScreen({super.key});

  @override
  State<TeacherContactScreen> createState() => _TeacherContactScreenState();
}

class _TeacherContactScreenState extends State<TeacherContactScreen> {
  final _labelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _addContactItem() async {
    final label = _labelCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();

    if (label.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both a label and a value/input.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('contact_info').add({
        'label': label,
        'value': value,
        'subtitle': subtitle.isEmpty ? 'Support Channel' : subtitle,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _labelCtrl.clear();
      _valueCtrl.clear();
      _subtitleCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact information added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteContactItem(String id) async {
    try {
      await FirebaseFirestore.instance.collection('contact_info').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact item removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Email, Phone, Helpline)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueCtrl,
              decoration: const InputDecoration(
                labelText: 'Input/Value (e.g. jfghjfh@gmail.com)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subtitle / Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: _saving
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _addContactItem();
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Setting',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage public helpline contacts rendered on the student Contact screen.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Information', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('contact_info')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No custom contact info added yet. Click "Add Information" above.'),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final label = data['label'] ?? '';
                        final value = data['value'] ?? '';
                        final subtitle = data['subtitle'] ?? '';

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: const Icon(Icons.perm_contact_calendar, color: AppTheme.royalBlue),
                            title: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteContactItem(doc.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
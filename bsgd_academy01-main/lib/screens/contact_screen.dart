import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact & Coaching Helpline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Have inquiries regarding batches, timings, or technical assistance?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    
                    // Default static items
                   

                    // Dynamically loaded teacher-configured fields from Teacher Contact Setting
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('contact_info').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final docs = snapshot.data!.docs;
                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final label = data['label'] ?? '';
                            final value = data['value'] ?? '';
                            final subtitle = data['subtitle'] ?? '';

                            IconData icon = Icons.info_outline;
                            final lowerLabel = label.toLowerCase();
                            if (lowerLabel.contains('phone') || lowerLabel.contains('mobile')) {
                              icon = Icons.phone;
                            } else if (lowerLabel.contains('email') || lowerLabel.contains('mail')) {
                              icon = Icons.email;
                            } else if (lowerLabel.contains('address') || lowerLabel.contains('location')) {
                              icon = Icons.location_on;
                            }

                            return ListTile(
                              dense: true,
                              leading: Icon(icon, color: AppTheme.royalBlue),
                              title: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(subtitle),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const Divider(height: 30),
                    const Text('Send Us a Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Student / Guardian Name', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const TextField(decoration: InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Your Inquiry Details', border: OutlineInputBorder())),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inquiry dispatched to BSGD Academy academic coordinator.')),
                        );
                      },
                      child: const Text('Submit Message', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
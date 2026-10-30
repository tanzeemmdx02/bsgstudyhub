import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TeacherPage {
  dashboard,
  notification,
  payments,
  notes,
  suggestion,
  message,
  students,
  attendance,
  courses,
  exams,
  liveClass,
  contactSetting,
  settings,
}

class TeacherRightBar extends StatelessWidget {
  final TeacherPage selected;
  final ValueChanged<TeacherPage> onSelect;
  final VoidCallback onVisitSite;
  final Future<void> Function() onLogout;

  const TeacherRightBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onVisitSite,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryNavy,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.academicGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.security, size: 16, color: Colors.black87),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Teacher Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _item(Icons.dashboard_outlined, 'Dashboard', TeacherPage.dashboard),
                _item(Icons.notifications_outlined, 'Notification', TeacherPage.notification),
                _item(Icons.payment_outlined, 'Payments', TeacherPage.payments),
                _item(Icons.edit_note_outlined, 'Notes', TeacherPage.notes),
                _item(Icons.lightbulb_outline, 'Suggestion', TeacherPage.suggestion),
                _item(Icons.chat_bubble_outline, 'Message', TeacherPage.message),
                _item(Icons.people_outline, 'Students', TeacherPage.students),
                _item(Icons.how_to_reg_outlined, 'Attendance', TeacherPage.attendance),
                _item(Icons.play_lesson_outlined, 'Courses', TeacherPage.courses),
                _item(Icons.quiz_outlined, 'Exams', TeacherPage.exams),
                _item(Icons.live_tv_outlined, 'Live Class', TeacherPage.liveClass),
                _item(Icons.contacts_outlined, 'Contact Setting', TeacherPage.contactSetting),
                const Divider(color: Colors.white24, height: 20),
                _item(Icons.settings_outlined, 'Settings', TeacherPage.settings),
                const Divider(color: Colors.white24),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.public, size: 20, color: Colors.white70),
                  title: const Text(
                    'Visit Site',
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  onTap: onVisitSite,
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.logout,
                    size: 20,
                    color: AppTheme.accentRose,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.accentRose,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, TeacherPage page) {
    final active = selected == page;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.royalBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: active ? Colors.white : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : Colors.white70,
          ),
        ),
        onTap: () => onSelect(page),
      ),
    );
  }
}
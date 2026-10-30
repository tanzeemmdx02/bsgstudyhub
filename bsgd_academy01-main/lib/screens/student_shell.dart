import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'courses_screen.dart';
import 'exams_screen.dart';
import 'results_screen.dart';
import 'public_suggestion_screen.dart';
import 'notes_screen.dart'; // if you have it; else remove

class StudentShell extends StatefulWidget {
  final int initialIndex;

  const StudentShell({super.key, this.initialIndex = 0});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _titles = ['Courses', 'Exams', 'Results', 'Suggestions'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    final pages = [
      const CoursesScreen(),
      const ExamsScreen(),
      const ResultsScreen(),
      const PublicSuggestionScreen(),
    ];
    final rightBar = Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'QUICK MENU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          _navTile(Icons.menu_book, 'Courses', 0),
          _navTile(Icons.quiz, 'Exams', 1),
          _navTile(Icons.emoji_events, 'Results', 2),
          _navTile(Icons.lightbulb_outline, 'Suggestions', 3),
          const Divider(height: 32),
          ListTile(
            dense: true,
            leading: const Icon(Icons.home_outlined, size: 20),
            title: const Text('Dashboard', style: TextStyle(fontSize: 13)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      endDrawer: wide ? null : Drawer(child: rightBar),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: pages[_index]),
                rightBar,
              ],
            )
          : pages[_index],
    );
  }

  Widget _navTile(IconData icon, String label, int i) {
    final selected = _index == i;
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: AppTheme.royalBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppTheme.royalBlue : AppTheme.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? AppTheme.royalBlue : null,
        ),
      ),
      onTap: () => setState(() => _index = i),
    );
  }
}

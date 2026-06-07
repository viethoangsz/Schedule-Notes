import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'notes/notes_screen.dart';
import 'alarm/alarm_screen.dart';
import 'tools/tools_screen.dart';
import 'settings/settings_screen.dart';
import 'search/search_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const NotesScreen(),
    const AlarmScreen(),
    const ToolsScreen(),
    const SettingsScreen(),
  ];

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: _currentIndex == 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: IconButton(
                        onPressed: _openSearch,
                        icon: Icon(Icons.search_rounded, color: cs.onPrimary),
                        tooltip: 'Tìm kiếm',
                        style: IconButton.styleFrom(
                          backgroundColor: cs.onPrimary.withOpacity(0.15),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch trình',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2_rounded),
            label: 'Ghi chú',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm_rounded),
            label: 'Báo thức',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets_rounded),
            label: 'Công cụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

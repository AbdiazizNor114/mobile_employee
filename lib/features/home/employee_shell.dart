import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/widgets/shaqonet_bottom_nav_bar.dart';
import '../activity/activity_screen.dart';
import '../hours/hours_screen.dart';
import '../profile/account_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

class EmployeeShell extends ConsumerStatefulWidget {
  const EmployeeShell({super.key});

  @override
  ConsumerState<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends ConsumerState<EmployeeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unreadActivityCount = ref.watch(unreadActivityCountProvider);
    const screens = [
      ProfileScreen(),
      ScheduleScreen(),
      ActivityScreen(),
      HoursScreen(),
      AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: ShaqoNetBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        unreadActivityCount: unreadActivityCount,
      ),
    );
  }
}

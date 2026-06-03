import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/service_providers.dart';

class ShaqoNetBottomNavBar extends ConsumerWidget {
  const ShaqoNetBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.unreadActivityCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int unreadActivityCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = _NavLabels.forLanguage(ref.watch(languageCodeProvider));

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.cardBackground,
      indicatorColor: AppColors.greenSoft,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: labels.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: labels.schedule,
        ),
        NavigationDestination(
          icon: _ActivityNavIcon(
            icon: Icons.notifications_none_rounded,
            unreadCount: unreadActivityCount,
          ),
          selectedIcon: _ActivityNavIcon(
            icon: Icons.notifications_rounded,
            unreadCount: unreadActivityCount,
          ),
          label: labels.activity,
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: labels.messages,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: labels.profile,
        ),
      ],
    );
  }
}

class _NavLabels {
  const _NavLabels({
    required this.home,
    required this.schedule,
    required this.activity,
    required this.messages,
    required this.profile,
  });

  final String home;
  final String schedule;
  final String activity;
  final String messages;
  final String profile;

  factory _NavLabels.forLanguage(String languageCode) {
    if (languageCode == 'so') {
      return const _NavLabels(
        home: 'Hoy',
        schedule: 'Jadwal',
        activity: 'Hawlaha',
        messages: 'Farriimaha',
        profile: 'Profile',
      );
    }

    return const _NavLabels(
      home: 'Home',
      schedule: 'Schedule',
      activity: 'Activity',
      messages: 'Messages',
      profile: 'Profile',
    );
  }
}

class _ActivityNavIcon extends StatelessWidget {
  const _ActivityNavIcon({required this.icon, required this.unreadCount});

  final IconData icon;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) return Icon(icon);

    return Badge(
      label: Text('$unreadCount'),
      child: Icon(icon),
    );
  }
}

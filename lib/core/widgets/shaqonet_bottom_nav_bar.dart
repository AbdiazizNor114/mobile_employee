import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class ShaqoNetBottomNavBar extends ConsumerWidget {
  const ShaqoNetBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.unreadActivityCount = 0,
    this.unreadMessageCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int unreadActivityCount;
  final int unreadMessageCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = AppLocalizations.of(context);
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
          icon: _NavIconWithBadge(
            icon: Icons.notifications_none_rounded,
            unreadCount: unreadActivityCount,
          ),
          selectedIcon: _NavIconWithBadge(
            icon: Icons.notifications_rounded,
            unreadCount: unreadActivityCount,
          ),
          label: labels.activity,
        ),
        NavigationDestination(
          icon: _NavIconWithBadge(
            icon: Icons.forum_outlined,
            unreadCount: unreadMessageCount,
          ),
          selectedIcon: _NavIconWithBadge(
            icon: Icons.forum_rounded,
            unreadCount: unreadMessageCount,
          ),
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

class _NavIconWithBadge extends StatelessWidget {
  const _NavIconWithBadge({required this.icon, required this.unreadCount});

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

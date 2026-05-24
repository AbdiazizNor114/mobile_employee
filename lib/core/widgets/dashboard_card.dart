import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import 'shaqonet_card.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ShaqoNetCard(padding: padding, child: child);
  }
}

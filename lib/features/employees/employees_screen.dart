import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Employees', leadingIcon: null),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                DashboardCard(
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined,
                          color: AppColors.primaryGreen, size: 40),
                      const SizedBox(height: AppSpacing.md),
                      Text('Team directory',
                          style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Coworkers, managers, and contact visibility will be connected later.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

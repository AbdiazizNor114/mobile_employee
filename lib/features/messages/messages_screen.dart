import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Messages', leadingIcon: null),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                DashboardCard(
                  child: Column(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppColors.primaryGreen, size: 40),
                      const SizedBox(height: AppSpacing.md),
                      Text('No new messages',
                          style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Workplace messages and shift replies will appear here.',
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

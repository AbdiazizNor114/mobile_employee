import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/profile_photo.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../l10n/generated/app_localizations.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final companyName = ref.watch(companyNameProvider);
    final languageCode = ref.watch(languageCodeProvider);
    final enabledLanguages = ref.watch(enabledLanguagesProvider);
    final l10n = AppLocalizations.of(context);
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 720.0 : double.infinity;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: l10n.profile,
            leadingIcon: Icons.edit_outlined,
            onLeadingPressed: () => context.go('/profile/edit'),
            trailingIcon: Icons.logout_rounded,
            onTrailingPressed: () async {
              await ref.read(signOutProvider)();
            },
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const OfflineCacheBanner(),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.greenSoft,
                            backgroundImage:
                                profilePhotoProvider(profile.profilePhotoUrl),
                            child:
                                profilePhotoProvider(profile.profilePhotoUrl) !=
                                        null
                                    ? null
                                    : Text(
                                        profile.initials,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(profile.fullName,
                              style: AppTypography.headingMedium),
                          Text(
                            profile.primaryRole,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Column(
                        children: [
                          _ProfileInfoRow(
                            icon: Icons.mail_outline_rounded,
                            label: l10n.email,
                            value: profile.email,
                          ),
                          const Divider(height: AppSpacing.lg),
                          _ProfileInfoRow(
                            icon: Icons.work_outline_rounded,
                            label: l10n.jobTitle,
                            value: profile.primaryRole,
                          ),
                          const Divider(height: AppSpacing.lg),
                          _ProfileInfoRow(
                            icon: Icons.phone_outlined,
                            label: l10n.phone,
                            value: profile.phoneNumber.isEmpty
                                ? l10n.notProvided
                                : profile.phoneNumber,
                          ),
                          const Divider(height: AppSpacing.lg),
                          _ProfileInfoRow(
                            icon: Icons.business_outlined,
                            label: l10n.company,
                            value: companyName,
                          ),
                        ],
                      ),
                    ),
                    if (enabledLanguages.length > 1) ...[
                      const SizedBox(height: AppSpacing.md),
                      DashboardCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.preferences,
                                style: AppTypography.headingMedium),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.language_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue:
                                        enabledLanguages.contains(languageCode)
                                            ? languageCode
                                            : 'en',
                                    decoration: InputDecoration(
                                      labelText: l10n.appLanguage,
                                    ),
                                    items: enabledLanguages
                                        .map(
                                          (code) => DropdownMenuItem(
                                            value: code,
                                            child: Text(
                                              code == 'en'
                                                  ? l10n.englishName
                                                  : code == 'so'
                                                      ? l10n.somaliName
                                                      : l10n.swahiliName,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (selected) {
                                      if (selected == null) return;
                                      ref
                                          .read(languageCodeProvider.notifier)
                                          .setLanguage(selected);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    DashboardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.documents,
                              style: AppTypography.headingMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.greenSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  l10n.employmentDocumentsManaged,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.greenSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

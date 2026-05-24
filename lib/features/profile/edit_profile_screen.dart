import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/employee_profile.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/profile_form_field.dart';
import '../../core/widgets/shaqonet_card.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late bool _careAssistant;
  late bool _teamLead;
  bool _extraOpen = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(employeeProfileProvider);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _careAssistant = profile.isCareAssistant;
    _teamLead = profile.isTeamLead;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _closeEditor() {
    context.go('/');
  }

  void _saveProfile() {
    ref.read(employeeProfileProvider.notifier).save(
          EmployeeProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            isCareAssistant: _careAssistant,
            isTeamLead: _teamLead,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved in demo mode.')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 680.0 : double.infinity;
    final previewProfile = EmployeeProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      isCareAssistant: _careAssistant,
      isTeamLead: _teamLead,
    );

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Edit Profile',
            leadingIcon: null,
            trailingIcon: Icons.close,
            onTrailingPressed: _closeEditor,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    ShaqoNetCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.greenSoft,
                            child: Text(
                              previewProfile.initials,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Change profile picture'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProfileFormField(
                      label: 'First name',
                      controller: _firstNameController,
                    ),
                    ProfileFormField(
                      label: 'Last name',
                      controller: _lastNameController,
                    ),
                    ProfileFormField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    ProfileFormField(
                      label: 'Phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    ShaqoNetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Job role', style: AppTypography.headingMedium),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _careAssistant,
                            onChanged: (value) =>
                                setState(() => _careAssistant = value ?? false),
                            title: const Text('Care assistant'),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _teamLead,
                            onChanged: (value) =>
                                setState(() => _teamLead = value ?? false),
                            title: const Text('Team lead'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShaqoNetCard(
                      child: ExpansionTile(
                        initiallyExpanded: _extraOpen,
                        onExpansionChanged: (value) =>
                            setState(() => _extraOpen = value),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text('Extra information',
                            style: AppTypography.headingMedium),
                        children: [
                          Text(
                            'Emergency contact, certificates, and employment notes will be added in a later backend slice.',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeEditor,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveProfile,
                      child: const Text('Save profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

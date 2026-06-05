import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/employee_profile.dart';
import '../../core/providers/mock_work_provider.dart';
import '../../core/utils/profile_photo.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/profile_form_field.dart';
import '../../core/widgets/shaqonet_card.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _maxPhotoBytes = 700 * 1024;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _profilePhotoUrlController;
  bool _extraOpen = false;
  bool _isLoading = false;
  final _picker = ImagePicker();

  bool get _isFormValid {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    return first.isNotEmpty && last.isNotEmpty && email.contains('@');
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(employeeProfileProvider);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _jobTitleController = TextEditingController(text: profile.jobTitle);
    _profilePhotoUrlController =
        TextEditingController(text: profile.profilePhotoUrl);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _profilePhotoUrlController.dispose();
    super.dispose();
  }

  void _closeEditor() {
    if (!_isLoading) context.go('/');
  }

  Future<void> _saveProfile() async {
    final existing = ref.read(employeeProfileProvider);
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add first name, last name, and a valid email.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(employeeProfileProvider.notifier).save(
            EmployeeProfile(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              isCareAssistant: existing.isCareAssistant,
              isTeamLead: existing.isTeamLead,
              jobTitle: _jobTitleController.text.trim(),
              companyRole: existing.companyRole,
              profilePhotoUrl: _profilePhotoUrlController.text.trim(),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved.')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save profile. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    if (_isLoading) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large. Choose a smaller photo.'),
            ),
          );
        }
        return;
      }
      final extension = picked.name.toLowerCase();
      final mimeType = extension.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final value = 'data:$mimeType;base64,${base64Encode(bytes)}';
      _profilePhotoUrlController.text = value;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pick image. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(employeeProfileProvider);
    final contentMaxWidth =
        MediaQuery.sizeOf(context).width >= 760 ? 680.0 : double.infinity;
    final previewProfile = EmployeeProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      isCareAssistant: existing.isCareAssistant,
      isTeamLead: existing.isTeamLead,
      jobTitle: _jobTitleController.text.trim(),
      companyRole: existing.companyRole,
      profilePhotoUrl: _profilePhotoUrlController.text.trim(),
    );

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Edit Profile',
            leadingIcon: null,
            trailingIcon: Icons.close,
            onTrailingPressed: _isLoading ? null : _closeEditor,
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
                            backgroundImage:
                                profilePhotoProvider(previewProfile.profilePhotoUrl),
                            child: profilePhotoProvider(
                                        previewProfile.profilePhotoUrl) !=
                                    null
                                ? null
                                : Text(
                                    previewProfile.initials,
                                    style: const TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.w900),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed:
                                    _isLoading ? null : _pickPhotoFromGallery,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Choose from gallery'),
                              ),
                              if (_profilePhotoUrlController.text.isNotEmpty)
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _profilePhotoUrlController.clear();
                                          setState(() {});
                                        },
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProfileFormField(
                      label: 'First name',
                      controller: _firstNameController,
                      enabled: !_isLoading,
                    ),
                    ProfileFormField(
                      label: 'Last name',
                      controller: _lastNameController,
                      enabled: !_isLoading,
                    ),
                    ProfileFormField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    ProfileFormField(
                      label: 'Phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                    ),
                    ProfileFormField(
                      label: 'Job title',
                      controller: _jobTitleController,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ShaqoNetCard(
                      child: ExpansionTile(
                        initiallyExpanded: _extraOpen,
                        onExpansionChanged: (value) {
                          if (!_isLoading) {
                            setState(() => _extraOpen = value);
                          }
                        },
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text('Extra information',
                            style: AppTypography.headingMedium),
                        children: [
                          Text(
                            'Emergency contact, certificates, and employment notes are managed by your workplace.',
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
                      onPressed: _isLoading ? null : _closeEditor,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isFormValid && !_isLoading) ? _saveProfile : null,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save profile'),
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

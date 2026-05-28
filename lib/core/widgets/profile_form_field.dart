import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class ProfileFormField extends StatelessWidget {
  const ProfileFormField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: controller == null ? initialValue : null,
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }
}

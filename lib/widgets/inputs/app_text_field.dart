import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Standard text field: label, hint, helper/error text, optional
/// prefix icon and password-visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.autofillHints,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  /// Renders the field visually disabled and non-editable — used where a
  /// value is shown but can't be changed from this form (e.g. a verified
  /// email/phone that has its own change flow).
  final bool readOnly;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          readOnly: widget.readOnly,
          enabled: !widget.readOnly,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          validator: widget.validator,
          autofillHints: widget.autofillHints,
          style: AppTypography.bodyLarge.copyWith(color: widget.readOnly ? AppColors.neutral500 : AppColors.ink),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.neutral400),
            filled: true,
            fillColor: widget.readOnly ? AppColors.neutral100 : AppColors.surface,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.neutral500)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.neutral500,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: hasError ? const BorderSide(color: AppColors.error) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.ink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorText: null,
          ),
        ),
        if (hasError || (widget.helperText?.isNotEmpty ?? false)) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasError ? widget.errorText! : widget.helperText!,
            style: AppTypography.caption.copyWith(color: hasError ? AppColors.error : AppColors.neutral500),
          ),
        ],
      ],
    );
  }
}

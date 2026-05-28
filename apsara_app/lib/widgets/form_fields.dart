import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LabeledField extends StatelessWidget {
  LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          cursorColor: context.appColors.primary,
          style: TextStyle(color: context.appColors.text, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 18,
                    color: context.appColors.textLight,
                  ),
            prefixText: prefixText,
          ),
        ),
      ],
    );
  }
}

class DropdownField extends StatelessWidget {
  DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: context.appColors.surfaceWarm,
          iconEnabledColor: context.appColors.textSecondary,
          iconDisabledColor: context.appColors.textLight,
          style: TextStyle(
            color: context.appColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          items: values
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoration: InputDecoration(),
        ),
      ],
    );
  }
}

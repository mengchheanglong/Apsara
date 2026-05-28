import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
  });

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: background ?? context.appColors.soft,
          borderRadius: BorderRadius.circular(22)),
      child: Text(label,
          style: TextStyle(
              color: foreground ?? context.appColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }
}

class OutlinePill extends StatelessWidget {
  const OutlinePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appColors.border),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, color: context.appColors.textSecondary)),
    );
  }
}

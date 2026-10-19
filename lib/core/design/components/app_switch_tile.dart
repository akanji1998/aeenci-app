import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Ligne de réglage avec interrupteur. `onChanged` nul : verrouillé.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: context.textTheme.bodyMedium),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: context.textTheme.bodySmall),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

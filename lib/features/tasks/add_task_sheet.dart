import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet offering voice / text task creation.
Future<void> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends ConsumerWidget {
  const _AddTaskSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.newTask,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _AddOption(
                    icon: Icons.mic_none,
                    label: l10n.addByVoice,
                    color: style.accent,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _AddOption(
                    icon: Icons.keyboard_alt_outlined,
                    label: l10n.addByText,
                    color: style.accent2,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends ConsumerWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Material(
      color: color.withValues(alpha: dark ? 0.12 : 0.10),
      borderRadius: BorderRadius.circular(style.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(style.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.cardRadius),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.78)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: onColor, size: 27),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

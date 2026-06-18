import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'task_model.dart';

/// Localized label for a [Priority].
String priorityLabel(Priority p, AppLocalizations l10n) => switch (p) {
      Priority.high => l10n.priorityHigh,
      Priority.medium => l10n.priorityMedium,
      Priority.low => l10n.priorityLow,
    };

/// A 3-up segmented control for choosing a task's [Priority]. Each segment
/// carries the priority's semantic color + icon. Used in the add-task sheet.
class PrioritySegment extends StatelessWidget {
  const PrioritySegment({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Priority value;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final p in Priority.values) ...[
          if (p != Priority.values.first) const SizedBox(width: 10),
          Expanded(
            child: _Segment(
              priority: p,
              label: priorityLabel(p, l10n),
              selected: p == value,
              onTap: () => onChanged(p),
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.priority,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Priority priority;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final c = priority.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? c.withValues(alpha: dark ? 0.20 : 0.14)
              : (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(priority.icon, size: 20, color: selected ? c : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a bottom sheet to change a task's priority. Returns the chosen value,
/// or null if dismissed. Used on long-press of a task row.
Future<Priority?> showPriorityPicker(
  BuildContext context, {
  required Priority current,
}) {
  return showModalBottomSheet<Priority>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.priority,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              for (final p in Priority.values)
                _PriorityRow(
                  priority: p,
                  label: priorityLabel(p, l10n),
                  selected: p == current,
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.priority,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Priority priority;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = priority.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(priority.icon, size: 20, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, size: 20, color: c),
          ],
        ),
      ),
    );
  }
}

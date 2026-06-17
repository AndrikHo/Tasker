import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/surface_card.dart';
import 'task_model.dart';

/// A single task row rendered as an elevated card with an animated checkbox,
/// a due chip, member avatars and a "completed by" line.
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task, required this.onToggle});

  final TaskItem task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = task.done;

    return SurfaceCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Check(
            done: done,
            accent: style.accent,
            onAccent: style.onAccent,
            onTap: onToggle,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: text.titleMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: scheme.onSurface.withValues(alpha: 0.45),
                    color: done
                        ? scheme.onSurface.withValues(alpha: 0.42)
                        : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (done && task.completedBy != null) ...[
                  const SizedBox(height: 7),
                  _CompletedBy(member: task.completedBy!),
                ] else if (task.due != null) ...[
                  const SizedBox(height: 9),
                  _DueChip(
                    due: task.due!,
                    accent: style.accent,
                    radius: style.chipRadius,
                    dark: dark,
                  ),
                ],
              ],
            ),
          ),
          if (task.assignees.isNotEmpty) ...[
            const SizedBox(width: 10),
            _AvatarStack(
              members: task.assignees,
              ringColor: style.cardColor(dark),
            ),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.done,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });
  final bool done;
  final Color accent;
  final Color onAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? accent : Colors.transparent,
          border: Border.all(
            color: done ? accent : scheme.onSurfaceVariant.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: done ? Icon(Icons.check_rounded, size: 17, color: onAccent) : null,
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({
    required this.due,
    required this.accent,
    required this.radius,
    required this.dark,
  });
  final DateTime due;
  final Color accent;
  final double radius;
  final bool dark;

  String _label() {
    final now = DateTime.now();
    final diff = due.difference(now);
    if (diff.inMinutes < 0) return 'Overdue';
    if (diff.inHours < 1) return 'In ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'In ${diff.inHours} h';
    return '${due.day}.${due.month}';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = due.difference(DateTime.now()).inMinutes < 0;
    final scheme = Theme.of(context).colorScheme;
    final c = overdue ? scheme.error : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(overdue ? Icons.error_outline : Icons.schedule_rounded,
              size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            _label(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBy extends StatelessWidget {
  const _CompletedBy({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(member.emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          'Done by ${member.name}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: member.color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Overlapping circular avatars for the task's assignees.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members, required this.ringColor});
  final List<Member> members;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final shown = members.take(3).toList();
    const overlap = 18.0;
    return SizedBox(
      width: 30 + (shown.length - 1) * overlap,
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor,
                ),
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: shown[i].color.withValues(alpha: 0.95),
                  child: Text(
                    shown[i].emoji,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

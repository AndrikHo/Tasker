import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/add_task_sheet.dart';
import '../tasks/task_model.dart';
import '../tasks/task_providers.dart';

/// Lists home, bento-style: an editorial greeting header, a list switcher
/// strip, a big-number hero (percent + progress), an Active / New-task stat
/// row, and the tasks grouped into clean rows inside elevated surfaces.
class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  int _selected = 0;

  static const _kinds = ListKind.values;

  static const _dotColors = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);
    final tasksByList = ref.watch(tasksProvider);
    final kind = _kinds[_selected];
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMMEEEEd(locale).format(DateTime.now());
    final names = [
      l10n.personalList,
      l10n.sharedList,
      l10n.familyList,
      l10n.workList,
    ];

    final tasks = tasksByList[kind] ?? const <TaskItem>[];
    final active = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    final pct = tasks.isEmpty ? 0 : (done.length / tasks.length * 100).round();

    void toggle(TaskItem t) =>
        ref.read(tasksProvider.notifier).toggle(kind, t.id, DemoMembers.me);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BentoHeader(
                eyebrow: date,
                title: l10n.greeting,
                trailing: const AccountAvatar(radius: 22),
              ),
            ),

            // List switcher strip.
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(kBentoPad, 8, kBentoPad, 0),
                  itemCount: names.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final count = (tasksByList[_kinds[i]] ?? const <TaskItem>[])
                        .where((t) => !t.done)
                        .length;
                    return _ListChip(
                      label: names[i],
                      count: count,
                      dot: _dotColors[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    );
                  },
                ),
              ),
            ),

            // Bento: hero + stats.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kBentoPad, 14, kBentoPad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _HeroTile(
                      listName: names[_selected],
                      pct: pct,
                      done: done.length,
                      total: tasks.length,
                      doneLabel: l10n.markDone,
                      accent: style.accent,
                    ),
                    const SizedBox(height: kBentoGap),
                    Row(
                      children: [
                        Expanded(
                          child: BentoStat(
                            value: '${active.length}',
                            label: l10n.active,
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        const SizedBox(width: kBentoGap),
                        Expanded(
                          child: BentoAddTile(
                            label: l10n.newTask,
                            onTap: () => showAddTaskSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(kBentoPad, 28, kBentoPad, 0),
                  child: Text(
                    l10n.emptyTasks,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              )
            else ...[
              if (active.isNotEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(kBentoPad, 18, kBentoPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: _TaskGroup(items: active, toggle: toggle),
                  ),
                ),
              if (done.isNotEmpty) ...[
                _SectionLabel(label: l10n.markDone),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(kBentoPad, 0, kBentoPad, 0),
                  sliver: SliverToBoxAdapter(
                    child: _TaskGroup(items: done, toggle: toggle),
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

/// Full-width hero tile: list name, an oversized completion percentage, the
/// done/total count and a slim progress bar.
class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.listName,
    required this.pct,
    required this.done,
    required this.total,
    required this.doneLabel,
    required this.accent,
  });

  final String listName;
  final int pct;
  final int done;
  final int total;
  final String doneLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoTile(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listName.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -3,
                  height: 0.9,
                ).copyWith(color: theme.colorScheme.onSurface),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(
                  '%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done / $total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      doneLabel.toLowerCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProgressBar(value: total == 0 ? 0 : done / total),
        ],
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            height: 12,
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [style.accent, style.accent2],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A list switcher chip: a colored dot, label and active count badge.
class _ListChip extends ConsumerWidget {
  const _ListChip({
    required this.label,
    required this.count,
    required this.dot,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color dot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: style.motion,
        curve: style.curve,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? style.accent.withValues(alpha: dark ? 0.18 : 0.14)
              : (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? style.accent
                : (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? style.accent
                      : scheme.onSurfaceVariant.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? style.onAccent : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kBentoPad + 6, 22, kBentoPad, 10),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }
}

/// A group of task rows inside a single elevated surface, divided by hairlines.
class _TaskGroup extends ConsumerWidget {
  const _TaskGroup({required this.items, required this.toggle});

  final List<TaskItem> items;
  final void Function(TaskItem) toggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 58, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                ),
              ),
            _TaskRow(task: items[i], onToggle: () => toggle(items[i])),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.onToggle});

  final TaskItem task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = task.done;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _Check(done: done, accent: style.accent, onAccent: style.onAccent),
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
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(task.completedBy!.emoji,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          'Done by ${task.completedBy!.name}',
                          style: text.labelSmall?.copyWith(
                            color: task.completedBy!.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ] else if (task.due != null) ...[
                    const SizedBox(height: 8),
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
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.done,
    required this.accent,
    required this.onAccent,
  });
  final bool done;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? accent : Colors.transparent,
        border: Border.all(
          color: done ? accent : scheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: done ? Icon(Icons.check_rounded, size: 16, color: onAccent) : null,
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

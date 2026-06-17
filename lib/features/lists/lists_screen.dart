import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/add_task_sheet.dart';
import '../tasks/task_card.dart';
import '../tasks/task_model.dart';
import '../tasks/task_providers.dart';
import 'new_list_sheet.dart';

/// Lists home: a warm greeting header, a progress-ring hero for the active
/// list, pill tabs for each list, and the tasks split into active / done.
class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  int _selected = 0;

  static const _kinds = ListKind.values;

  // Per-list identity colors used for the pill dots.
  static const _dotColors = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF818CF8),
    Color(0xFFFB7185),
    Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasksByList = ref.watch(tasksProvider);
    final kind = _kinds[_selected];
    final names = [
      l10n.personalList,
      l10n.sharedList,
      l10n.familyList,
      l10n.workList,
    ];

    final tasks = tasksByList[kind] ?? const <TaskItem>[];
    final active = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();

    void toggle(TaskItem t) => ref
        .read(tasksProvider.notifier)
        .toggle(kind, t.id, DemoMembers.me);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(greeting: l10n.greeting, onNewList: () => showNewListSheet(context)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: _HeroProgress(
                  listName: names[_selected],
                  total: tasks.length,
                  done: done.length,
                  doneLabel: l10n.markDone,
                  emptyLabel: l10n.emptyTasks,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  itemCount: names.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final count =
                        (tasksByList[_kinds[i]] ?? const <TaskItem>[])
                            .where((t) => !t.done)
                            .length;
                    return _ListPill(
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
            if (tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.task_alt,
                  title: l10n.emptyTasks,
                  actionLabel: l10n.newTask,
                  onAction: () => showAddTaskSheet(context),
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ..._taskSlivers(active, toggle),
              if (done.isNotEmpty) _SectionHeader(label: l10n.markDone),
              ..._taskSlivers(done, toggle),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _taskSlivers(List<TaskItem> items, void Function(TaskItem) toggle) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final t = items[i];
            return TaskCard(task: t, onToggle: () => toggle(t));
          },
        ),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.onNewList});

  final String greeting;
  final VoidCallback onNewList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMMEEEEd(locale).format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  greeting,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.add_rounded, onTap: onNewList),
          const SizedBox(width: 12),
          const AccountAvatar(radius: 21),
        ],
      ),
    );
  }
}

class _RoundIconButton extends ConsumerWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.06 : 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
        child: Icon(icon, size: 24, color: scheme.onSurface),
      ),
    );
  }
}

class _HeroProgress extends ConsumerWidget {
  const _HeroProgress({
    required this.listName,
    required this.total,
    required this.done,
    required this.doneLabel,
    required this.emptyLabel,
  });

  final String listName;
  final int total;
  final int done;
  final String doneLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final theme = Theme.of(context);
    final value = total == 0 ? 0.0 : done / total;
    final pct = (value * 100).round();

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ProgressRing(
            value: value,
            color: style.accent,
            color2: style.accent2,
            size: 84,
            stroke: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (total == 0)
                  Text(
                    emptyLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$done',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: style.accent,
                        ),
                      ),
                      Text(
                        ' / $total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doneLabel.toLowerCase(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }
}

class _ListPill extends ConsumerWidget {
  const _ListPill({
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
          borderRadius: BorderRadius.circular(40),
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

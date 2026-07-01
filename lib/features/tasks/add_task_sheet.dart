import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/feedback.dart';
import '../../l10n/app_localizations.dart';
import 'priority_selector.dart';
import 'task_model.dart';
import 'task_providers.dart';

/// Sheet for adding a task to [listId]. Text entry adds the task immediately;
/// voice capture is stubbed until speech-to-text lands.
Future<void> showAddTaskSheet(BuildContext context, String listId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddTaskSheet(listId: listId),
    ),
  );
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet({required this.listId});

  final String listId;

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _controller = TextEditingController();
  bool _canAdd = false;
  Priority _priority = Priority.low;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canAdd) setState(() => _canAdd = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final me = ref.read(currentMemberProvider);
    ref.read(tasksProvider.notifier).add(
          widget.listId,
          TaskItem(
            id: 't_${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            assignees: [me],
            priority: _priority,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: l10n.taskHint,
                suffixIcon: IconButton(
                  tooltip: l10n.addByVoice,
                  icon: Icon(Icons.mic_none, color: style.accent),
                  onPressed: () => showComingSoon(context, l10n.comingSoon),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.priority.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 10),
            PrioritySegment(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canAdd ? _add : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

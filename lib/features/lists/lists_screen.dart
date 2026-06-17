import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Lists overview. Skeleton: shows the default list types as tabs.
/// Real data (lists, tasks, group access) will be wired to Supabase.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lists = <String>[
      l10n.personalList,
      l10n.sharedList,
      l10n.familyList,
      l10n.workList,
    ];

    return DefaultTabController(
      length: lists.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.listsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final name in lists) Tab(text: name)],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.newList,
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            for (final _ in lists)
              _EmptyTasksView(message: l10n.emptyTasks),
          ],
        ),
        floatingActionButton: _AddTaskFab(l10n: l10n),
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _AddTaskFab extends StatelessWidget {
  const _AddTaskFab({required this.l10n});
  final AppLocalizations l10n;

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic),
              title: Text(l10n.addByVoice),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: Text(l10n.addByText),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddSheet(context),
      child: const Icon(Icons.add),
    );
  }
}

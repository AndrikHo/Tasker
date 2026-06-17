import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_style.dart';
import '../../core/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_model.dart';
import '../tasks/task_providers.dart';

/// Friend detail: a big avatar, the name/id, and a remove action.
Future<void> showFriendDetailSheet(BuildContext context, Member member) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _FriendDetailSheet(member: member),
  );
}

class _FriendDetailSheet extends ConsumerWidget {
  const _FriendDetailSheet({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BigAvatar(member: member),
            const SizedBox(height: 16),
            Text(
              member.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(friendsProvider.notifier).remove(member.id);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.person_remove_alt_1_outlined, size: 20),
                label: Text(l10n.delete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group detail: the group name and its member list.
Future<void> showGroupDetailSheet(
  BuildContext context,
  String name,
  List<Member> members,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _GroupDetailSheet(name: name, members: members),
  );
}

class _GroupDetailSheet extends ConsumerWidget {
  const _GroupDetailSheet({required this.name, required this.members});
  final String name;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = ref.watch(styleProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(style.chipRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [style.accent, style.accent2],
                    ),
                  ),
                  child:
                      Icon(Icons.groups_rounded, color: style.onAccent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.members.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: m.color.withValues(alpha: 0.95),
                      child: Text(m.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      m.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.color.withValues(alpha: 0.22),
        border: Border.all(color: member.color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(member.emoji, style: const TextStyle(fontSize: 38)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_model.dart';
import '../tasks/task_providers.dart';
import 'add_friend_sheet.dart';

/// Friends and groups: a header, a list of friends, and the shared groups
/// with their member avatars. Demo data previews the collaboration model.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    const friends = <Member>[
      DemoMembers.wife,
      DemoMembers.son,
      DemoMembers.coworker,
    ];
    final groups = <_Group>[
      _Group(l10n.familyList, const [
        DemoMembers.me,
        DemoMembers.wife,
        DemoMembers.son,
      ]),
      _Group(l10n.workList, const [DemoMembers.me, DemoMembers.coworker]),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                title: l10n.friendsTitle,
                onAdd: () => showAddFriendSheet(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.separated(
                itemCount: friends.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _FriendRow(member: friends[i]),
              ),
            ),
            _SectionHeader(label: l10n.groups),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _GroupCard(group: groups[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group {
  const _Group(this.name, this.members);
  final String name;
  final List<Member> members;
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _RoundIconButton(icon: Icons.person_add_alt_1_rounded, onTap: onAdd),
          const SizedBox(width: 12),
          const AccountAvatar(radius: 21),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (dark ? Colors.white : Colors.black)
              .withValues(alpha: dark ? 0.06 : 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
        child: Icon(icon, size: 23, color: scheme.onSurface),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {},
      child: Row(
        children: [
          _MemberAvatar(member: member, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              member.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final _Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ref.watch(styleProvider);
    return SurfaceCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(style.chipRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  style.accent.withValues(alpha: 0.9),
                  style.accent2.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Icon(Icons.groups_rounded, color: style.onAccent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _MemberStack(members: group.members),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, this.radius = 20});

  final Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.color.withValues(alpha: 0.22),
        border: Border.all(color: member.color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(member.emoji, style: TextStyle(fontSize: radius * 0.9)),
    );
  }
}

class _MemberStack extends ConsumerWidget {
  const _MemberStack({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ring = style.cardColor(dark);
    const r = 13.0;
    const overlap = 16.0;

    return SizedBox(
      height: r * 2,
      width: overlap * (members.length - 1) + r * 2,
      child: Stack(
        children: [
          for (var i = 0; i < members.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
                child: _MemberAvatar(member: members[i], radius: r),
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
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
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

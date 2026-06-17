import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/account_avatar.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_model.dart';
import '../tasks/task_providers.dart';
import 'add_friend_sheet.dart';
import 'friend_detail_sheet.dart';

/// Friends and groups, bento-style: an editorial header, a Friends-count /
/// Add-friend stat row, the friends as clean rows, and the shared groups as
/// gradient-iconed bento tiles with overlapping member avatars.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final friends = ref.watch(friendsProvider);
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
              child: BentoHeader(
                title: l10n.friendsTitle,
                trailing: const AccountAvatar(radius: 22),
              ),
            ),

            // Stat row: friends count + add-friend tile.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kBentoPad, 10, kBentoPad, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: BentoStat(
                        value: '${friends.length}',
                        label: l10n.friendsTitle,
                        icon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: kBentoGap),
                    Expanded(
                      child: BentoAddTile(
                        label: l10n.addFriend,
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: () => showAddFriendSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Friends as clean rows in one surface.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kBentoPad, 18, kBentoPad, 0),
              sliver: SliverToBoxAdapter(
                child: _FriendGroup(members: friends),
              ),
            ),

            _SectionLabel(label: l10n.groups),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(kBentoPad, 0, kBentoPad, 120),
              sliver: SliverList.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: kBentoGap),
                itemBuilder: (context, i) => _GroupTile(group: groups[i]),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kBentoPad + 6, 24, kBentoPad, 10),
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

class _FriendGroup extends StatelessWidget {
  const _FriendGroup({required this.members});
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 74, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                ),
              ),
            _FriendRow(member: members[i]),
          ],
        ],
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
    return InkWell(
      onTap: () => showFriendDetailSheet(context, member),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _MemberAvatar(member: member, radius: 22),
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
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.group});

  final _Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ref.watch(styleProvider);
    return BentoTile(
      onTap: () => showGroupDetailSheet(context, group.name, group.members),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(style.chipRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [style.accent, style.accent2],
              ),
            ),
            child: Icon(Icons.groups_rounded, color: style.onAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
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
    const r = 14.0;
    const overlap = 17.0;

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../theme/app_style.dart';
import '../../features/characters/character_art.dart';

/// The account avatar: a gradient ring around the selected character. Tapping
/// it opens account settings. Shared by the lists header and any app bar.
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key, this.radius = 19});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(characterProvider);
    final accent2 = character.look.accent2;
    return GestureDetector(
      onTap: () => context.go('/settings/account'),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [character.color, accent2],
          ),
          boxShadow: [
            BoxShadow(
              color: character.color.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CharacterArt(character: character, size: radius * 2),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/settings_provider.dart';
import '../theme/app_style.dart';

/// The account avatar: a gradient ring around a circular avatar. Tapping it
/// opens account settings. Shared by the lists header and any app bar.
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key, this.radius = 19});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.go('/settings/account'),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [style.accent, style.accent2],
          ),
          boxShadow: [
            BoxShadow(
              color: style.accent.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: scheme.surfaceContainerHigh,
          child: Icon(Icons.person, size: radius + 1, color: scheme.onSurface),
        ),
      ),
    );
  }
}

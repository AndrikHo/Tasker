import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';

/// Shared top bar: title on the left, account avatar on the right.
/// Frosted background; tapping the avatar opens account settings.
class TaskerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TaskerAppBar({
    super.key,
    required this.title,
    this.bottom,
    this.actions = const [],
  });

  final String title;
  final PreferredSizeWidget? bottom;
  final List<Widget> actions;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final sigma = style.blurSigma > 0 ? style.blurSigma : 6.0;

    return AppBar(
      titleSpacing: 20,
      title: Text(title),
      bottom: bottom,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: const SizedBox.expand(),
        ),
      ),
      actions: [
        ...actions,
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: GestureDetector(
            onTap: () => context.go('/settings/account'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.accent, style.accent2],
                ),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.person, size: 19),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

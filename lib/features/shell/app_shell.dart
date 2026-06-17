import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation shell hosting the main tabs. Adding tasks lives inside
/// the content (bento tiles), so the bar is a clean, evenly spaced row with
/// no docked center button.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _GlassNavBar(
        style: style,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        destinations: [
          _NavSpec(Icons.checklist_outlined, Icons.checklist, l10n.navLists),
          _NavSpec(Icons.people_outline, Icons.people, l10n.navFriends),
          _NavSpec(Icons.settings_outlined, Icons.settings, l10n.navSettings),
        ],
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.style,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  final AppStyle style;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavSpec> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sigma = style.blurSigma > 0 ? style.blurSigma : 6.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: (dark ? scheme.surface : Colors.white)
                .withValues(alpha: dark ? 0.55 : 0.72),
            border: Border(
              top: BorderSide(
                color: (dark ? Colors.white : scheme.outlineVariant)
                    .withValues(alpha: 0.08),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        spec: destinations[i],
                        selected: currentIndex == i,
                        accent: style.accent,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? accent : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              selected ? spec.selectedIcon : spec.icon,
              key: ValueKey(selected),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';

/// Account functions screen. Skeleton: actions are placeholders.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                _AvatarRing(style: style),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: style.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    '#0',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: style.accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _Group(
            children: [
              SettingsTile(
                icon: Icons.image_outlined,
                title: l10n.changeAvatar,
                onTap: () {},
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.badge_outlined,
                title: l10n.changeName,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            children: [
              SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: l10n.subscription,
                onTap: () {},
                trailing: _Pill(text: 'FREE', color: scheme.onSurfaceVariant),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () {},
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfUse,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            children: [
              SettingsTile(
                icon: Icons.logout,
                title: l10n.logout,
                showChevron: false,
                onTap: () {},
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: l10n.deleteData,
                danger: true,
                showChevron: false,
                onTap: () {},
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: l10n.deleteAccount,
                danger: true,
                showChevron: false,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 76, right: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.style});
  final AppStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(3),
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
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHigh,
              child:
                  Icon(Icons.person, size: 46, color: scheme.onSurfaceVariant),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: style.accent,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
              ),
              child: Icon(
                Icons.photo_camera,
                size: 15,
                color: style.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

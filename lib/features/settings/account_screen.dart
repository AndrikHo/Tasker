import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';

/// Account functions screen, bento-style: a profile hero tile followed by
/// grouped action tiles. Actions are placeholders until auth lands.
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
        padding: const EdgeInsets.fromLTRB(kBentoPad, 8, kBentoPad, 40),
        children: [
          // Profile hero.
          BentoTile(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _AvatarRing(style: style, size: 76),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.profile,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: style.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          '#0',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: style.accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kBentoGap),
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
          const SizedBox(height: kBentoGap),
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
          const SizedBox(height: kBentoGap),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
  const _AvatarRing({required this.style, this.size = 104});
  final AppStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
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
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHigh,
              child: Icon(Icons.person,
                  size: size * 0.42, color: scheme.onSurfaceVariant),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: style.accent,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 3),
              ),
              child: Icon(
                Icons.photo_camera,
                size: 13,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';

/// Supported UI languages (must match ARB files in lib/l10n/arb).
const supportedLanguages = <String, String>{
  'en': 'English',
  'ko': '한국어',
  'ru': 'Русский',
  'es': 'Español',
  'zh': '中文',
  'hi': 'हिन्दी',
  'ar': 'العربية',
  'pt': 'Português',
  'ja': '日本語',
  'fr': 'Français',
  'de': 'Deutsch',
  'id': 'Bahasa Indonesia',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final style = ref.watch(styleProvider);
    final buddies = ref.watch(buddyEnabledProvider);
    final locale = ref.watch(localeProvider);
    final langLabel =
        locale == null ? null : supportedLanguages[locale.languageCode];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            BentoHeader(title: l10n.settingsTitle),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kBentoPad),
              child: _Group(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: l10n.account,
                    subtitle: '#0',
                    onTap: () => context.go('/settings/account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kBentoGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kBentoPad),
              child: _Group(
                children: [
                  SettingsTile(
                    icon: Icons.language,
                    title: l10n.language,
                    subtitle: langLabel,
                    onTap: () => _showLanguagePicker(context, ref),
                  ),
                  _GroupDivider(),
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.theme,
                    showChevron: false,
                    trailing: _ThemeSegment(themeMode: themeMode),
                  ),
                  _GroupDivider(),
                  SettingsTile(
                    icon: Icons.emoji_emotions_outlined,
                    title: l10n.buddies,
                    subtitle: l10n.buddiesHint,
                    showChevron: false,
                    onTap: () =>
                        ref.read(buddyEnabledProvider.notifier).toggle(),
                    trailing: Switch(
                      value: buddies,
                      onChanged: (v) =>
                          ref.read(buddyEnabledProvider.notifier).set(v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(kBentoPad + 6, 0, kBentoPad, 12),
              child: Text(
                l10n.style.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kBentoPad),
              child: _StyleGrid(current: style),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            for (final entry in supportedLanguages.entries)
              _LanguageRow(
                code: entry.key,
                label: entry.value,
                selected: current?.languageCode == entry.key,
                onTap: () {
                  ref.read(localeProvider.notifier).set(Locale(entry.key));
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A grouped settings card: tiles laid out in a single elevated surface.
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

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? style.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(style.cardRadius),
          border: Border.all(
            color: selected ? style.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? scheme.onSurface : null,
                    ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: style.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

/// The visual-style picker as a 3-up bento grid of gradient-swatch tiles.
class _StyleGrid extends ConsumerWidget {
  const _StyleGrid({required this.current});
  final AppStyle current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = AppStyle.values;
    return Column(
      children: [
        for (var row = 0; row < styles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: kBentoGap),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: kBentoGap),
                Expanded(
                  child: row + col < styles.length
                      ? _StyleCard(
                          style: styles[row + col],
                          selected: styles[row + col] == current,
                          onTap: () => ref
                              .read(styleProvider.notifier)
                              .set(styles[row + col]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: style.motion,
        curve: style.curve,
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? style.accent.withValues(alpha: dark ? 0.18 : 0.14)
              : style.cardColor(dark),
          borderRadius: BorderRadius.circular(style.cardRadius),
          border: Border.all(
            color: selected ? style.accent : style.hairline(dark),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? null : style.cardShadow(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.chipRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.accent, style.accent2],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    style.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, size: 16, color: style.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.themeMode});
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
      ],
      selected: {themeMode},
      onSelectionChanged: (s) =>
          ref.read(themeModeProvider.notifier).set(s.first),
    );
  }
}

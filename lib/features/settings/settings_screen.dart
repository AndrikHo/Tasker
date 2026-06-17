import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
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
    final locale = ref.watch(localeProvider);
    final langLabel =
        locale == null ? null : supportedLanguages[locale.languageCode];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _Header(title: l10n.settingsTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                l10n.style.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
            _StylePicker(current: style),
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

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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

class _StylePicker extends ConsumerWidget {
  const _StylePicker({required this.current});
  final AppStyle current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppStyle.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = AppStyle.values[i];
          final selected = s == current;
          return GestureDetector(
            onTap: () => ref.read(styleProvider.notifier).set(s),
            child: AnimatedContainer(
              duration: s.motion,
              curve: s.curve,
              width: 104,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s.accent.withValues(alpha: selected ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(s.cardRadius),
                border: Border.all(
                  color: selected ? s.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [s.accent, s.accent2],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    s.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
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

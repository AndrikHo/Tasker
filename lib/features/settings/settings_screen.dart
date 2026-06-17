import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.account),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/account'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            trailing: _ThemeSegment(themeMode: themeMode),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in supportedLanguages.entries)
              ListTile(
                title: Text(entry.value),
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

class _ThemeSegment extends ConsumerWidget {
  const _ThemeSegment({required this.themeMode});
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto)),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
      ],
      selected: {themeMode},
      onSelectionChanged: (s) =>
          ref.read(themeModeProvider.notifier).set(s.first),
    );
  }
}

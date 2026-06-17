import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_providers.dart';

/// Avatar palette + faces offered when editing the local profile. A stand-in
/// until Supabase auth provides a real account with an uploaded photo.
const _avatarColors = <Color>[
  Color(0xFF22D3EE),
  Color(0xFF818CF8),
  Color(0xFFFB7185),
  Color(0xFFFBBF24),
  Color(0xFF4ADE80),
  Color(0xFFF472B6),
];

const _avatarEmojis = <String>[
  '🙂', '😎', '🚀', '🌟', '🐱', '🎧', '🦊', '🐼', '🔥', '🎮', '🌈', '⚡',
];

/// Account functions screen, bento-style: a profile hero tile followed by
/// grouped action tiles. Name and avatar are editable locally; backend-bound
/// actions give honest feedback until auth lands.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(kBentoPad, 8, kBentoPad, 40),
        children: [
          // Profile hero.
          BentoTile(
            padding: const EdgeInsets.all(20),
            onTap: () => _editAvatar(context, ref),
            child: Row(
              children: [
                _AvatarRing(profile: profile, style: style, size: 76),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name ?? l10n.profile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                onTap: () => _editAvatar(context, ref),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.badge_outlined,
                title: l10n.changeName,
                onTap: () => _editName(context, ref),
              ),
            ],
          ),
          const SizedBox(height: kBentoGap),
          _Group(
            children: [
              SettingsTile(
                icon: Icons.workspace_premium_outlined,
                title: l10n.subscription,
                onTap: () => showComingSoon(context, l10n.comingSoon),
                trailing: _Pill(text: 'FREE', color: scheme.onSurfaceVariant),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => showComingSoon(context, l10n.comingSoon),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfUse,
                onTap: () => showComingSoon(context, l10n.comingSoon),
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
                onTap: () => showComingSoon(context, l10n.signInRequired),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: l10n.deleteData,
                danger: true,
                showChevron: false,
                onTap: () => _confirmDeleteData(context, ref),
              ),
              _GroupDivider(),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: l10n.deleteAccount,
                danger: true,
                showChevron: false,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: ref.read(profileProvider).name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.nickname),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await ref.read(profileProvider.notifier).setName(name);
    }
  }

  Future<void> _editAvatar(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _AvatarSheet(),
    );
  }

  Future<void> _confirmDeleteData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: l10n.deleteData,
      message: l10n.deleteDataMessage,
      confirmLabel: l10n.delete,
    );
    if (ok != true || !context.mounted) return;
    ref.read(tasksProvider.notifier).clearAll();
    ref.read(listsProvider.notifier).reset();
    ref.read(friendsProvider.notifier).reset();
    await ref.read(profileProvider.notifier).clear();
    if (context.mounted) showComingSoon(context, l10n.dataDeleted);
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountMessage,
      confirmLabel: l10n.delete,
    );
    if (ok == true && context.mounted) {
      showComingSoon(context, l10n.signInRequired);
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Emoji + color picker that writes straight to the profile.
class _AvatarSheet extends ConsumerWidget {
  const _AvatarSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: profile.color.withValues(alpha: 0.22),
                  border: Border.all(color: profile.color, width: 2),
                ),
                alignment: Alignment.center,
                child:
                    Text(profile.emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.chooseAvatar.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in _avatarColors)
                  GestureDetector(
                    onTap: () => notifier.setAvatar(
                        emoji: profile.emoji, colorValue: c.toARGB32()),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.toARGB32() == profile.colorValue
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: c.toARGB32() == profile.colorValue
                          ? Icon(Icons.check,
                              size: 20,
                              color: c.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in _avatarEmojis)
                  GestureDetector(
                    onTap: () => notifier.setAvatar(
                        emoji: e, colorValue: profile.colorValue),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e == profile.emoji
                            ? profile.color.withValues(alpha: 0.20)
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: e == profile.emoji
                              ? profile.color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
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
  const _AvatarRing({
    required this.profile,
    required this.style,
    this.size = 104,
  });
  final Profile profile;
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
                colors: [profile.color, style.accent2],
              ),
              boxShadow: [
                BoxShadow(
                  color: profile.color.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: scheme.surfaceContainerHigh,
              child: Text(
                profile.emoji,
                style: TextStyle(fontSize: size * 0.40),
              ),
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

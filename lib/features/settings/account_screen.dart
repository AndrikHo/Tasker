import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/settings_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/auth/auth_providers.dart';
import '../../data/repositories/repository_providers.dart';
import '../../l10n/app_localizations.dart';
import '../characters/character.dart';
import '../characters/character_art.dart';
import '../tasks/task_providers.dart';

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
    final character = ref.watch(characterProvider);

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
                _AvatarRing(character: character, style: style, size: 76),
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
              if (ref.watch(backendConfiguredProvider)) ...[
                SettingsTile(
                  icon: Icons.logout,
                  title: l10n.logout,
                  showChevron: false,
                  onTap: () => _confirmLogout(context, ref),
                ),
                _GroupDivider(),
              ],
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
      // Mirror the display name to the backend profile when signed in.
      final repo = ref.read(taskerRepositoryProvider);
      if (repo != null) {
        final updated = ref.read(profileProvider);
        try {
          await repo.updateMyProfile(updated);
        } catch (_) {
          // Local change still applies; surfaced on next profile sync.
        }
      }
    }
  }

  Future<void> _editAvatar(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _CharacterSheet(),
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
    final repo = ref.read(taskerRepositoryProvider);
    // clearAll() routes to the backend when signed in, else clears local state.
    ref.read(tasksProvider.notifier).clearAll();
    if (repo == null) {
      ref.read(listsProvider.notifier).reset();
      ref.read(friendsProvider.notifier).reset();
      await ref.read(profileProvider.notifier).clear();
    }
    if (context.mounted) showComingSoon(context, l10n.dataDeleted);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: l10n.logout,
      message: l10n.logoutMessage,
      confirmLabel: l10n.logout,
    );
    if (ok != true) return;
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (_) {
      // Sign-out failures are non-fatal; the auth gate reacts to state.
    }
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
    if (ok != true) return;
    final repo = ref.read(taskerRepositoryProvider);
    if (repo == null) {
      if (context.mounted) showComingSoon(context, l10n.signInRequired);
      return;
    }
    try {
      await repo.deleteAccount();
      await ref.read(authServiceProvider).signOut();
    } catch (_) {
      if (context.mounted) showComingSoon(context, l10n.genericError);
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

/// Character picker that sets the avatar and, with it, the whole app theme.
/// Tapping a character applies it immediately; the sheet stays open so the
/// theme change is visible behind it.
class _CharacterSheet extends ConsumerWidget {
  const _CharacterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.watch(characterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CharacterArt(character: current, size: 92),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                current.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final c in kCharacters)
                  GestureDetector(
                    onTap: () =>
                        ref.read(characterProvider.notifier).set(c),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.id == current.id
                              ? c.color
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CharacterArt(character: c, size: 56),
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
    required this.character,
    required this.style,
    this.size = 104,
  });
  final Character character;
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
                colors: [character.color, style.accent2],
              ),
              boxShadow: [
                BoxShadow(
                  color: character.color.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: scheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: CharacterArt(character: character, size: size - 6),
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

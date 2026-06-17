import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Account functions screen. Skeleton: actions are placeholders.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person, size: 44, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                // Account id placeholder (ids start at #0 per spec).
                Text('#0', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Tile(icon: Icons.image_outlined, label: l10n.changeAvatar),
          _Tile(icon: Icons.badge_outlined, label: l10n.changeName),
          const Divider(),
          _Tile(icon: Icons.workspace_premium_outlined, label: l10n.subscription),
          _Tile(icon: Icons.privacy_tip_outlined, label: l10n.privacyPolicy),
          _Tile(icon: Icons.description_outlined, label: l10n.termsOfUse),
          const Divider(),
          _Tile(icon: Icons.logout, label: l10n.logout),
          _Tile(
            icon: Icons.delete_sweep_outlined,
            label: l10n.deleteData,
            danger: true,
          ),
          _Tile(
            icon: Icons.delete_forever_outlined,
            label: l10n.deleteAccount,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () {},
    );
  }
}

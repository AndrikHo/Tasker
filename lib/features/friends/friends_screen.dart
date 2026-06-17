import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Friends and groups. Skeleton only.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: l10n.addFriend,
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Text(
          l10n.emptyFriends,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

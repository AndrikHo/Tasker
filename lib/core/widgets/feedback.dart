import 'package:flutter/material.dart';

/// Shows a transient snackbar so a tap never feels dead. Used for actions that
/// are intentionally stubbed until the backend (auth, voice, camera) lands.
void showComingSoon(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

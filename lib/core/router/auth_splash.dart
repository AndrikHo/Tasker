import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_style.dart';

/// Minimal themed splash shown while the auth state is still resolving, so the
/// app never flashes the wrong screen before the gate decides. The ambient
/// background is painted by the app-level builder; this sits on top.
class AuthSplash extends ConsumerWidget {
  const AuthSplash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(styleProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.accent, style.accent2],
                ),
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: style.onAccent,
                size: 34,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(style.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_style.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/auth/auth_models.dart';
import '../../data/auth/auth_providers.dart';
import '../../l10n/app_localizations.dart';

/// Email + password sign-in / sign-up screen shown by the auth gate when the
/// backend is configured and no user is signed in. Themed via [styleProvider]
/// so it belongs to the rest of the app (ambient background is painted by the
/// app-level builder; this screen lays its card on top).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _createMode = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  /// Set after a sign-up that requires email confirmation (user, no session).
  bool _awaitingConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    return ok ? null : AppLocalizations.of(context).emailInvalid;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    return v.length >= 6
        ? null
        : AppLocalizations.of(context).passwordTooShort;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _loading = true;
      _error = null;
      _awaitingConfirmation = false;
    });

    try {
      if (_createMode) {
        await auth.signUpWithPassword(
          email,
          password,
          displayName: _nameController.text.trim(),
        );
        // Sign-up returns a live session; authStateProvider drives navigation.
      } else {
        await auth.signInWithPassword(email, password);
        // authStateProvider drives navigation on success.
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).authFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _createMode = !_createMode;
      _error = null;
      _awaitingConfirmation = false;
    });
  }

  /// Social sign-in (Google/Apple) lands via a browser redirect + deep link;
  /// that wiring is added in a follow-up. Until then, tapping a provider shows a
  /// clear notice so the buttons are never silent dead ends.
  void _oauth(SocialProvider provider) {
    FocusScope.of(context).unfocus();
    showComingSoon(context, AppLocalizations.of(context).comingSoon);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(styleProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(style: style),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    child: _awaitingConfirmation
                        ? _ConfirmationNotice(
                            email: _emailController.text.trim(),
                            onBack: () => setState(
                                () => _awaitingConfirmation = false),
                          )
                        : _buildForm(context, l10n, style, theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    AppStyle style,
    ThemeData theme,
  ) {
    final scheme = theme.colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _createMode ? l10n.createAccount : l10n.signIn,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          if (_createMode) ...[
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              enabled: !_loading,
              decoration: _decoration(
                style,
                label: l10n.nickname,
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            validator: _validateEmail,
            decoration: _decoration(
              style,
              label: l10n.email,
              icon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !_loading,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
            decoration: _decoration(
              style,
              label: l10n.password,
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: _loading
                    ? null
                    : () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: style.accent,
                foregroundColor: style.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(style.buttonRadius),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(style.onAccent),
                      ),
                    )
                  : Text(
                      _createMode ? l10n.createAccount : l10n.signIn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _toggleMode,
              child: Text(
                _createMode ? l10n.haveAccountPrompt : l10n.noAccountPrompt,
                style: TextStyle(
                  color: style.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _SocialDivider(label: l10n.orContinueWith),
          const SizedBox(height: 18),
          _SocialRow(
            enabled: !_loading,
            onTap: _oauth,
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    AppStyle style, {
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: scheme.onSurfaceVariant),
      suffixIcon: suffix,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.chipRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.chipRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(style.chipRadius),
        borderSide: BorderSide(color: style.accent, width: 2),
      ),
    );
  }
}

/// "or continue with" divider with hairlines on both sides.
class _SocialDivider extends StatelessWidget {
  const _SocialDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant.withValues(alpha: 0.6);
    return Row(
      children: [
        Expanded(child: Divider(color: line, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(child: Divider(color: line, thickness: 1)),
      ],
    );
  }
}

/// Row of social sign-in buttons. Each provider lights up once it is enabled in
/// the Supabase dashboard; tapping one before then surfaces a clear error.
class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.enabled, required this.onTap});

  final bool enabled;
  final void Function(SocialProvider provider) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          label: 'Google',
          background: Colors.white,
          foreground: const Color(0xFF1F1F1F),
          border: const Color(0xFFDADCE0),
          onPressed: enabled ? () => onTap(SocialProvider.google) : null,
          child: const _GoogleGlyph(),
        ),
        const SizedBox(width: 14),
        _SocialButton(
          label: 'Kakao',
          background: const Color(0xFFFEE500),
          foreground: const Color(0xFF191600),
          onPressed: enabled ? () => onTap(SocialProvider.kakao) : null,
          child: const Icon(Icons.chat_bubble, size: 22),
        ),
        const SizedBox(width: 14),
        _SocialButton(
          label: 'Facebook',
          background: const Color(0xFF1877F2),
          foreground: Colors.white,
          onPressed: enabled ? () => onTap(SocialProvider.facebook) : null,
          child: const Text(
            'f',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 14),
        _SocialButton(
          label: 'Apple',
          background: const Color(0xFF000000),
          foreground: Colors.white,
          onPressed: enabled ? () => onTap(SocialProvider.apple) : null,
          child: const Icon(Icons.apple, size: 24),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.child,
    required this.onPressed,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: border == null
              ? BorderSide.none
              : BorderSide(color: border!, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: IconTheme(
                data: IconThemeData(color: foreground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal multi-color Google "G" rendered without an asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
        height: 1.0,
      ),
    );
  }
}

/// Brand mark: a gradient app glyph plus the app name.
class _Brand extends StatelessWidget {
  const _Brand({required this.style});
  final AppStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.accent, style.accent2],
            ),
            boxShadow: [
              BoxShadow(
                color: style.accent.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.checklist_rounded,
            color: style.onAccent,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tasker',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

/// Shown after a sign-up that needs email confirmation.
class _ConfirmationNotice extends StatelessWidget {
  const _ConfirmationNotice({required this.email, required this.onBack});

  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_unread_outlined,
            size: 44, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.checkEmailTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.checkEmailMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(l10n.signIn),
        ),
      ],
    );
  }
}

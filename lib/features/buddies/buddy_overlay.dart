import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import 'buddy.dart';

/// When real art lands in `assets/mascots/`, flip this to `true` and wire the
/// asset path in [BuddyArt]. Until then we render colored placeholder blobs.
const bool kBuddyArtReady = false;

/// Overlays the app with a "LIFE FRIENDS" buddy that peeks in from a screen
/// edge now and then, when buddies are enabled.
///
/// Rules (kept deliberately gentle so it never annoys):
/// - only when [buddyEnabledProvider] is on,
/// - never while the OS asks to reduce motion (decorative animation),
/// - frequency-capped (long random gaps between appearances),
/// - tap the buddy to dismiss it early,
/// - lives in the lower band of the screen so it never covers the header or
///   the bottom nav, and only the buddy itself is tappable (the rest of the
///   screen stays fully interactive).
class BuddyOverlay extends ConsumerStatefulWidget {
  const BuddyOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BuddyOverlay> createState() => _BuddyOverlayState();
}

class _BuddyOverlayState extends ConsumerState<BuddyOverlay>
    with SingleTickerProviderStateMixin {
  static const _size = 132.0;
  static const _visibleFraction = 0.62; // how much of the buddy peeks out

  final _rng = math.Random();
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    reverseDuration: const Duration(milliseconds: 420),
  );

  Timer? _timer;
  Buddy? _buddy;
  bool _fromLeft = true;
  double _bottom = 160;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(buddyEnabledProvider)) {
        _scheduleNext(first: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _scheduleNext({bool first = false, bool soon = false}) {
    _timer?.cancel();
    if (!ref.read(buddyEnabledProvider)) return;
    final Duration delay;
    if (first) {
      delay = const Duration(seconds: 11);
    } else if (soon) {
      delay = const Duration(seconds: 18);
    } else {
      delay = Duration(seconds: 34 + _rng.nextInt(46)); // 34-80s
    }
    _timer = Timer(delay, _peek);
  }

  void _peek() {
    if (!mounted || !ref.read(buddyEnabledProvider) || _buddy != null) {
      _scheduleNext();
      return;
    }
    // Respect the OS "reduce motion" setting: skip the animation entirely.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _scheduleNext();
      return;
    }
    final size = MediaQuery.of(context).size;
    setState(() {
      _buddy = kBuddies[_rng.nextInt(kBuddies.length)];
      _fromLeft = _rng.nextBool();
      // Lower band, clear of the header and the bottom nav bar.
      final maxBottom = math.max(150.0, size.height * 0.42);
      _bottom = 130 + _rng.nextDouble() * (maxBottom - 130);
    });
    _ctrl.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 4600), _retreat);
  }

  void _retreat() {
    if (!mounted || _buddy == null) return;
    _ctrl.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _buddy = null);
      _scheduleNext();
    });
  }

  void _dismiss() {
    _timer?.cancel();
    _retreat();
  }

  @override
  Widget build(BuildContext context) {
    // React to the toggle flipping while the app is open.
    ref.listen<bool>(buddyEnabledProvider, (prev, next) {
      if (next) {
        if (_buddy == null) _scheduleNext(first: true);
      } else {
        _timer?.cancel();
        if (_buddy != null) _retreat();
      }
    });

    final buddy = _buddy;
    return Stack(
      children: [
        widget.child,
        if (buddy != null)
          Positioned(
            bottom: _bottom,
            left: _fromLeft ? 0 : null,
            right: _fromLeft ? null : 0,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final t = Curves.easeOutBack.transform(
                    _ctrl.value.clamp(0.0, 1.0),
                  );
                  final hidden = _size * (1 - _visibleFraction * t);
                  final dx = _fromLeft ? -hidden : hidden;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.rotate(
                      angle: (_fromLeft ? 1 : -1) * 0.06,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _dismiss,
                  child: BuddyArt(buddy: buddy, size: _size),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Renders a buddy. Uses the generated PNG when [kBuddyArtReady] is set,
/// otherwise a colored placeholder blob so the system is fully testable today.
class BuddyArt extends StatelessWidget {
  const BuddyArt({super.key, required this.buddy, this.size = 120});

  final Buddy buddy;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kBuddyArtReady) {
      return Image.asset(buddy.asset, width: size, height: size);
    }
    return _PlaceholderBlob(buddy: buddy, size: size);
  }
}

class _PlaceholderBlob extends StatelessWidget {
  const _PlaceholderBlob({required this.buddy, required this.size});

  final Buddy buddy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = buddy.color;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(Colors.white.withValues(alpha: 0.22), c),
                  c,
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.42),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          // Glossy highlight, top-left, for a soft toy look.
          Positioned(
            top: size * 0.16,
            left: size * 0.18,
            child: Container(
              width: size * 0.22,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Text(buddy.face, style: TextStyle(fontSize: size * 0.46)),
        ],
      ),
    );
  }
}

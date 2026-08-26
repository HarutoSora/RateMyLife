import 'dart:math';

import 'package:flutter/material.dart';

/// Shared, lightweight animation building blocks for the app's "neon
/// arcade" gamified moments (Life Battles, Nuke, rewards, etc.) — built
/// entirely from `AnimationController`/`TweenAnimationBuilder`/
/// `CustomPainter`, no external animation package. Extracted from the
/// Life Battles screen so every feature that wants a number count-up, a
/// pulsing glow, or a one-shot particle burst reuses the same three
/// widgets instead of re-implementing them per screen.

/// Every sound-worthy beat across the game-ified features (Life
/// Battles, Nuke/Cure, Would You Choose, the ad reward). No audio
/// package exists in this project yet — per this project's "don't add
/// dependencies unless necessary" rule, [playSfx] is intentionally a
/// no-op for now. It exists so every call site is already wired to the
/// right event; adding a real audio player later is a one-line change
/// inside [playSfx] itself, with zero changes anywhere else.
enum AppSfx {
  battleIntro,
  battleSelect,
  battleLockIn,
  battleReveal,
  battleReward,
  nukeLaunch,
  nukeImpact,
  cureStart,
  cureComplete,
  choiceSelect,
  choiceReveal,
  adRewardClaimed,
}

void playSfx(AppSfx event) {
  // Intentionally empty — see AppSfx's doc comment above.
}

/// A number that animates from 0 (or its previous value) up to [value]
/// whenever [value] changes — the same idiom already used by
/// `ScoreTile`/`ScoreBadge`, exposed here for screens that don't already
/// have their own copy.
class AnimatedCountUp extends StatelessWidget {
  const AnimatedCountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    required this.style,
    this.duration = const Duration(milliseconds: 700),
    this.decimals = 0,
    this.textKey,
  });

  final double value;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final Duration duration;

  /// 0 for whole numbers (default), 1 for one decimal place, etc.
  final int decimals;

  /// Key applied to the inner `Text` itself (not this wrapper widget) —
  /// for the rare case a widget test needs to find/read the rendered
  /// text directly (e.g. `find.byKey` + `tester.widget<Text>`).
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${v.toStringAsFixed(decimals)}$suffix', key: textKey, style: style),
    );
  }
}

/// Wraps [child] in a soft, continuously pulsing glow driven by a
/// repeating [controller] (0..1) — used for idle "this is alive" moments
/// (a VS badge, a CTA button) rather than a one-shot effect.
class PulseGlow extends StatelessWidget {
  const PulseGlow({
    super.key,
    required this.controller,
    required this.color,
    required this.child,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.minGlow = 10,
    this.maxGlow = 26,
  });

  final Animation<double> controller;
  final Color color;
  final Widget child;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final double minGlow;
  final double maxGlow;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (sin(controller.value * 2 * pi) + 1) / 2;
        final glow = minGlow + (maxGlow - minGlow) * t;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35 + t * 0.35),
                blurRadius: glow,
                spreadRadius: 1 + t * 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// A lightweight, reusable one-shot particle burst — a single
/// `CustomPaint` drawing a handful of fading circles outward from
/// center. Owns its own `AnimationController` (created/disposed with
/// this widget), so parents never need to track it: Flutter plays it
/// once when first inserted into the tree and disposes it when removed.
class BurstFx extends StatefulWidget {
  const BurstFx({
    super.key,
    required this.colors,
    this.particleCount = 18,
    this.duration = const Duration(milliseconds: 700),
    this.radius = 90,
  });

  final List<Color> colors;
  final int particleCount;
  final Duration duration;
  final double radius;

  @override
  State<BurstFx> createState() => _BurstFxState();
}

class _BurstFxState extends State<BurstFx> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
    final rng = Random();
    _particles = List.generate(widget.particleCount, (i) {
      final angle = (2 * pi / widget.particleCount) * i + rng.nextDouble() * 0.4;
      final distance = widget.radius * (0.6 + rng.nextDouble() * 0.4);
      final color = widget.colors[rng.nextInt(widget.colors.length)];
      final size = 3.0 + rng.nextDouble() * 4;
      return _Particle(angle: angle, distance: distance, color: color, size: size);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(progress: _controller.value, particles: _particles),
          size: Size(widget.radius * 2.4, widget.radius * 2.4),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({required this.angle, required this.distance, required this.color, required this.size});

  final double angle;
  final double distance;
  final Color color;
  final double size;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (final p in particles) {
      final dx = cos(p.angle) * p.distance * eased;
      final dy = sin(p.angle) * p.distance * eased;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawCircle(center + Offset(dx, dy), p.size * (1 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Animates a handful of small coin glyphs flying from [fromKey]'s
/// current on-screen position to [toKey]'s — e.g. a reward icon flying
/// toward a coin-balance pill elsewhere on screen. Inserted directly
/// into the enclosing `Overlay` (so it draws above the bottom sheet/
/// dialog it was triggered from) and self-removes once every particle
/// finishes. A no-op if either widget isn't currently laid out (e.g. the
/// balance pill isn't on screen at all) — never throws.
void flyCoinsToBalance(
  BuildContext context, {
  required GlobalKey fromKey,
  required GlobalKey toKey,
  int count = 6,
}) {
  final fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
  final toBox = toKey.currentContext?.findRenderObject() as RenderBox?;
  if (fromBox == null || toBox == null || !fromBox.attached || !toBox.attached) return;

  final overlay = Overlay.of(context, rootOverlay: true);
  final start = fromBox.localToGlobal(fromBox.size.center(Offset.zero));
  final end = toBox.localToGlobal(toBox.size.center(Offset.zero));
  final rng = Random();

  for (var i = 0; i < count; i++) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingCoin(
        start: start + Offset(rng.nextDouble() * 16 - 8, rng.nextDouble() * 16 - 8),
        end: end,
        delay: Duration(milliseconds: i * 50),
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyingCoin extends StatefulWidget {
  const _FlyingCoin({required this.start, required this.end, required this.delay, required this.onDone});

  final Offset start;
  final Offset end;
  final Duration delay;
  final VoidCallback onDone;

  @override
  State<_FlyingCoin> createState() => _FlyingCoinState();
}

class _FlyingCoinState extends State<_FlyingCoin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _controller.forward().whenComplete(widget.onDone);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInCubic.transform(_controller.value);
        final dx = widget.start.dx + (widget.end.dx - widget.start.dx) * t;
        // A slight upward arc partway through, dipping back down to the
        // target — a straight line reads as sliding, not "flying".
        final arc = sin(t * pi) * -40;
        final dy = widget.start.dy + (widget.end.dy - widget.start.dy) * t + arc;
        final scale = 1 - t * 0.4;
        final opacity = t < 0.8 ? 1.0 : (1 - t) / 0.2;
        return Positioned(
          left: dx - 10,
          top: dy - 10,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC530), size: 20),
            ),
          ),
        );
      },
    );
  }
}

// Animated 3D-style visuals built with pure Flutter.
//
// No image assets or extra packages are used — the "3D images" are drawn with
// real perspective matrices (Matrix4) and layered icon extrusion, then
// animated on a loop. This keeps the app lightweight while giving the Login
// and Home screens a lively, tactile hero.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Global switch so widget tests can keep frames stable. Set to false in tests
/// to avoid never-ending `pumpAndSettle` loops from the looping heroes.
bool kHeroAnimationsEnabled = true;

// ---------------------------------------------------------------------------
// Motion wrappers
// ---------------------------------------------------------------------------

/// Gently swings [child] in 3D space using a perspective matrix while floating
/// it up and down. This is the core "animated 3D image" wrapper.
class Showcase3D extends StatefulWidget {
  const Showcase3D({
    super.key,
    required this.child,
    this.tilt = 0.16,
    this.float = 10,
    this.period = const Duration(seconds: 6),
    this.perspective = 0.0014,
  });

  final Widget child;

  /// Max Y-axis swing (radians) applied by the loop.
  final double tilt;

  /// Vertical float distance in logical pixels.
  final double float;

  final Duration period;

  /// Strength of the perspective divide (bigger = more dramatic depth).
  final double perspective;

  @override
  State<Showcase3D> createState() => _Showcase3DState();
}

class _Showcase3DState extends State<Showcase3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
    if (kHeroAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value * 2 * math.pi;
        final swing = math.sin(t) * widget.tilt;
        final bob = math.cos(t) * widget.float;
        final m = Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(swing * 0.5)
          ..rotateY(swing);
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Fades and slides [child] into place once, used to stage sections.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 18),
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide =
        Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Glow helpers
// ---------------------------------------------------------------------------

/// Static soft radial glow used to add depth behind hero content.
class GlowOrb extends StatelessWidget {
  const GlowOrb({super.key, required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

/// Slowly pulsing glow for ambient movement in the hero.
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.diameter,
    required this.color,
    this.period = const Duration(seconds: 5),
  });

  final double diameter;
  final Color color;
  final Duration period;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
    if (kHeroAnimationsEnabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = 0.85 + 0.15 * math.sin(_c.value * 2 * math.pi);
        return Transform.scale(
          scale: s,
          child: GlowOrb(diameter: widget.diameter, color: widget.color),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Extruded "3D" icon
// ---------------------------------------------------------------------------

/// A chunky, extruded icon built from stacked copies of a Material glyph so it
/// reads as a small solid 3D object. Brand-coloured and cheap to draw.
class Extruded3DIcon extends StatelessWidget {
  const Extruded3DIcon({
    super.key,
    required this.icon,
    this.size = 96,
    this.depth = 3,
    this.layers = 9,
    this.front = Colors.white,
    this.side = const Color(0xFF0B5D2E),
  });

  final IconData icon;
  final double size;
  final double depth;
  final int layers;
  final Color front;
  final Color side;

  @override
  Widget build(BuildContext context) {
    final span = depth * layers;
    return SizedBox(
      width: size + span,
      height: size + span,
      child: Transform.translate(
        offset: Offset(-span / 2, -span / 2),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Back-to-front extrusion; deeper layers darken for volume.
            for (var i = layers; i >= 1; i--)
              Transform.translate(
                offset: Offset(i * depth, i * depth),
                child: Icon(
                  icon,
                  size: size,
                  color: Color.lerp(side, Colors.black, i / (layers * 2.4)),
                ),
              ),
            // Front face with a soft drop shadow for lift.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: size, color: front),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ready-made animated hero: a pulsing glow behind an extruded 3D icon that
/// swings and floats on a loop. Drop it into a Login or Home hero.
class Floating3DHero extends StatelessWidget {
  const Floating3DHero({
    super.key,
    required this.icon,
    this.size = 96,
    this.front = Colors.white,
    this.side = const Color(0xFF0B5D2E),
    this.glow,
    this.depth = 3,
    this.layers = 9,
    this.period = const Duration(seconds: 6),
  });

  final IconData icon;
  final double size;
  final Color front;
  final Color side;
  final Color? glow;
  final double depth;
  final int layers;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    return Showcase3D(
      period: period,
      tilt: 0.20,
      float: size * 0.06,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow != null) PulsingGlow(diameter: size * 1.9, color: glow!),
          Extruded3DIcon(
            icon: icon,
            size: size,
            depth: depth,
            layers: layers,
            front: front,
            side: side,
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

import '../../main.dart' show resolveStartScreen;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconRotate;
  late final Animation<Offset> _iconSlide;

  late final AnimationController _nameCtrl;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameScale;

  late final AnimationController _dotsCtrl;
  late final Animation<double> _dotsOpacity;

  late final AnimationController _particleCtrl;

  late final AnimationController _orbCtrl;
  late final Animation<double> _orbOpacity;

  late final AnimationController _ringCtrl;
  late final Animation<double> _ringOpacity;

  late final AnimationController _earCtrl;
  late final Animation<double> _earL;
  late final Animation<double> _earR;

  late final AnimationController _bobCtrl;

  late final AnimationController _blinkCtrl;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();

    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _iconScale   = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _iconCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _iconRotate  = Tween(begin: -0.12, end: 0.0).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconSlide   = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));

    _nameCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));
    _nameSlide   = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.elasticOut));
    _nameScale   = Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.elasticOut));

    _dotsCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _dotsOpacity = Tween(begin: 0.0, end: 1.0).animate(_dotsCtrl);

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _orbCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbOpacity = Tween(begin: 0.0, end: 0.45).animate(CurvedAnimation(parent: _orbCtrl, curve: const Interval(0.0, 0.15)));

    _ringCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _ringOpacity = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.0, 0.1, curve: Curves.easeIn)));

    _earCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _earL = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _earCtrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _earR = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _earCtrl, curve: const Interval(0.3, 1.0, curve: Curves.elasticOut)));

    _bobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);

    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _blink     = Tween(begin: 1.0, end: 0.05).animate(CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    final nextScreenFuture = resolveStartScreen();

    await Future.delayed(const Duration(milliseconds: 300));
    _iconCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 520));
    _earCtrl.forward();
    _particleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 280));
    _nameCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _dotsCtrl.forward();

    _startBlinking();

    final results = await Future.wait([
      nextScreenFuture,
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);

    _navigate(results[0] as Widget);
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 3500));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      await _blinkCtrl.reverse();
    }
  }

  void _navigate(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _nameCtrl.dispose();
    _dotsCtrl.dispose();
    _particleCtrl.dispose();
    _orbCtrl.dispose();
    _ringCtrl.dispose();
    _earCtrl.dispose();
    _bobCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgStart   = isDark ? const Color(0xFF3A1E7A) : const Color(0xFFB0D8F0);
    final bgMid     = isDark ? const Color(0xFF2A1568) : const Color(0xFFB8A8E8);
    final bgEnd     = isDark ? const Color(0xFF160D40) : const Color(0xFFE8B8F0);
    final iconG1    = isDark ? const Color(0xFF6080E0) : const Color(0xFFA0B8F8);
    final iconG2    = isDark ? const Color(0xFF8060D8) : const Color(0xFFC0A0F0);
    final iconG3    = isDark ? const Color(0xFFC080E8) : const Color(0xFFE0A8F8);
    final nameColor = isDark ? Colors.white : const Color(0xFF2D2D4E);
    final dotIdle   = isDark ? Colors.white.withOpacity(0.28) : const Color(0xFF503C8C).withOpacity(0.3);
    final dotActive = isDark ? Colors.white.withOpacity(0.88) : const Color(0xFF503C8C).withOpacity(0.75);
    final ringColor = Colors.white.withOpacity(isDark ? 0.4 : 0.6);
    final glowColor = isDark
        ? const Color(0xFF6432C8).withOpacity(0.65)
        : const Color(0xFF8C64C8).withOpacity(0.45);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.6),
                radius: 1.4,
                colors: [bgStart, bgMid, bgEnd],
              ),
            ),
          ),

          // Orb top-left
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) {
              final t = _orbCtrl.value;
              return Positioned(
                top: -80 + 15 * sin(t * pi),
                left: -50 + 20 * sin(t * pi),
                child: Opacity(
                  opacity: _orbOpacity.value,
                  child: _orb(240, iconG1.withOpacity(0.55)),
                ),
              );
            },
          ),

          // Orb bottom-right
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) {
              final t = _orbCtrl.value;
              return Positioned(
                bottom: -50 - 20 * sin(t * pi * 0.9),
                right: -40 - 15 * sin(t * pi * 1.2),
                child: Opacity(
                  opacity: _orbOpacity.value,
                  child: _orb(200, iconG3.withOpacity(0.5)),
                ),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating shimmer ring
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _ringOpacity.value,
                        child: Transform.rotate(
                          angle: _ringCtrl.value * 2 * pi,
                          child: Container(
                            width: 202,
                            height: 202,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(48),
                              border: Border.all(color: ringColor, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Particles
                    AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __) => SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: _buildParticles(_particleCtrl.value),
                        ),
                      ),
                    ),

                    // Icon
                    AnimatedBuilder(
                      animation: Listenable.merge([_iconCtrl, _bobCtrl]),
                      builder: (_, __) => Opacity(
                        opacity: _iconOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, -5 * sin(_bobCtrl.value * pi)),
                          child: SlideTransition(
                            position: _iconSlide,
                            child: Transform.rotate(
                              angle: _iconRotate.value,
                              child: ScaleTransition(
                                scale: _iconScale,
                                child: _buildIcon(iconG1, iconG2, iconG3, ringColor, glowColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // App name
                AnimatedBuilder(
                  animation: _nameCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _nameOpacity.value,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: ScaleTransition(
                        scale: _nameScale,
                        child: Text(
                          'Safe Space',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: nameColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 44),

                // Dots
                FadeTransition(
                  opacity: _dotsOpacity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dot(dotIdle),
                      const SizedBox(width: 9),
                      _dot(dotActive),
                      const SizedBox(width: 9),
                      _dot(dotIdle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _dot(Color color) => Container(
        width: 9, height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _buildIcon(Color g1, Color g2, Color g3, Color ringColor, Color glowColor) {
    return Container(
      width: 176,
      height: 176,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [g1, g2, g3],
        ),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 50, spreadRadius: 4, offset: const Offset(0, 18)),
        ],
      ),
      child: Center(
        child: Container(
          width: 148,
          height: 144,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: ringColor, width: 2),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bottom gradient bar
              Positioned(
                bottom: 10,
                child: Container(
                  width: 56, height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(colors: [Color(0xFF60B0FF), Color(0xFFE060F0)]),
                  ),
                ),
              ),

              // Left ear dot
              Positioned(
                left: -2,
                child: AnimatedBuilder(
                  animation: _earCtrl,
                  builder: (_, __) => Transform.scale(scale: _earL.value, child: _earDot()),
                ),
              ),

              // Right ear dot
              Positioned(
                right: -2,
                child: AnimatedBuilder(
                  animation: _earCtrl,
                  builder: (_, __) => Transform.scale(scale: _earR.value, child: _earDot()),
                ),
              ),

              // Face painter
              AnimatedBuilder(
                animation: _blinkCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(120, 120),
                  painter: _FacePainter(eyeScaleY: _blink.value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earDot() => Container(
        width: 12, height: 12,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF60C8FF)),
      );

  List<Widget> _buildParticles(double t) {
    const configs = [
      _PC(color: Color(0xFFA0C8FF), dx: -75, dy: -65),
      _PC(color: Color(0xFFD0A0F8), dx:  75, dy: -65),
      _PC(color: Color(0xFFF0A8D0), dx: -95, dy:  10),
      _PC(color: Color(0xFF80D8C0), dx:  95, dy:  10),
      _PC(color: Color(0xFFFFD080), dx: -55, dy:  75),
      _PC(color: Color(0xFFA0E8A0), dx:  55, dy:  75),
      _PC(color: Color(0xFFC0B0FF), dx: -35, dy: -90),
      _PC(color: Color(0xFFFFA0B0), dx:  35, dy: -90),
    ];
    return configs.map((c) {
      final p = Curves.easeOut.transform(t.clamp(0.0, 1.0));
      return Transform.translate(
        offset: Offset(c.dx * p * 1.4, c.dy * p * 1.4),
        child: Opacity(
          opacity: (1.0 - p).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: (1.0 - p * 0.5).clamp(0.0, 1.0),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.color),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _PC {
  final Color color;
  final double dx, dy;
  const _PC({required this.color, required this.dx, required this.dy});
}

// ─────────────────────────────────────────────
//  Face painter — headphones ON TOP of bubble
//  Canvas size: 120×120  →  center = (60, 60)
// ─────────────────────────────────────────────
class _FacePainter extends CustomPainter {
  final double eyeScaleY;
  const _FacePainter({required this.eyeScaleY});

  @override
  void paint(Canvas canvas, Size size) {
    const double cx = 60;
    const double cy = 60;

    // ── 1. Shadow under bubble ───────────────
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(cx, 114), width: 44, height: 7),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── 2. White chat bubble ─────────────────
    //   Rounded rect top + pointer tail at bottom
    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(cx - 34, cy - 36, 68, 58),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubbleRect, Paint()..color = Colors.white);

    // Tail (downward triangle)
    final tail = Path()
      ..moveTo(cx - 9, cy + 22)
      ..lineTo(cx,     cy + 36)
      ..lineTo(cx + 9, cy + 22)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white);

// ── 3. Headphone band — فوق الـ bubble ──
final bandPaint = Paint()
  ..color = const Color(0xFF1A1A2E)
  ..strokeWidth = 5.0
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

// المشكلة كانت هنا — خلي الـ arc يمشي فوق الراس
const double bandCY = cy - 22;   // ارفع أكتر للفوق
final bandRect = Rect.fromCenter(
  center: const Offset(cx, bandCY),
  width: 68,
  height: 44,
);
// من 210° لـ 330° (فوق الراس) — sweep موجب يمشي عكس عقارب الساعة
canvas.drawArc(bandRect, pi * 210 / 180, pi * 120 / 180, false, bandPaint);

// ── 4. Ear cups ──
final cupPaint = Paint()
  ..color = const Color(0xFF1A1A2E)
  ..style = PaintingStyle.fill;

// Left cup — اتحسب موقعه على طرف الـ arc
canvas.drawRRect(
  RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(cx - 34, cy - 20), width: 11, height: 19),
    const Radius.circular(5),
  ),
  cupPaint,
);

// Right cup
canvas.drawRRect(
  RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(cx + 34, cy - 20), width: 11, height: 19),
    const Radius.circular(5),
  ),
  cupPaint,
);
    // ── 5. Eyes with blink ───────────────────
    final eyePaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.save();
    canvas.translate(cx - 13, cy);
    canvas.scale(1.0, eyeScaleY);
    canvas.drawCircle(Offset.zero, 4.0, eyePaint);
    canvas.restore();

    // Right eye
    canvas.save();
    canvas.translate(cx + 13, cy);
    canvas.scale(1.0, eyeScaleY);
    canvas.drawCircle(Offset.zero, 4.0, eyePaint);
    canvas.restore();

    // ── 6. Blush ─────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 22, cy + 10), width: 13, height: 8),
      Paint()..color = const Color(0xFFFFB0C0).withOpacity(0.65),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 22, cy + 10), width: 13, height: 8),
      Paint()..color = const Color(0xFFFFB0C0).withOpacity(0.65),
    );

    // ── 7. Smile ─────────────────────────────
    final smilePath = Path()
      ..moveTo(cx - 13, cy + 14)
      ..quadraticBezierTo(cx, cy + 26, cx + 13, cy + 14);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.eyeScaleY != eyeScaleY;
}
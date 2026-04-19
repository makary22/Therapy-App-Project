import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Design tokens  (mirror TipPracticeTemplate)
// ─────────────────────────────────────────────
const Color _purple = Color(0xFF7B5EA7);
const Color _pink = Color(0xFFD45DA1);
const Color _bg = Color(0xFFF4F1F8);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E1F29);
const Color _textMuted = Color(0xFF888888);

// ─────────────────────────────────────────────
//  Data
// ─────────────────────────────────────────────
const _steps = [
  _StepData(
    icon: Icons.self_improvement_outlined,
    title: 'Relax your body',
    body: 'Walk at a gentle pace and relax your shoulders. Let your arms swing naturally.',
    accent: Color(0xFFB39DDB),
  ),
  _StepData(
    icon: Icons.directions_walk_outlined,
    title: 'Feel the ground',
    body: 'Notice how your feet touch the ground with each step — heel, arch, then toes.',
    accent: Color(0xFF9575CD),
  ),
  _StepData(
    icon: Icons.visibility_outlined,
    title: 'Engage your senses',
    body: 'Name 3 things you see clearly around you and 2 distinct sounds you can hear.',
    accent: Color(0xFFCE93D8),
  ),
  _StepData(
    icon: Icons.air_outlined,
    title: 'Breathe deeply',
    body: 'Take one slow, full breath every 20–30 seconds. Exhale for longer than you inhale.',
    accent: Color(0xFFF48FB1),
  ),
];

class _StepData {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  const _StepData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class GroundingWalkScreen extends StatefulWidget {
  const GroundingWalkScreen({super.key});

  @override
  State<GroundingWalkScreen> createState() => _GroundingWalkScreenState();
}

class _GroundingWalkScreenState extends State<GroundingWalkScreen>
    with TickerProviderStateMixin {
  // ── Timer state ──
  static const int _totalSeconds = 9 * 60; // 9 min mid-point
  int _elapsed = 0;
  bool _running = false;
  Timer? _timer;

  // ── Step completion ──
  final Set<int> _done = {};

  // ── Animations ──
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Timer helpers ──
  void _toggleTimer() {
    setState(() => _running = !_running);
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsed >= _totalSeconds) {
          _timer?.cancel();
          setState(() => _running = false);
        } else {
          setState(() => _elapsed++);
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsed = 0;
      _running = false;
      _done.clear();
    });
  }

  String get _timeLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _elapsed / _totalSeconds;

  // ── Step toggle ──
  void _toggleStep(int i) => setState(
        () => _done.contains(i) ? _done.remove(i) : _done.add(i),
      );

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(pulseAnim: _pulseAnim),
                const SizedBox(height: 16),
                _BenefitBanner(),
                const SizedBox(height: 20),
                _TimerCard(
                  timeLabel: _timeLabel,
                  progress: _progress,
                  running: _running,
                  onToggle: _toggleTimer,
                  onReset: _resetTimer,
                ),
                const SizedBox(height: 22),
                _sectionLabel('STEPS'),
                const SizedBox(height: 10),
                ..._steps.asMap().entries.map(
                      (e) => _StepCard(
                        index: e.key,
                        data: e.value,
                        done: _done.contains(e.key),
                        onTap: () => _toggleStep(e.key),
                      ),
                    ),
                const SizedBox(height: 18),
                _ProgressFooter(done: _done.length, total: _steps.length),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Practice',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: _textMuted,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      );
}

// ─────────────────────────────────────────────
//  Hero Card
// ─────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _HeroCard({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B6BB8), Color(0xFFD45DA1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            right: -30,
            top: -30,
            child: _GlowCircle(size: 140, color: Colors.white.withOpacity(0.07)),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: _GlowCircle(size: 80, color: Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                ScaleTransition(
                  scale: pulseAnim,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.park_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grounding Walk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Focus on the feeling of your\nfeet touching the earth.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
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
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─────────────────────────────────────────────
//  Benefit Banner
// ─────────────────────────────────────────────
class _BenefitBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _purple.withOpacity(0.8), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Brings focus back to your body and the present moment. Regular practice reduces anxiety and improves mindfulness.',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Timer Card
// ─────────────────────────────────────────────
class _TimerCard extends StatelessWidget {
  final String timeLabel;
  final double progress;
  final bool running;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _TimerCard({
    required this.timeLabel,
    required this.progress,
    required this.running,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: _purple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Session Timer',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '8–10 min',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Big time display
          Text(
            timeLabel,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: _purple.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(_purple),
            ),
          ),
          const SizedBox(height: 18),
          // Buttons
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: running ? 'Pause' : 'Start',
                  icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  filled: true,
                  onTap: onToggle,
                ),
              ),
              const SizedBox(width: 10),
              _PillButton(
                label: 'Reset',
                icon: Icons.replay_rounded,
                filled: false,
                onTap: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [_purple, _pink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: filled ? null : _purple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : _purple),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : _purple,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Step Card  (tappable, checkable)
// ─────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int index;
  final _StepData data;
  final bool done;
  final VoidCallback onTap;

  const _StepCard({
    required this.index,
    required this.data,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? data.accent.withOpacity(0.1) : _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? data.accent.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!done)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number / check
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? data.accent : data.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Icon(data.icon, color: data.accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: done ? data.accent : _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: data.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.body,
                    style: TextStyle(
                      color: done ? _textMuted : _textPrimary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Progress Footer
// ─────────────────────────────────────────────
class _ProgressFooter extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressFooter({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final allDone = done == total;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [const Color(0xFF7B5EA7), const Color(0xFFD45DA1)]
              : [_purple.withOpacity(0.06), _pink.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allDone ? Colors.transparent : _purple.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.emoji_events_rounded : Icons.flag_outlined,
            color: allDone ? Colors.white : _purple,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Amazing! Walk complete 🎉' : 'Your progress',
                  style: TextStyle(
                    color: allDone ? Colors.white : _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allDone
                      ? 'You completed all steps. Great job staying grounded!'
                      : '$done of $total steps completed',
                  style: TextStyle(
                    color: allDone ? Colors.white70 : _textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
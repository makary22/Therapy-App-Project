import 'package:flutter/material.dart';
import 'dart:async';

class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

enum _Phase { idle, inhale, holdIn, exhale, holdOut, done }

class _BoxBreathingScreenState extends State<BoxBreathingScreen> {
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  static const int _targetRounds = 4;
  static const int _phaseDurationMs = 4000; // 4 seconds per phase
  static const Duration _tick = Duration(milliseconds: 50);

  Timer? _engine;
  _Phase _phase = _Phase.idle;
  int _completedRounds = 0;
  int _phaseElapsedMs = 0;
  int _totalElapsedMs = 0;

  // 0.0 = empty, 1.0 = full
  double _breathLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _engine = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void dispose() {
    _engine?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    if (_phase == _Phase.idle || _phase == _Phase.done) return;

    setState(() {
      _phaseElapsedMs += _tick.inMilliseconds;
      _totalElapsedMs += _tick.inMilliseconds;

      final double progress =
          (_phaseElapsedMs / _phaseDurationMs).clamp(0.0, 1.0);

      switch (_phase) {
        case _Phase.inhale:
          _breathLevel = progress;
          if (_phaseElapsedMs >= _phaseDurationMs) _advancePhase();
        case _Phase.holdIn:
          _breathLevel = 1.0;
          if (_phaseElapsedMs >= _phaseDurationMs) _advancePhase();
        case _Phase.exhale:
          _breathLevel = 1.0 - progress;
          if (_phaseElapsedMs >= _phaseDurationMs) _advancePhase();
        case _Phase.holdOut:
          _breathLevel = 0.0;
          if (_phaseElapsedMs >= _phaseDurationMs) _advancePhase();
        default:
          break;
      }
    });
  }

  void _advancePhase() {
    _phaseElapsedMs = 0;

    switch (_phase) {
      case _Phase.inhale:
        _phase = _Phase.holdIn;
      case _Phase.holdIn:
        _phase = _Phase.exhale;
      case _Phase.exhale:
        _phase = _Phase.holdOut;
      case _Phase.holdOut:
        _completedRounds++;
        if (_completedRounds >= _targetRounds) {
          _phase = _Phase.done;
          _breathLevel = 0.0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Excellent. You completed 4 breathing cycles.'),
                ),
              );
            }
          });
        } else {
          _phase = _Phase.inhale;
        }
      default:
        break;
    }
  }

  void _start() {
    if (_phase != _Phase.idle) return;
    setState(() {
      _phase = _Phase.inhale;
      _phaseElapsedMs = 0;
    });
  }

  void _reset() {
    setState(() {
      _phase = _Phase.idle;
      _completedRounds = 0;
      _phaseElapsedMs = 0;
      _totalElapsedMs = 0;
      _breathLevel = 0.0;
    });
  }

  String _phaseLabel() {
    switch (_phase) {
      case _Phase.idle:
        return 'Tap Start';
      case _Phase.inhale:
        return 'Inhale';
      case _Phase.holdIn:
        return 'Hold';
      case _Phase.exhale:
        return 'Exhale';
      case _Phase.holdOut:
        return 'Hold';
      case _Phase.done:
        return 'Done';
    }
  }

  String _helperText() {
    switch (_phase) {
      case _Phase.idle:
        return 'Press Start to begin your box breathing session.';
      case _Phase.inhale:
        return 'Breathe in slowly through your nose for 4 seconds.';
      case _Phase.holdIn:
        return 'Hold your breath gently at the top for 4 seconds.';
      case _Phase.exhale:
        return 'Exhale slowly through your mouth for 4 seconds.';
      case _Phase.holdOut:
        return 'Hold empty for 4 seconds before the next breath.';
      case _Phase.done:
        return 'Nice work. Tap reset to start another session.';
    }
  }

  String _formatElapsed() {
    final totalSeconds = (_totalElapsedMs / 1000).floor();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Countdown seconds left in current phase
  int _secondsLeft() {
    final remaining = _phaseDurationMs - _phaseElapsedMs;
    return (remaining / 1000).ceil().clamp(0, 4);
  }

  double _sessionProgress() =>
      (_completedRounds / _targetRounds).clamp(0.0, 1.0);

  // Phase progress within the 4-phase box (0..1 per phase)
  double _phaseProgress() =>
      (_phaseElapsedMs / _phaseDurationMs).clamp(0.0, 1.0);

  Color _phaseColor() {
    switch (_phase) {
      case _Phase.inhale:
        return _purple;
      case _Phase.holdIn:
        return const Color(0xFF5C8DD6);
      case _Phase.exhale:
        return _pink;
      case _Phase.holdOut:
        return const Color(0xFF7EC8A4);
      default:
        return _purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleSize = 120.0 + (_breathLevel * 90.0);
    final phaseColor = _phaseColor();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Box Breathing',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Progress card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cycle $_completedRounds / $_targetRounds',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatElapsed(),
                        style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _sessionProgress(),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: const Color(0xFFE7E1F0),
                    color: _purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Main breathing area ──
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Phase progress arc indicator
                    if (_phase != _Phase.idle && _phase != _Phase.done)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: 220,
                          child: _BoxPhaseIndicator(
                            phase: _phase,
                            phaseProgress: _phaseProgress(),
                            phaseColor: phaseColor,
                          ),
                        ),
                      ),

                    // Animated circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            phaseColor.withOpacity(0.9),
                            (_phase == _Phase.exhale || _phase == _Phase.holdOut
                                    ? _pink
                                    : _purple)
                                .withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(circleSize / 2),
                        boxShadow: [
                          BoxShadow(
                            color: phaseColor.withOpacity(0.25),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _phaseLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_phase != _Phase.idle &&
                              _phase != _Phase.done) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_secondsLeft()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _helperText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Buttons ──
            Row(
              children: [
                if (_phase == _Phase.idle)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                if (_phase != _Phase.idle) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Reset Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6DEEF),
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4-segment phase indicator ──────────────────────────────────────────────
class _BoxPhaseIndicator extends StatelessWidget {
  final _Phase phase;
  final double phaseProgress;
  final Color phaseColor;

  const _BoxPhaseIndicator({
    required this.phase,
    required this.phaseProgress,
    required this.phaseColor,
  });

  static const _labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _phases = [
    _Phase.inhale,
    _Phase.holdIn,
    _Phase.exhale,
    _Phase.holdOut
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = _phases[i] == phase;
        final isPast = _phases.indexOf(phase) > i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        color: const Color(0xFFE7E1F0),
                      ),
                      if (isPast)
                        Container(height: 4, color: phaseColor.withOpacity(0.5)),
                      if (isActive)
                        FractionallySizedBox(
                          widthFactor: phaseProgress,
                          child: Container(height: 4, color: phaseColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? phaseColor
                        : const Color(0xFFBBB6C9),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
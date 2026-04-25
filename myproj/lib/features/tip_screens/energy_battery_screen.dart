import 'package:flutter/material.dart';

class EnergyBatteryScreen extends StatefulWidget {
  const EnergyBatteryScreen({super.key});

  @override
  State<EnergyBatteryScreen> createState() => _EnergyBatteryScreenState();
}

class _EnergyBatteryScreenState extends State<EnergyBatteryScreen> {
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  double _energyValue = 50;
  String? _selectedAction;

  _EnergyStage get _currentStage {
    final v = _energyValue.round();
    if (v <= 20) {
      return const _EnergyStage(
        name: 'Struggle',
        emoji: '😔',
        question:
            'Your energy is very low right now. What is one tiny step you can do for yourself?',
        quickActions: [
          'Dark mode for 5 minutes',
          '20-minute power nap',
          'Box breathing for 1 minute',
        ],
      );
    }
    if (v <= 40) {
      return const _EnergyStage(
        name: 'Low Battery',
        emoji: '😟',
        question: 'You need a gentle recharge. What can lift you a little?',
        quickActions: [
          'Make a comfort drink',
          'Take a 15-minute screen break',
          'Listen to one favorite song',
        ],
      );
    }
    if (v <= 60) {
      return const _EnergyStage(
        name: 'Balanced',
        emoji: '😐',
        question: 'You are steady. Do you want to keep balance or boost up?',
        quickActions: [
          'Write one clear sentence',
          'Take a short walk',
          'Do a quick stretch',
        ],
      );
    }
    if (v <= 80) {
      return const _EnergyStage(
        name: 'High Energy',
        emoji: '🙂',
        question: 'Your energy is good. How will you use it well?',
        quickActions: [
          'Finish one small pending task',
          'Write 3 gratitude points',
          'Plan top 2 tasks for tomorrow',
        ],
      );
    }
    return const _EnergyStage(
      name: 'Supercharged',
      emoji: '😊',
      question:
          'You are fully charged. What message can you leave for your future tired self?',
      quickActions: [
        'Record a short voice note',
        'Capture a memory photo',
        'Send a kind message to someone',
      ],
    );
  }

  Color get _barColor {
    final v = _energyValue;
    if (v <= 20) return const Color(0xFFE05252);
    if (v <= 40) return const Color(0xFFE8913A);
    if (v <= 60) return const Color(0xFF7B5EA7);
    if (v <= 80) return const Color(0xFF1D7B63);
    return const Color(0xFFD45DA1);
  }

  @override
  Widget build(BuildContext context) {
    final stage = _currentStage;
    final color = _barColor;
    final pct = _energyValue.round();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Energy Battery',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDAC7F7), Color(0xFFF0C9E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.battery_charging_full_rounded,
                      color: _purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Energy Battery',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tune in with your current energy and choose one caring action.',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'How much energy do you have right now?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2E38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(stage.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          stage.name,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _energyValue / 100,
                      minHeight: 10,
                      color: color,
                      backgroundColor: const Color(0xFFEEEBF3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: color,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 13),
                      overlayColor: color.withOpacity(0.15),
                      trackHeight: 0,
                    ),
                    child: Slider(
                      value: _energyValue,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (val) {
                        setState(() {
                          _energyValue = val;
                          _selectedAction = null;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '100%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: color.withOpacity(0.22),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.question,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2E2E38),
                      fontWeight: FontWeight.w700,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: stage.quickActions.map((action) {
                      final selected = _selectedAction == action;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAction = action),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? color : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: color.withOpacity(selected ? 1.0 : 0.3),
                              width: 1.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.22),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            action,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF4A4A54),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedAction != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Great choice. A small step is enough for now.',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyStage {
  const _EnergyStage({
    required this.name,
    required this.emoji,
    required this.question,
    required this.quickActions,
  });

  final String name;
  final String emoji;
  final String question;
  final List<String> quickActions;
}

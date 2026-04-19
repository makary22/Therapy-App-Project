import 'package:flutter/material.dart';

import '../home/HomeScreen.dart';

class UnloadShoreScreen extends StatefulWidget {
  const UnloadShoreScreen({super.key});

  @override
  State<UnloadShoreScreen> createState() => _UnloadShoreScreenState();
}

class _UnloadShoreScreenState extends State<UnloadShoreScreen> {
  final TextEditingController _thing1Controller = TextEditingController();
  final TextEditingController _thing2Controller = TextEditingController();
  final TextEditingController _thing3Controller = TextEditingController();
  bool _showSuccessOverlay = false;

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void dispose() {
    _thing1Controller.dispose();
    _thing2Controller.dispose();
    _thing3Controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final things = [
      _thing1Controller.text.trim(),
      _thing2Controller.text.trim(),
      _thing3Controller.text.trim(),
    ];

    if (things.any((item) => item.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all 3 fields.')),
      );
      return;
    }

    final Map<String, dynamic> savedPayload = {
      'tipId': 'unload_shore',
      'savedAt': DateTime.now().toIso8601String(),
      'items': things,
    };

    debugPrint('UnloadShore save: $savedPayload');

    if (!mounted) return;
    setState(() {
      _showSuccessOverlay = true;
    });
  }

  void _finishAndReturnHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Unload the Shore',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
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
                            Icons.edit_note_rounded,
                            color: _purple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unload the Shore',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Write down 3 things that can wait until tomorrow',
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 18, color: _purple),
                        const SizedBox(width: 8),
                        Text(
                          'A gentle reset for tomorrow',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _purple.withOpacity(0.08),
                          _pink.withOpacity(0.06)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _purple.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Unload the next 3 items without judgment. Keep them short, simple, and easy to revisit tomorrow.',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'INPUTS',
                    style: TextStyle(
                      color: _textMuted,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing1Controller,
                    label: 'Thing 1',
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing2Controller,
                    label: 'Thing 2',
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing3Controller,
                    label: 'Thing 3',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save for tomorrow',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.22),
                alignment: Alignment.center,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _purple.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: _purple,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Safe travels to sleep. See you tomorrow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finishAndReturnHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Finish',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThingField({
    required TextEditingController controller,
    required String label,
  }) {
    const Color surfaceColor = _cardBg;
    const Color textColor = _textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7E3EF),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'What can wait until tomorrow?',
          labelStyle: const TextStyle(color: textColor),
          hintStyle: const TextStyle(color: _textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _purple, width: 1.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: surfaceColor,
        ),
        style: const TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

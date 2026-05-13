import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnloadShoreScreen extends StatefulWidget {
  const UnloadShoreScreen({super.key});

  @override
  State<UnloadShoreScreen> createState() => _UnloadShoreScreenState();
}

class _UnloadShoreScreenState extends State<UnloadShoreScreen> {
  final TextEditingController _thing1Controller = TextEditingController();
  final TextEditingController _thing2Controller = TextEditingController();
  final TextEditingController _thing3Controller = TextEditingController();
  final List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _pendingPopupEntry;
  bool _showSuccessOverlay = false;

  static const String _historyStorageKey = 'unload_shore_history_v1';
  static const String _popupSeenStorageKey = 'unload_shore_popup_seen_v1';
  static const Duration _historyRetention = Duration(hours: 24);

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

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

    final now = DateTime.now();
    final historyEntry = <String, dynamic>{
      'savedAt': now.toIso8601String(),
      'items': List<String>.from(things),
    };

    final updatedHistory = _pruneExpiredHistory([
      historyEntry,
      ..._history,
    ], now);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyStorageKey, jsonEncode(updatedHistory));

    if (!mounted) return;
    setState(() {
      _history
        ..clear()
        ..addAll(updatedHistory);
      _showSuccessOverlay = false;
      _pendingPopupEntry = null;
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_historyStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final now = DateTime.now();
      final loadedHistory = <Map<String, dynamic>>[];

      for (final entry in decoded) {
        if (entry is! Map) continue;
        final savedAt = DateTime.tryParse(entry['savedAt']?.toString() ?? '');
        final itemsRaw = entry['items'];
        if (savedAt == null || itemsRaw is! List) continue;

        final items = itemsRaw
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

        if (items.isEmpty) continue;
        if (now.difference(savedAt) > _historyRetention) continue;

        loadedHistory.add({
          'savedAt': savedAt.toIso8601String(),
          'items': items,
        });
      }

      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(loadedHistory);
      });

      if (loadedHistory.length != decoded.length) {
        await prefs.setString(
          _historyStorageKey,
          jsonEncode(loadedHistory),
        );
      }

      await _maybeShowPendingPopup(prefs, loadedHistory);
    } catch (_) {
      // Ignore malformed cached data and continue with empty history.
    }
  }

  Future<void> _maybeShowPendingPopup(
    SharedPreferences prefs,
    List<Map<String, dynamic>> history,
  ) async {
    final DateTime todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final String? seenRaw = prefs.getString(_popupSeenStorageKey);
    final DateTime? seenAt = DateTime.tryParse(seenRaw ?? '');

    final dueEntries = history.where((entry) {
      final savedAt = DateTime.tryParse(entry['savedAt']?.toString() ?? '');
      if (savedAt == null) return false;
      if (!savedAt.isBefore(todayStart)) return false;
      if (seenAt != null && !savedAt.isAfter(seenAt)) return false;
      return true;
    }).toList();

    if (dueEntries.isEmpty || !mounted) return;

    dueEntries.sort((a, b) {
      final aTime = DateTime.tryParse(a['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    setState(() {
      _pendingPopupEntry = dueEntries.first;
      _showSuccessOverlay = true;
    });
  }

  List<Map<String, dynamic>> _pruneExpiredHistory(
    List<Map<String, dynamic>> entries,
    DateTime now,
  ) {
    return entries.where((entry) {
      final savedAt = DateTime.tryParse(entry['savedAt']?.toString() ?? '');
      if (savedAt == null) return false;
      return now.difference(savedAt) <= _historyRetention;
    }).toList();
  }

  Future<void> _finishAndReturnHome() async {
    if (_pendingPopupEntry != null) {
      await _markPopupSeen(_pendingPopupEntry!);
    }
    if (mounted) {
      setState(() {
        _showSuccessOverlay = false;
        _pendingPopupEntry = null;
      });
    }
    Navigator.of(context).pop();
  }

  Future<void> _markPopupSeen(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _popupSeenStorageKey,
      entry['savedAt']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Unload the Shore',
          style: TextStyle(
            color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
        ),
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
                      color: isDark ? const Color(0xFF1A1C27) : _cardBg,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unload the Shore',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFF1EEF8)
                                      : _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Write down 3 things that can wait until tomorrow',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFB5B2C4)
                                      : _textMuted,
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
                      color: isDark ? const Color(0xFF1A1C27) : _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 18, color: _purple),
                        const SizedBox(width: 8),
                        Text(
                          'A gentle reset for tomorrow',
                          style: TextStyle(
                            color:
                                isDark ? const Color(0xFFF1EEF8) : _textPrimary,
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
                          isDark
                              ? _purple.withOpacity(0.18)
                              : _purple.withOpacity(0.08),
                          isDark
                              ? _pink.withOpacity(0.12)
                              : _pink.withOpacity(0.06)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4A4058)
                            : _purple.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Unload the next 3 items without judgment. Keep them short, simple, and easy to revisit tomorrow.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE8E5F3) : _textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'INPUTS',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB5B2C4) : _textMuted,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing1Controller,
                    label: 'Thing 1',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing2Controller,
                    label: 'Thing 2',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildThingField(
                    controller: _thing3Controller,
                    label: 'Thing 3',
                    isDark: isDark,
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
                  const SizedBox(height: 18),
                  Text(
                    'HISTORY',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB5B2C4) : _textMuted,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1C27) : _cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A3B4D)
                              : const Color(0xFFE7E3EF),
                        ),
                      ),
                      child: Text(
                        'Saved items will appear here for 24 hours.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB5B2C4) : _textMuted,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _history.map((entry) {
                        final savedAt = DateTime.tryParse(
                                entry['savedAt']?.toString() ?? '')
                            ?.toLocal();
                        final items = (entry['items'] as List<dynamic>? ?? [])
                            .map((item) => item.toString())
                            .toList();

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1C27) : _cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3A3B4D)
                                  : const Color(0xFFE7E3EF),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 16,
                                      color: isDark
                                          ? const Color(0xFFB5B2C4)
                                          : _purple),
                                  const SizedBox(width: 8),
                                  Text(
                                    savedAt == null
                                        ? 'Saved recently'
                                        : _formatSavedAt(savedAt),
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFF1EEF8)
                                          : _textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...items.asMap().entries.map((itemEntry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _purple.withOpacity(0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${itemEntry.key + 1}',
                                          style: const TextStyle(
                                            color: _purple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          itemEntry.value,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFE8E5F3)
                                                : _textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
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
                    color: isDark
                        ? const Color(0xFF1E1F2A)
                        : Colors.white.withOpacity(0.96),
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
                      Text(
                        _pendingPopupEntry == null
                            ? 'Safe travels to sleep. See you tomorrow.'
                            : 'Here are the 3 things you saved yesterday.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_pendingPopupEntry != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2B38)
                                : const Color(0xFFF6F3FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...((_pendingPopupEntry!['items']
                                              as List<dynamic>? ??
                                          [])
                                      .map((item) => item.toString())
                                      .toList())
                                  .asMap()
                                  .entries
                                  .map((itemEntry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _purple.withOpacity(0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${itemEntry.key + 1}',
                                          style: const TextStyle(
                                            color: _purple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          itemEntry.value,
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFE8E5F3)
                                                : _textPrimary,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
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
    required bool isDark,
  }) {
    final Color surfaceColor = isDark ? const Color(0xFF1A1C27) : _cardBg;
    final Color textColor = isDark ? const Color(0xFFF1EEF8) : _textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3B4D) : const Color(0xFFE7E3EF),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'What can wait until tomorrow?',
          labelStyle: TextStyle(color: textColor),
          hintStyle:
              TextStyle(color: isDark ? const Color(0xFFB5B2C4) : _textMuted),
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
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatSavedAt(DateTime savedAt) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int hour = savedAt.hour % 12 == 0 ? 12 : savedAt.hour % 12;
    final String minute = savedAt.minute.toString().padLeft(2, '0');
    final String period = savedAt.hour >= 12 ? 'PM' : 'AM';
    return '${monthNames[savedAt.month - 1]} ${savedAt.day}, $hour:$minute $period';
  }
}

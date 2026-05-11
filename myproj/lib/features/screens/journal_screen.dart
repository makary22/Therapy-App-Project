import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/ChatScreen.dart';
import '../home/HomeScreen.dart';
import 'profile_screen.dart';
import 'weekly_reflections_screen.dart';

class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
    required this.rating,
    required this.emoji,
    required this.tags,
    required this.accent,
    this.sessionIndex,
  });

  final String title;
  final String content;
  final DateTime dateTime;
  final int rating;
  final String emoji;
  final List<String> tags;
  final Color accent;
  final int? sessionIndex;
}

class JournalDataSource {
  static const String _storageKey = 'chat_sessions_v1';

  static Future<List<JournalEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    final List<JournalEntry> entries = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final session in decoded) {
            if (session is! Map<String, dynamic>) continue;
            final messages = session['messages'];
            if (messages is! List) continue;

            Map<String, dynamic>? firstUserMessage;
            for (final msg in messages) {
              if (msg is! Map<String, dynamic>) continue;
              if (msg['isUser'] == true &&
                  (msg['text'] as String? ?? '').trim().isNotEmpty) {
                firstUserMessage = msg;
                break;
              }
            }

            if (firstUserMessage == null) continue;

            final String text =
                (firstUserMessage['text'] as String? ?? '').trim();
            if (text.isEmpty) continue;

            DateTime date = DateTime.now();
            final ts = firstUserMessage['timestamp'];
            if (ts is String) {
              date = _parseTimestampToLocal(ts) ?? date;
            }

            final int rating = (firstUserMessage['rating'] as num?)?.toInt() ??
                _inferRatingFromText(text);
            final String mood = (firstUserMessage['mood'] as String?) ?? '';

            entries.add(
              JournalEntry(
                title: _deriveTitle(text),
                content: text,
                dateTime: date,
                rating: rating.clamp(1, 5),
                emoji: _emojiForMood(mood, rating),
                tags: _deriveTags(text),
                accent: _accentColor(rating),
              ),
            );
          }
        }
      } catch (_) {}
    }

    if (entries.isEmpty) {
      entries.addAll(_sampleEntries());
    }

    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return entries;
  }

  static Future<List<JournalEntry>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    final List<JournalEntry> entries = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            final session = decoded[i];
            if (session is! Map<String, dynamic>) continue;
            if (session['favorite'] != true) continue;
            final messages = session['messages'];
            if (messages is! List) continue;

            Map<String, dynamic>? firstUserMessage;
            for (final msg in messages) {
              if (msg is! Map<String, dynamic>) continue;
              if (msg['isUser'] == true &&
                  (msg['text'] as String? ?? '').trim().isNotEmpty) {
                firstUserMessage = msg;
                break;
              }
            }

            if (firstUserMessage == null) continue;

            final String text =
                (firstUserMessage['text'] as String? ?? '').trim();
            if (text.isEmpty) continue;

            DateTime date = DateTime.now();
            final ts = firstUserMessage['timestamp'];
            if (ts is String) {
              date = _parseTimestampToLocal(ts) ?? date;
            }

            final int rating = (firstUserMessage['rating'] as num?)?.toInt() ??
                _inferRatingFromText(text);
            final String mood = (firstUserMessage['mood'] as String?) ?? '';

            entries.add(
              JournalEntry(
                title: _deriveTitle(text),
                content: text,
                dateTime: date,
                rating: rating.clamp(1, 5),
                emoji: _emojiForMood(mood, rating),
                tags: _deriveTags(text),
                accent: _accentColor(rating),
                sessionIndex: i,
              ),
            );
          }
        }
      } catch (_) {}
    }

    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return entries;
  }

  static DateTime? _parseTimestampToLocal(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  static String monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String entryTimeLabel(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date =
        DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
    final diff = today.difference(date).inDays;

    final String suffix = localDateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = localDateTime.hour % 12;
    if (hour == 0) hour = 12;
    final String minute = localDateTime.minute.toString().padLeft(2, '0');
    final String time = '$hour:$minute $suffix';

    if (diff == 0) return 'TODAY • $time';
    if (diff == 1) return 'YESTERDAY • $time';
    const monthShort = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${monthShort[localDateTime.month - 1]} ${localDateTime.day} • $time';
  }

  static List<JournalEntry> _sampleEntries() {
    final now = DateTime.now();
    return [
      JournalEntry(
        title: 'Calm & Centered',
        content:
            'The morning meditation really helped clear my mind. I feel ready to tackle the day with a sense of peace.',
        dateTime: now.subtract(const Duration(hours: 2)),
        rating: 5,
        emoji: '😊',
        tags: const ['Meditation', 'Work'],
        accent: const Color(0xFF7B5EA7),
        sessionIndex: null,
      ),
      JournalEntry(
        title: 'Productive Growth',
        content:
            'Had a difficult conversation today, but I feel lighter after expressing what I needed to say.',
        dateTime: now.subtract(const Duration(days: 1, hours: 4)),
        rating: 4,
        emoji: '🌱',
        tags: const ['Relationships'],
        accent: const Color(0xFF1D7B63),
        sessionIndex: null,
      ),
      JournalEntry(
        title: 'Inspired Moments',
        content:
            'The sunset felt beautiful and grounding. I paused and appreciated the colors and the calm.',
        dateTime: now.subtract(const Duration(days: 2, hours: 1)),
        rating: 5,
        emoji: '✨',
        tags: const ['Gratitude', 'Nature'],
        accent: const Color(0xFFD45DA1),
        sessionIndex: null,
      ),
    ];
  }

  static String _deriveTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Journal Entry';
    final words = trimmed.split(RegExp(r'\s+'));
    final first = words.take(3).join(' ');
    return first.length > 28 ? '${first.substring(0, 28)}...' : first;
  }

  static int _inferRatingFromText(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'great|happy|grateful|calm|peace').hasMatch(lower)) return 5;
    if (RegExp(r'good|better|okay|productive|hope').hasMatch(lower)) return 4;
    if (RegExp(r'stress|hard|sad|tired|anxious').hasMatch(lower)) return 2;
    return 3;
  }

  static String _emojiForMood(String mood, int rating) {
    if (mood.isNotEmpty) return mood;
    if (rating >= 5) return '😊';
    if (rating == 4) return '🙂';
    if (rating == 3) return '😐';
    if (rating == 2) return '😟';
    return '😔';
  }

  static List<String> _deriveTags(String text) {
    final lower = text.toLowerCase();
    final tags = <String>[];
    if (RegExp(r'work|project|task').hasMatch(lower)) tags.add('Work');
    if (RegExp(r'friend|family|relationship|conversation').hasMatch(lower)) {
      tags.add('Relationships');
    }
    if (RegExp(r'meditation|breathe|calm|peace').hasMatch(lower)) {
      tags.add('Meditation');
    }
    if (RegExp(r'nature|sunset|walk|outside').hasMatch(lower)) {
      tags.add('Nature');
    }
    if (tags.isEmpty) tags.add('Reflection');
    return tags.take(2).toList();
  }

  static Color _accentColor(int rating) {
    if (rating >= 5) return const Color(0xFFD45DA1);
    if (rating == 4) return const Color(0xFF1D7B63);
    if (rating == 3) return const Color(0xFF7B5EA7);
    return const Color(0xFF8B6F47);
  }
}

// ─────────────────────────────────────────────────────────────
// JOURNAL SCREEN
// ─────────────────────────────────────────────────────────────
class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    required this.name,
    required this.header,
    this.showBottomNavigation = true,
    this.navIndexNotifier,
  });

  final String name;
  final Widget Function(String name) header;
  final bool showBottomNavigation;
  final ValueNotifier<int>? navIndexNotifier;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  final List<JournalEntry> _journalEntries = [];
  final List<JournalEntry> _favoriteEntries = [];
  int _currentNavIndex = 1;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool _isLoadingJournal = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    // listen for tab activation from HomeScreen (if provided)
    widget.navIndexNotifier?.addListener(_navListener);
  }

  Future<void> _loadEntries() async {
    final entries = await JournalDataSource.loadEntries();
    final favs = await JournalDataSource.loadFavorites();
    if (!mounted) return;
    setState(() {
      _journalEntries
        ..clear()
        ..addAll(entries);
      _favoriteEntries
        ..clear()
        ..addAll(favs);
      _isLoadingJournal = false;
    });
  }

  void _navListener() {
    if (widget.navIndexNotifier?.value == 1) {
      _loadEntries();
      final now = DateTime.now();
      setState(() {
        _visibleMonth = DateTime(now.year, now.month);
        _selectedDate = DateTime(now.year, now.month, now.day);
      });
    }
  }

  @override
  void dispose() {
    widget.navIndexNotifier?.removeListener(_navListener);
    super.dispose();
  }

  // Public helper to reset calendar to today
  void resetToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() => _currentNavIndex = index);

    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WeeklyReflectionsScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesForVisibleMonth = _journalEntries.where((entry) {
      return entry.dateTime.year == _visibleMonth.year &&
          entry.dateTime.month == _visibleMonth.month;
    }).toList();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF12131C) : const Color(0xFFF4F1F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: widget.header(widget.name),
          ),
        ),
      ),
      body: _isLoadingJournal
          ? const Center(
              child: CircularProgressIndicator(color: _purple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Your Journey',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE8DEF8) : _purple,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Reflecting on ${JournalDataSource.monthLabel(_visibleMonth)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFFB7B1C7)
                          : const Color(0xFF50505A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCalendarCard(entriesForVisibleMonth, isDark),
                  const SizedBox(height: 14),
                  _buildFavoritesSection(isDark),
                ],
              ),
            ),
      bottomNavigationBar:
          widget.showBottomNavigation ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildCalendarCard(List<JournalEntry> monthEntries, bool isDark) {
    final firstDayOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final startOffset = firstDayOfMonth.weekday - 1;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final Map<DateTime, int> entriesCount = {};
    for (final e in monthEntries) {
      final d = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      entriesCount[d] = (entriesCount[d] ?? 0) + 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFECE9F2),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _calendarArrow(
                Icons.chevron_left_rounded,
                () => setState(() {
                  final newVisible =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                  _visibleMonth = newVisible;
                  final now = DateTime.now();
                  if (newVisible.year == now.year &&
                      newVisible.month == now.month) {
                    _selectedDate = DateTime(now.year, now.month, now.day);
                  } else {
                    final desiredDay = _selectedDate.day;
                    final daysInNew =
                        DateTime(newVisible.year, newVisible.month + 1, 0).day;
                    final day =
                        desiredDay <= daysInNew ? desiredDay : daysInNew;
                    _selectedDate =
                        DateTime(newVisible.year, newVisible.month, day);
                  }
                }),
              ),
              const SizedBox(width: 8),
              _calendarArrow(
                Icons.chevron_right_rounded,
                () => setState(() {
                  final newVisible =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                  _visibleMonth = newVisible;
                  final now = DateTime.now();
                  if (newVisible.year == now.year &&
                      newVisible.month == now.month) {
                    _selectedDate = DateTime(now.year, now.month, now.day);
                  } else {
                    final desiredDay = _selectedDate.day;
                    final daysInNew =
                        DateTime(newVisible.year, newVisible.month + 1, 0).day;
                    final day =
                        desiredDay <= daysInNew ? desiredDay : daysInNew;
                    _selectedDate =
                        DateTime(newVisible.year, newVisible.month, day);
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              7,
              (index) {
                const labels = [
                  'MON',
                  'TUE',
                  'WED',
                  'THU',
                  'FRI',
                  'SAT',
                  'SUN'
                ];
                return Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9C9AAF) : _textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date =
                  DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final entryCount = entriesCount[date] ?? 0;
              final hasEntry = entryCount > 0;
              final selected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final selectedBg =
                  isDark ? const Color(0xFF3A344A) : const Color(0xFFDCD4EB);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? (isDark ? const Color(0xFFF2EEF9) : _purple)
                              : (isDark
                                  ? const Color(0xFFE1DCEC)
                                  : _textPrimary),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Dynamic dot: size and opacity reflect number of entries on that day
                      Builder(builder: (_) {
                        if (!hasEntry) {
                          return const SizedBox(width: 5, height: 5);
                        }
                        final int count = entryCount;
                        final double size =
                            count == 1 ? 5 : (count <= 3 ? 7 : 9);
                        final double opacity =
                            (0.4 + (count.clamp(1, 4) * 0.15)).clamp(0.4, 1.0);
                        final dotColor = Color.fromRGBO(123, 94, 167, opacity);
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favorite Chats',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_favoriteEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF5F3F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'No favorite chats yet.',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFFB7B1C7) : const Color(0xFF696570),
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Column(
            children: _favoriteEntries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _openFavoriteChat(e),
                        child: _buildJournalEntryCard(e, isDark),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  void _openFavoriteChat(JournalEntry entry) {
    final int? sessionIndex = entry.sessionIndex;
    if (sessionIndex == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialMessage: '',
          initialSessionIndex: sessionIndex,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'HOME'},
      {'icon': Icons.menu_book_outlined, 'label': 'JOURNAL'},
      {'icon': Icons.insights_outlined, 'label': 'INSIGHTS'},
      {'icon': Icons.person_outline_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF0EEF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool active = index == _currentNavIndex;

          return GestureDetector(
            onTap: () => _handleNavTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: active
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF764AA1), Color(0xFFD96CB3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: active
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9C9AAF)
                            : const Color(0xFF8A9AB3)),
                    size: 20,
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _calendarArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFE6E2EF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _purple),
      ),
    );
  }

  Widget _buildEmptyEntriesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_stories_outlined, size: 40, color: Color(0xFFCAC4D5)),
          SizedBox(height: 10),
          Text(
            'No entries for this date',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF696570),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntryCard(JournalEntry entry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isDark ? const Color(0xFF232534) : const Color(0xFFF1EFF5),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entry.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(entry.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          JournalDataSource.entryTimeLabel(entry.dateTime),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: isDark
                                ? const Color(0xFFACA7BB)
                                : const Color(0xFF73707C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: entry.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < entry.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: const Color(0xFFD45DA1),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"${entry.content}"',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFD6D1E2)
                      : const Color(0xFF4D4E58),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: entry.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF343748)
                              : const Color(0xFFE3DFEA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? const Color(0xFFE7DCF9) : entry.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

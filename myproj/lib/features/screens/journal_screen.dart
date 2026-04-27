import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
    required this.rating,
    required this.emoji,
    required this.tags,
    required this.accent,
  });

  final String title;
  final String content;
  final DateTime dateTime;
  final int rating;
  final String emoji;
  final List<String> tags;
  final Color accent;
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
              date = DateTime.tryParse(ts) ?? date;
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(date).inDays;

    final String suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String time = '$hour:$minute $suffix';

    if (diff == 0) return 'TODAY • $time';
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
    return '${monthShort[dateTime.month - 1]} ${dateTime.day} • $time';
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
  });

  final String name;
  final Widget Function(String name) header;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  final List<JournalEntry> _journalEntries = [];
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
  }

  Future<void> _loadEntries() async {
    final entries = await JournalDataSource.loadEntries();
    if (!mounted) return;
    setState(() {
      _journalEntries
        ..clear()
        ..addAll(entries);
      _isLoadingJournal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesForSelectedDay = _journalEntries.where((entry) {
      return entry.dateTime.year == _selectedDate.year &&
          entry.dateTime.month == _selectedDate.month &&
          entry.dateTime.day == _selectedDate.day;
    }).toList();

    final entriesForVisibleMonth = _journalEntries.where((entry) {
      return entry.dateTime.year == _visibleMonth.year &&
          entry.dateTime.month == _visibleMonth.month;
    }).toList();

    final entriesToShow = entriesForSelectedDay;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      children: [
        const SizedBox.shrink(),
        const SizedBox(height: 22),
        const Text(
          'Your Journey',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: _purple,
            height: 1.1,
          ),
        ),
        Text(
          'Reflecting on ${JournalDataSource.monthLabel(_visibleMonth)}',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF50505A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        _buildCalendarCard(entriesForVisibleMonth),
        const SizedBox(height: 24),
        const Text(
          'Past Entries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoadingJournal)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: _purple),
            ),
          )
        else if (entriesForSelectedDay.isEmpty)
          _buildEmptyEntriesCard()
        else
          ...entriesToShow.map(_buildJournalEntryCard),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCalendarCard(List<JournalEntry> monthEntries) {
    final firstDayOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final startOffset = firstDayOfMonth.weekday - 1;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final daysWithEntries = monthEntries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECE9F2),
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
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                  _selectedDate =
                      DateTime(_visibleMonth.year, _visibleMonth.month, 1);
                }),
              ),
              const SizedBox(width: 8),
              _calendarArrow(
                Icons.chevron_right_rounded,
                () => setState(() {
                  _visibleMonth =
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                  _selectedDate =
                      DateTime(_visibleMonth.year, _visibleMonth.month, 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('MON',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('TUE',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('WED',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('THU',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('FRI',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('SAT',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
              Text('SUN',
                  style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w700)),
            ],
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
              final hasEntry = daysWithEntries.contains(date);
              final selected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xFFDCD4EB) : Colors.transparent,
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
                          color: selected ? _purple : _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: hasEntry ? _purple : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
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

  Widget _buildJournalEntryCard(JournalEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: const Color(0xFFF1EFF5),
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
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: Color(0xFF73707C),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4D4E58),
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
                          color: const Color(0xFFE3DFEA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: entry.accent,
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

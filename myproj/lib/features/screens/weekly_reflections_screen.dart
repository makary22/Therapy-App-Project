import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/HomeScreen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart';

class WeeklyReflectionsScreen extends StatefulWidget {
  const WeeklyReflectionsScreen({
    super.key,
    this.showBottomNavigation = true,
    this.name,
    this.header,
  });

  final bool showBottomNavigation;
  final String? name;
  final Widget Function(String name)? header;

  @override
  State<WeeklyReflectionsScreen> createState() =>
      _WeeklyReflectionsScreenState();
}

class _WeeklyReflectionsScreenState extends State<WeeklyReflectionsScreen> {
  static const String _historyStorageKey = 'chat_sessions_v1';

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFF8F7FC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF797985);

  bool _loading = true;
  late _WeeklyInsights _insights;
  int _currentNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _insights = _WeeklyInsights.empty();
    _loadWeeklyInsights();
  }

  Future<void> _loadWeeklyInsights() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_historyStorageKey);

    final List<_CheckInEntry> allEntries = [];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final session in decoded) {
            if (session is! Map) continue;
            final messagesRaw = session['messages'];
            if (messagesRaw is! List || messagesRaw.isEmpty) continue;

            // Collect ALL user messages from this session
            final List<Map<dynamic, dynamic>> userMessages = [];
            for (final msg in messagesRaw) {
              if (msg is! Map) continue;
              if ((msg['isUser'] ?? false) == true) {
                userMessages.add(msg);
              }
            }

            if (userMessages.isEmpty) continue;

            // Pick the message that has the best rating signal:
            // 1) explicit numeric rating > 0
            // 2) fallback: first user message (we'll infer rating from text)
            Map<dynamic, dynamic>? best;
            for (final msg in userMessages) {
              if (_parseRating(msg['rating']) > 0) {
                best = msg;
                break;
              }
            }
            best ??= userMessages.first;

            final String text = (best['text'] as String? ?? '').trim();
            final String mood = (best['mood'] as String? ?? '').trim();
            final String ts = (best['timestamp']?.toString() ?? '').trim();

            // Rating: explicit field first, then infer from text
            int rating = _parseRating(best['rating']);
            if (rating <= 0) rating = _inferRatingFromText(text);

            DateTime? time = DateTime.tryParse(ts)?.toLocal();
            time ??= _parseSessionDate(session['date']?.toString());
            if (time == null) continue;

            allEntries.add(
              _CheckInEntry(
                day: DateTime(time.year, time.month, time.day),
                rating: rating.clamp(1, 5),
                mood: mood,
                text: text,
              ),
            );
          }
        }
      } catch (_) {
        // Ignore malformed cached data.
      }
    }

    if (!mounted) return;
    setState(() {
      _insights = _WeeklyInsights.fromEntries(allEntries);
      _loading = false;
    });
  }

  // ── Infer a 1-5 rating from free text when no explicit rating exists ────
  static int _inferRatingFromText(String text) {
    final lower = text.toLowerCase();
    if (RegExp(
            r'great|happy|grateful|calm|peace|amazing|wonderful|جميل|ممتاز|سعيد|زين')
        .hasMatch(lower)) return 5;
    if (RegExp(r'good|better|okay|productive|hope|كويس|تمام|أحسن')
        .hasMatch(lower)) return 4;
    if (RegExp(r'stress|hard|sad|tired|anxious|تعبان|زعلان|قلق|صعب|مرهق')
        .hasMatch(lower)) return 2;
    if (RegExp(r'terrible|awful|hopeless|horrible|worst|كارثة|بكره|أسوأ')
        .hasMatch(lower)) return 1;
    return 3; // neutral default
  }

  DateTime? _parseSessionDate(String? label) {
    if (label == null || label.trim().isEmpty) return null;

    final raw = label.trim();
    final now = DateTime.now();
    if (raw == 'Today') {
      return DateTime(now.year, now.month, now.day);
    }
    if (raw == 'Yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return DateTime(y.year, y.month, y.day);
    }

    final parts = raw.split(' ');
    if (parts.length != 2) return null;

    const monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final month = monthMap[parts[0]];
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return null;

    var year = now.year;
    var candidate = DateTime(year, month, day);
    if (candidate.isAfter(now)) {
      year -= 1;
      candidate = DateTime(year, month, day);
    }

    return DateTime(candidate.year, candidate.month, candidate.day);
  }

  int _parseRating(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.round();

    final txt = raw.toString().trim();
    if (txt.isEmpty) return 0;

    final asInt = int.tryParse(txt);
    if (asInt != null) return asInt;

    final asDouble = double.tryParse(txt);
    if (asDouble != null) return asDouble.round();

    return 0;
  }

  String _displayName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();

    if (displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Friend';
  }

  Widget _buildJournalHeader(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 22,
              color: isDark ? const Color(0xFFE5DFF0) : _purple,
            ),
            const SizedBox(width: 6),
            Text(
              'Safe Space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE5DFF0) : _purple,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark ? const Color(0xFF383A4A) : const Color(0xFFD4D2DD),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF2D2F3D) : _purple,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackHeader(String name, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 22,
              color: isDark ? const Color(0xFFE5DFF0) : _purple,
            ),
            const SizedBox(width: 6),
            Text(
              'Safe Space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE5DFF0) : _purple,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark ? const Color(0xFF383A4A) : const Color(0xFFD4D2DD),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: isDark ? const Color(0xFF2D2F3D) : _purple,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex) return;

    setState(() => _currentNavIndex = index);

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JournalScreen(
            name: _displayName(),
            header: _buildJournalHeader,
          ),
        ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = widget.name ?? _displayName();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: widget.header != null
                ? widget.header!(name)
                : _buildFallbackHeader(name, isDark),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Reflections',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF3F0FA) : _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Insightful growth from the last 7 days.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFA7A3B4) : _textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildMomentumCard(isDark),
                  const SizedBox(height: 14),
                  _buildAverageCard(isDark),
                  const SizedBox(height: 14),
                  _buildMoodTrendsCard(isDark),
                  const SizedBox(height: 14),
                  _buildFrequentEmotionsCard(isDark),
                  const SizedBox(height: 14),
                  _buildAdviceCard(isDark),
                ],
              ),
            ),
      bottomNavigationBar:
          widget.showBottomNavigation ? _buildBottomNavigation(isDark) : null,
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

  Widget _buildMomentumCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C5CB6), Color(0xFFD45DA1)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT MOMENTUM',
            style: TextStyle(
              color: Color(0xFFEFE7FA),
              letterSpacing: 1.4,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You've checked in ${_insights.streakDays} days in a row 🔥",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _insights.streakLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(bool isDark) {
    // Show "–" when there is genuinely no data instead of "0.0"
    final bool hasData = _insights.weeklyAverage > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : _surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: _pink, size: 30),
          const SizedBox(height: 6),
          Text(
            hasData ? _insights.weeklyAverageLabel : '–',
            style: TextStyle(
              color: isDark ? const Color(0xFFF3F0FA) : _textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'AVERAGE WEEKLY RATING: ${_insights.weeklyAverageLabel} / 5'
                : 'NO RATINGS YET THIS WEEK',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFB4AFBF) : const Color(0xFF6C6B75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : _cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Trends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFF3F0FA)
                            : const Color(0xFF22232C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fluctuations this week',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF9E9AAC)
                            : const Color(0xFF666672),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: _purple),
                  const SizedBox(width: 6),
                  Text(
                    'WELLNESS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isDark
                          ? const Color(0xFFBDB9CA)
                          : const Color(0xFF5D5C67),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _TrendLinePainter(
                values: _insights.dailyAverages,
                strokeStart: _purple,
                strokeEnd: _pink,
                gridColor: isDark
                    ? const Color(0xFF313344).withOpacity(0.8)
                    : const Color(0xFFD8D4E3),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _insights.dayLabels
                .map(
                  (d) => Text(
                    d,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: isDark
                          ? const Color(0xFFA09CAE)
                          : const Color(0xFF7A7885),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentEmotionsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : _surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded,
                  color: Color(0xFF1A8A70), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Frequent Emotions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF3F0FA) : _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _insights.topEmotions
                .map((e) => _EmotionChip(label: e.label, color: e.color))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : _cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_pink, _purple],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"',
                  style: TextStyle(
                    color: Color(0xFFCF97C0),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _insights.weeklyAdvice,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: isDark ? const Color(0xFFF0EDF8) : _textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '- SAFE SPACE AI',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB4AFBF)
                        : const Color(0xFF72717B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
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

// ─────────────────────────────────────────────────────────────
// TREND LINE PAINTER
// ─────────────────────────────────────────────────────────────
class _TrendLinePainter extends CustomPainter {
  final List<double> values;
  final Color strokeStart;
  final Color strokeEnd;
  final Color gridColor;

  _TrendLinePainter({
    required this.values,
    required this.strokeStart,
    required this.strokeEnd,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Only draw points that have data (value > 0)
    const double minValue = 1;
    const double maxValue = 5;
    final double widthStep =
        values.length == 1 ? 0 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue; // skip days with no data
      final normalized =
          ((values[i] - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
      final x = widthStep * i;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [strokeStart, strokeEnd],
    );

    final linePaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first, radius: 6));
    } else {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = strokeEnd;
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.strokeStart != strokeStart ||
        oldDelegate.strokeEnd != strokeEnd ||
        oldDelegate.gridColor != gridColor;
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────
class _EmotionChip extends StatelessWidget {
  final String label;
  final Color color;

  const _EmotionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2B2A31),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────
class _CheckInEntry {
  final DateTime day;
  final int rating;
  final String mood;
  final String text;

  const _CheckInEntry({
    required this.day,
    required this.rating,
    required this.mood,
    required this.text,
  });
}

class _EmotionCount {
  final String label;
  final int count;

  const _EmotionCount(this.label, this.count);
}

class _EmotionTag {
  final String label;
  final Color color;

  const _EmotionTag({required this.label, required this.color});
}

class _WeeklyInsights {
  final double weeklyAverage;
  final List<double> dailyAverages;
  final List<String> dayLabels;
  final int streakDays;
  final List<_EmotionTag> topEmotions;
  final String weeklyAdvice;

  const _WeeklyInsights({
    required this.weeklyAverage,
    required this.dailyAverages,
    required this.dayLabels,
    required this.streakDays,
    required this.topEmotions,
    required this.weeklyAdvice,
  });

  factory _WeeklyInsights.empty() {
    return _WeeklyInsights(
      weeklyAverage: 0,
      dailyAverages: List<double>.filled(7, 0),
      dayLabels: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      streakDays: 0,
      topEmotions: const [
        _EmotionTag(label: 'Grounding', color: Color(0xFFD9C8F2)),
        _EmotionTag(label: 'Hopeful', color: Color(0xFFF2C8DD)),
        _EmotionTag(label: 'Calm', color: Color(0xFFBDEBD4)),
      ],
      weeklyAdvice:
          'You did not log enough check-ins this week yet. Try one short reflection today to unlock your weekly trend.',
    );
  }

  factory _WeeklyInsights.fromEntries(List<_CheckInEntry> allEntries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    final weekly = allEntries
        .where((e) => !e.day.isBefore(start) && !e.day.isAfter(today))
        .toList();

    final dailyBuckets = <DateTime, List<int>>{};
    for (int i = 0; i < 7; i++) {
      // Use Duration addition to correctly handle month-end rollovers
      final raw = start.add(Duration(days: i));
      final day = DateTime(raw.year, raw.month, raw.day);
      dailyBuckets[day] = [];
    }

    final moodCounts = <String, int>{};
    final textCounts = <String, int>{};

    for (final e in weekly) {
      // Normalize to midnight to guarantee key match with dailyBuckets
      final key = DateTime(e.day.year, e.day.month, e.day.day);
      if (dailyBuckets.containsKey(key)) {
        dailyBuckets[key]!.add(e.rating);
      }

      final moodLabel = _moodToLabel(e.mood);
      if (moodLabel != null) {
        moodCounts[moodLabel] = (moodCounts[moodLabel] ?? 0) + 1;
      }

      for (final token in _extractEmotionTokens(e.text)) {
        textCounts[token] = (textCounts[token] ?? 0) + 1;
      }
    }

    final dailyAverages = dailyBuckets.entries.map((entry) {
      final ratings = entry.value.where((r) => r > 0).toList();
      if (ratings.isEmpty) return 0.0;
      final sum = ratings.fold<int>(0, (a, b) => a + b);
      return sum / ratings.length;
    }).toList();

    double weeklyAverage = 0;
    final ratedDays = dailyAverages.where((v) => v > 0).toList();
    final int checkInDays =
        dailyBuckets.values.where((v) => v.isNotEmpty).length;
    if (ratedDays.isNotEmpty) {
      weeklyAverage = ratedDays.reduce((a, b) => a + b) / ratedDays.length;
    }

    final streakDays = _calculateStreak(dailyBuckets);
    final dayLabels = dailyBuckets.keys.map(_dayLabel).toList();

    final topEmotions = _buildTopEmotions(moodCounts, textCounts);
    final advice =
        _weeklyAdvice(weeklyAverage, streakDays, checkInDays, ratedDays.length);

    return _WeeklyInsights(
      weeklyAverage: weeklyAverage,
      dailyAverages: dailyAverages,
      dayLabels: dayLabels,
      streakDays: streakDays,
      topEmotions: topEmotions,
      weeklyAdvice: advice,
    );
  }

  String get weeklyAverageLabel =>
      weeklyAverage == 0 ? '–' : weeklyAverage.toStringAsFixed(1);

  String get streakLabel {
    if (streakDays >= 6) return 'Excellent consistency';
    if (streakDays >= 3) return 'Great consistency';
    if (streakDays >= 1) return 'Nice comeback';
    return 'Start your streak today';
  }

  static int _calculateStreak(Map<DateTime, List<int>> dailyBuckets) {
    int streak = 0;
    final days = dailyBuckets.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final d in days) {
      if ((dailyBuckets[d] ?? []).isNotEmpty) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  static String _dayLabel(DateTime day) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[day.weekday - 1];
  }

  static List<_EmotionTag> _buildTopEmotions(
    Map<String, int> moodCounts,
    Map<String, int> textCounts,
  ) {
    final combined = <_EmotionCount>[];

    for (final e in moodCounts.entries) {
      combined.add(_EmotionCount(e.key, e.value));
    }
    for (final e in textCounts.entries) {
      final existingIndex = combined.indexWhere((x) => x.label == e.key);
      if (existingIndex == -1) {
        combined.add(_EmotionCount(e.key, e.value));
      } else {
        final merged = _EmotionCount(
          combined[existingIndex].label,
          combined[existingIndex].count + e.value,
        );
        combined[existingIndex] = merged;
      }
    }

    combined.sort((a, b) => b.count.compareTo(a.count));
    final top = combined.take(4).toList();

    if (top.isEmpty) {
      return const [
        _EmotionTag(label: 'Grateful', color: Color(0xFFD9C8F2)),
        _EmotionTag(label: 'Calm', color: Color(0xFFBDEBD4)),
        _EmotionTag(label: 'Inspired', color: Color(0xFFF2C8DD)),
      ];
    }

    const palette = [
      Color(0xFFD9C8F2),
      Color(0xFFE0DFF0),
      Color(0xFFF2C8DD),
      Color(0xFFBDEBD4),
    ];

    return List<_EmotionTag>.generate(
      top.length,
      (i) =>
          _EmotionTag(label: top[i].label, color: palette[i % palette.length]),
    );
  }

  static String _weeklyAdvice(
    double avg,
    int streak,
    int checkInDays,
    int ratedDays,
  ) {
    if (checkInDays == 0) {
      return 'You did not log enough check-ins this week yet. Try one short reflection today.';
    }

    if (ratedDays == 0) {
      return 'You checked in this week. Add a rating after each reflection for a clearer trend.';
    }

    if (avg >= 4.2) {
      return 'You showed strong emotional stability this week. Keep the habits that helped you stay grounded.';
    }
    if (avg >= 3.2) {
      return 'Your week had ups and downs, but your consistency is helping. A small nightly check-in can help.';
    }
    if (streak >= 3) {
      return 'This week looked heavy, but your consistency is a real strength. Be gentle with yourself.';
    }
    return 'Your average suggests this week was demanding. Try one calming routine daily and ask for support.';
  }

  static String? _moodToLabel(String mood) {
    switch (mood) {
      case '😔':
      case '😟':
        return 'Heavy';
      case '😐':
        return 'Neutral';
      case '🙂':
        return 'Hopeful';
      case '😄':
        return 'Grateful';
      default:
        return null;
    }
  }

  static Iterable<String> _extractEmotionTokens(String text) sync* {
    final normalized = text.toLowerCase();

    final map = <String, List<String>>{
      'Grateful': ['grateful', 'thankful', 'امتنان', 'شاكر'],
      'Tired': ['tired', 'exhausted', 'drained', 'تعبان', 'مرهق'],
      'Inspired': ['inspired', 'motivated', 'creative', 'ملهم', 'متحمس'],
      'Calm': ['calm', 'peaceful', 'relaxed', 'هادي', 'هادئ'],
      'Anxious': ['anxious', 'worried', 'panic', 'قلق', 'متوتر'],
      'Stressed': ['stress', 'overwhelmed', 'pressure', 'ضغط'],
      'Sad': ['sad', 'down', 'hopeless', 'حزين', 'زعلان'],
    };

    for (final entry in map.entries) {
      final found = entry.value.any(normalized.contains);
      if (found) yield entry.key;
    }
  }
}

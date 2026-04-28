import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/ChatScreen.dart';
import '../screens/journal_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/weekly_reflections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dayReflectionController =
      TextEditingController();

  // emoji + label pairs
  static const List<Map<String, String>> _moodOptions = [
    {'emoji': '😔', 'label': 'V. Bad'},
    {'emoji': '😟', 'label': 'Bad'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😄', 'label': 'V. Good'},
  ];

  String? _selectedMood;
  int _selectedRating = 0;
  int _currentNavIndex = 0;
  final ValueNotifier<int> _navIndexNotifier = ValueNotifier<int>(0);

  // Water tracker state
  static const int _waterGoal = 8; // cups
  int _waterCups = 0;
  static const String _waterLastResetKey = 'water_last_reset_ms';

  Uint8List? _avatarBytes;
  String _profileName = '';

  // Daily quote — rotates by day-of-year
  static const List<Map<String, String>> _quotes = [
    {
      'text':
          'Don\'t spend time beating on a wall, hoping it will turn into a door.',
      'author': 'Coco Chanel',
    },
    {
      'text': 'You are enough, just as you are.',
      'author': 'Meghan Markle',
    },
    {
      'text': 'In the middle of difficulty lies opportunity.',
      'author': 'Albert Einstein',
    },
    {
      'text': 'Be gentle with yourself. You are a child of the universe.',
      'author': 'Max Ehrmann',
    },
    {
      'text': 'Rest is not idle — it is wisdom.',
      'author': 'Safe Space',
    },
  ];

  Map<String, String> get _todayQuote {
    final dayIndex = DateTime.now().difference(DateTime(2024)).inDays;
    return _quotes[dayIndex % _quotes.length];
  }

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadWaterData();
  }

  @override
  void dispose() {
    _dayReflectionController.dispose();
    _navIndexNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarBase64 = prefs.getString('profile_avatar_base64');
    final savedName = (prefs.getString('profile_name') ?? '').trim();

    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();

    final resolvedName = savedName.isNotEmpty
        ? savedName
        : (displayName.isNotEmpty
            ? displayName.split(' ').first
            : (email.isNotEmpty ? email.split('@').first : 'Friend'));

    if (!mounted) return;
    setState(() {
      _avatarBytes = avatarBase64 != null ? base64Decode(avatarBase64) : null;
      _profileName = resolvedName;
    });
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastResetMs = prefs.getInt(_waterLastResetKey);
    final bool shouldReset = lastResetMs == null ||
        now
                .difference(DateTime.fromMillisecondsSinceEpoch(lastResetMs))
                .inHours >=
            24;

    if (shouldReset) {
      await prefs.setInt('water_cups', 0);
      await prefs.setInt(_waterLastResetKey, now.millisecondsSinceEpoch);
      setState(() => _waterCups = 0);
      return;
    }

    setState(() => _waterCups = prefs.getInt('water_cups') ?? 0);
  }

  Future<void> _saveWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _waterLastResetKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('water_cups', _waterCups);
  }

  String _greetingByTime() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = _profileName.isNotEmpty ? _profileName : 'Friend';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeContent(isDark, name),
          JournalScreen(
            name: name,
            header: _buildHeader,
            showBottomNavigation: false,
            navIndexNotifier: _navIndexNotifier,
          ),
          WeeklyReflectionsScreen(
            showBottomNavigation: false,
            name: name,
            header: _buildHeader,
          ),
          const ProfileScreen(showBottomNavigation: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHomeContent(bool isDark, String name) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        children: [
          _buildHeader(name),
          const SizedBox(height: 20),
          _buildGreeting(name),
          const SizedBox(height: 6),
          const SizedBox(height: 14),
          _buildMessageOfTheDay(isDark),
          const SizedBox(height: 16),
          _buildMoodCard(isDark),
          const SizedBox(height: 16),
          _buildDayCard(isDark),
          const SizedBox(height: 16),
          _buildWaterTracker(isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MESSAGE OF THE DAY
  // ─────────────────────────────────────────────
  Widget _buildMessageOfTheDay(bool isDark) {
    final quote = _todayQuote;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B5EA7), Color(0xFFD45DA1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MESSAGE OF THE DAY',
            style: TextStyle(
              color: Color(0xFFEDE6F8),
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${quote['text']}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${quote['author']}',
            style: const TextStyle(
              color: Color(0xFFE4D8F8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MOOD CARD  (emoji + label underneath)
  // ─────────────────────────────────────────────
  Widget _buildMoodCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _moodOptions.map((option) {
              final bool isSelected = _selectedMood == option['emoji'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = option['emoji']),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE3D5FB)
                            : (isDark
                                ? const Color(0xFF2A2B38)
                                : const Color(0xFFF5F3F8)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _purple.withOpacity(0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                        border: isSelected
                            ? Border.all(
                                color: _purple.withOpacity(0.35), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(option['emoji']!,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? _purple
                            : (isDark ? const Color(0xFFA8A6B5) : _textMuted),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WATER TRACKER
  // ─────────────────────────────────────────────
  Widget _buildWaterTracker(bool isDark) {
    final double liters = _waterCups * 0.25; // 250 ml per cup

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF2F0F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Stats',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Water sub-header
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 16, color: Color(0xFF4A90D9)),
              const SizedBox(width: 6),
              Text(
                'Water',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFD5D2E2)
                      : const Color(0xFF2D2E38),
                ),
              ),
              const Spacer(),
              Text(
                '${liters.toStringAsFixed(1)}L / ${(_waterGoal * 0.25).toStringAsFixed(1)}L',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFA8A6B5)
                      : const Color(0xFF6C6B75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (_waterCups >= _waterGoal) return;
              setState(() => _waterCups++);
              _saveWaterData();
            },
            child: Container(
              width: 42,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF4A90D9).withOpacity(0.3),
                    width: 1.5),
              ),
              child: const Center(
                child:
                    Icon(Icons.add_rounded, size: 22, color: Color(0xFF4A90D9)),
              ),
            ),
          ),

          if (_waterCups > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_waterCups, (index) {
                return Container(
                  width: 36,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0E8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF4A90D9).withOpacity(0.35),
                      width: 1.3,
                    ),
                  ),
                  child: const Center(
                    child: Text('🥤', style: TextStyle(fontSize: 18)),
                  ),
                );
              }),
            ),
          ],

          if (_waterCups >= _waterGoal) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🎉 Goal reached! Great job staying hydrated.',
                style: TextStyle(
                  color: Color(0xFF2C6FAA),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(String name) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.eco_outlined,
                size: 22, color: isDark ? const Color(0xFFE5DFF0) : _purple),
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
          onTap: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            if (!mounted) return;
            await _loadProfileData();
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
            child: ClipOval(
              child: _avatarBytes != null
                  ? Image.memory(_avatarBytes!,
                      fit: BoxFit.cover, width: 44, height: 44)
                  : CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF2D2F3D) : _dark,
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String name) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${_greetingByTime()},\n$name ',
            style: TextStyle(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
            ),
          ),
          const TextSpan(text: '🌿', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DAY CARD (reflection text + stars)
  // ─────────────────────────────────────────────
  Widget _buildDayCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF2F0F5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How was your day?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
                ),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChatScreen(initialMessage: '')),
                ),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_note_rounded,
                      color: Color(0xFFC79ABF), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dayReflectionController,
            maxLines: 4,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'When the world feels too small to hold you, you\'ll always find a place in my heart..💜',
              hintStyle: TextStyle(
                color:
                    isDark ? const Color(0xFFA09DB0) : const Color(0xFFA5A3AE),
                fontSize: 14,
                height: 1.5,
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF2A2B38) : const Color(0xFFE7E4ED),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rate your day',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFD5D2E2)
                      : const Color(0xFF2D2E38),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final bool isSelected = index < _selectedRating;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 26,
                        color: isSelected ? _purple : const Color(0xFFCBC8D3),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSendToAIButton(),
        ],
      ),
    );
  }

  Widget _buildSendToAIButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D4A97), Color(0xFFE173B7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4A97).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            final String msg = _dayReflectionController.text.trim();
            if (msg.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please write your reflection first.'),
                  backgroundColor: Color(0xFF6D4A97),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  initialMessage: msg,
                  initialMood: _selectedMood,
                  initialRating: _selectedRating,
                ),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Send to AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    )),
                SizedBox(width: 6),
                Text('✨', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM NAV
  // ─────────────────────────────────────────────
  Widget _buildBottomNavigation() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool active = index == _currentNavIndex;
          return GestureDetector(
            onTap: () {
              if (index == _currentNavIndex) return;
              setState(() => _currentNavIndex = index);
              _navIndexNotifier.value = index;
            },
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
                  Icon(item['icon'] as IconData,
                      color: active
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF9C9AAF)
                              : const Color(0xFF8A9AB3)),
                      size: 20),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(item['label'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

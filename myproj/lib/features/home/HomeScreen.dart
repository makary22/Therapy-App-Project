import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/ChatScreen.dart';
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

  final List<String> _moods = ['😔', '😟', '😐', '🙂', '😄'];
  final List<Map<String, String>> _recentReflections = [];

  String? _selectedMood;
  int _selectedRating = 0;
  int _currentNavIndex = 0;

  Uint8List? _avatarBytes;
  String _profileName = '';

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _dayReflectionController.dispose();
    super.dispose();
  }

  // Loads profile image and display name for the header.
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            _buildHeader(name),
            const SizedBox(height: 20),
            _buildGreeting(name),
            const SizedBox(height: 6),
            Text(
              'Take a breath. How are you feeling right now?',
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark ? const Color(0xFFB0ADBE) : const Color(0xFF50505A),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildMoodCard(),
            const SizedBox(height: 16),
            _buildDayCard(),
            const SizedBox(height: 24),
            _buildRecentReflectionsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(String name) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
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
                  ? Image.memory(
                      _avatarBytes!,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                    )
                  : CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF2D2F3D) : _dark,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
          const TextSpan(
            text: '🌿',
            style: TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                'Current Mood',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
                ),
              ),
              Text(
                'SELECT ONE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: isDark ? const Color(0xFFA8A6B5) : _textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_moods.length, (index) {
              final String mood = _moods[index];
              final bool isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: AnimatedContainer(
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
                              color: _purple.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                    border: isSelected
                        ? Border.all(
                            color: _purple.withOpacity(0.3), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(mood, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ChatScreen(initialMessage: ''),
                    ),
                  );
                },
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
                    fontWeight: FontWeight.w600),
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
            final String initialMessage = _dayReflectionController.text.trim();
            if (initialMessage.isEmpty) {
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
                builder: (context) => ChatScreen(
                  initialMessage: initialMessage,
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
                Text(
                  'Send to AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 6),
                Text('✨', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReflectionsSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reflections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF2EEF9) : _textPrimary,
              ),
            ),
            Text(
              'VIEW JOURNAL',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: _purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentReflections.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF5F3F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 40,
                    color: isDark ? const Color(0xFF67657A) : Colors.grey[350]),
                const SizedBox(height: 10),
                Text(
                  'No reflections yet',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? const Color(0xFFC2BFCE) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Write your first note and it will appear here.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9A97A8) : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentReflections.map(_buildRecentReflectionCard),
      ],
    );
  }

  Widget _buildRecentReflectionCard(Map<String, String> reflection) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF5F3F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reflection['mood']!, style: const TextStyle(fontSize: 26)),
              Text(
                reflection['date']!,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFC1BECE)
                      : const Color(0xFF3B3C46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  reflection['text']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFC8C5D6)
                        : const Color(0xFF4D4E58),
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _purple, size: 16),
            ],
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            onTap: () async {
              if (index == 2) {
                setState(() => _currentNavIndex = index);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WeeklyReflectionsScreen(),
                  ),
                );
                if (!mounted) return;
                setState(() => _currentNavIndex = 0);
                return;
              }
              if (index == 3) {
                setState(() => _currentNavIndex = index);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (!mounted) return;
                // FIX: reload الصورة والـ nickname بعد الرجوع
                await _loadProfileData();
                setState(() => _currentNavIndex = 0);
                return;
              }
              setState(() => _currentNavIndex = index);
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

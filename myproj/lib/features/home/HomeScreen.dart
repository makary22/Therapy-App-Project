import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  // ── Colors ──
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _dark = Color(0xFF1A1A2E);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void dispose() {
    _dayReflectionController.dispose();
    super.dispose();
  }

  String _greetingByTime() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = (user?.displayName ?? '').trim();
    final String email = (user?.email ?? '').trim();
    final String name = displayName.isNotEmpty
        ? displayName.split(' ').first
        : (email.isNotEmpty ? email.split('@').first : 'Friend');

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            _buildHeader(name),
            const SizedBox(height: 20),
            _buildGreeting(name),
            const SizedBox(height: 6),
            const Text(
              'Take a breath. How are you feeling right now?',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF50505A),
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

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.eco_outlined, size: 22, color: _purple),
            SizedBox(width: 6),
            Text(
              'Safe Space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _purple,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4D2DD), width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: _dark,
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
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GREETING
  // ─────────────────────────────────────────────────────────────
  Widget _buildGreeting(String name) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${_greetingByTime()},\n$name ',
            style: const TextStyle(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
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

  // ─────────────────────────────────────────────────────────────
  // MOOD CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildMoodCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Current Mood',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Text(
                'SELECT ONE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: _textMuted,
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
                        : const Color(0xFFF5F3F8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _purple.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
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

  // ─────────────────────────────────────────────────────────────
  // DAY CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildDayCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'How was your day?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Icon(Icons.edit_note_rounded, color: Color(0xFFC79ABF), size: 22),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dayReflectionController,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 14,
              color: _textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Write freely, no judgment here...',
              hintStyle: const TextStyle(
                color: Color(0xFFA5A3AE),
                fontSize: 14,
                height: 1.5,
              ),
              filled: true,
              fillColor: const Color(0xFFE7E4ED),
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
              const Text(
                'Rate your day',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D2E38),
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

  // ─────────────────────────────────────────────────────────────
  // SEND TO AI BUTTON
  // ─────────────────────────────────────────────────────────────
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
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (_dayReflectionController.text.trim().isNotEmpty ||
                _selectedMood != null ||
                _selectedRating > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reflection sent to AI for analysis! ✨'),
                  backgroundColor: Color(0xFF6D4A97),
                ),
              );
            }
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

  // ─────────────────────────────────────────────────────────────
  // RECENT REFLECTIONS
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentReflectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Recent Reflections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
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
              color: const Color(0xFFF5F3F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 40, color: Colors.grey[350]),
                const SizedBox(height: 10),
                Text(
                  'No reflections yet',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Write your first note and it will appear here.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F8),
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
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B3C46),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4D4E58),
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

  // ─────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomNavigation() {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'HOME'},
      {'icon': Icons.menu_book_outlined, 'label': 'JOURNAL'},
      {'icon': Icons.insights_outlined, 'label': 'INSIGHTS'},
      {'icon': Icons.person_outline_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EEF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
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
            onTap: () => setState(() => _currentNavIndex = index),
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
                    color: active ? Colors.white : const Color(0xFF8A9AB3),
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
}

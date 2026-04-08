import 'package:flutter/material.dart';

class AdviceSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const AdviceSummaryScreen({
    super.key,
    required this.messages,
  });

  // ── Colors (matches Home + Chat) ──
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBg2 = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  // ─────────────────────────────────────────────────────────────
  // LOGIC — reads ALL messages for better analysis
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _buildSummaryData() {
    final userMessages =
        messages.where((m) => (m['isUser'] ?? false) == true).toList();
    final aiMessages =
        messages.where((m) => (m['isUser'] ?? false) == false).toList();

    // ── Extract mood + rating from first user message ──
    final firstUser = userMessages.isNotEmpty ? userMessages.first : null;
    final String mood = (firstUser?['mood'] as String?) ?? '';
    final int rating = (firstUser?['rating'] as int?) ?? 0;

    // ── Combine ALL user text for deeper analysis ──
    final String fullUserText = userMessages
        .map((m) => (m['text'] as String?) ?? '')
        .where((t) => t.isNotEmpty)
        .join(' ')
        .toLowerCase();

    // ── Keyword detection ──
    final bool hasAnxiety = _containsAny(fullUserText,
        ['anxious', 'anxiety', 'worried', 'nervous', 'panic', 'قلق', 'خايف']);
    final bool hasSadness = _containsAny(fullUserText,
        ['sad', 'cry', 'depressed', 'hopeless', 'empty', 'حزين', 'زهقت']);
    final bool hasStress = _containsAny(fullUserText,
        ['stress', 'overwhelm', 'tired', 'exhaust', 'pressure', 'تعبان', 'ضغط']);
    final bool hasPositive = _containsAny(fullUserText,
        ['happy', 'great', 'good', 'productive', 'grateful', 'كويس', 'تمام']);
    final bool hasAnger = _containsAny(fullUserText,
        ['angry', 'anger', 'frustrated', 'annoyed', 'mad', 'زعلان', 'غضبان']);

    // ── Determine dominant state ──
    String tag;
    String tagEmoji;
    Color tagColor;
    String headline;
    String insight;
    List<Map<String, dynamic>> tips;

    // Priority: mood emoji > rating > keywords
    final bool lowMood = mood == '😔' || mood == '😟';
    final bool highMood = mood == '🙂' || mood == '😄';
    final bool lowRating = rating > 0 && rating <= 2;
    final bool highRating = rating >= 4;

    if (hasAnxiety || (lowMood && hasStress)) {
      tag = 'ANXIOUS';
      tagEmoji = '🌊';
      tagColor = const Color(0xFF7B9FD4);
      headline = 'Your mind is working overtime right now.';
      insight =
          'Anxiety often spikes when we feel like we\'re losing control of things around us. '
          'What you\'re feeling is real — and it makes sense. Your nervous system is trying to protect you, '
          'even when it doesn\'t feel helpful.\n\n'
          'The key right now is to signal safety to your body, not to solve everything at once.';
      tips = _anxietyTips();
    } else if (hasSadness || (lowMood && !hasStress) || lowRating) {
      tag = 'HEAVY-HEARTED';
      tagEmoji = '🌧️';
      tagColor = const Color(0xFF9B8EC4);
      headline = 'It\'s okay to not be okay today.';
      insight =
          'Sadness is not weakness — it\'s your heart processing something that mattered to you. '
          'You don\'t have to rush through it or explain it to anyone.\n\n'
          'Being here and writing it out is already a courageous step. '
          'Allow yourself the space to feel without judgment.';
      tips = _sadnessTips();
    } else if (hasAnger) {
      tag = 'FRUSTRATED';
      tagEmoji = '🔥';
      tagColor = const Color(0xFFD47B7B);
      headline = 'Something — or someone — pushed your limits today.';
      insight =
          'Anger is often a signal that a boundary was crossed or something important to you was dismissed. '
          'It\'s one of the most honest emotions we have.\n\n'
          'Rather than suppressing it, try to find what\'s underneath — '
          'is it hurt? Disappointment? Feeling unheard? That\'s where the real message lives.';
      tips = _angerTips();
    } else if (hasStress || (lowRating && !hasSadness)) {
      tag = 'OVERWHELMED';
      tagEmoji = '⚡';
      tagColor = const Color(0xFFD4A57B);
      headline = 'You\'ve been carrying too much at once.';
      insight =
          'When everything feels urgent, nothing gets the attention it deserves — '
          'and that includes you. Overwhelm usually means your plate is full, not that you are weak.\n\n'
          'Breaking things into smaller pieces and giving yourself permission to do less '
          'is not giving up — it\'s smart energy management.';
      tips = _stressTips();
    } else if (hasPositive || highMood || highRating) {
      tag = 'THRIVING';
      tagEmoji = '🌱';
      tagColor = const Color(0xFF7EC8A4);
      headline = 'You\'re showing up for yourself — and it shows.';
      insight =
          'There\'s real momentum in your reflection today. Whether it was a big win or a quiet sense of okayness, '
          'noticing it and naming it matters.\n\n'
          'Keep building on these moments. Small consistent actions '
          'compound into the life you\'re working toward.';
      tips = _positiveTips();
    } else {
      tag = 'REFLECTING';
      tagEmoji = '🌿';
      tagColor = _purple;
      headline = 'You showed up and that already matters.';
      insight =
          'Sometimes we don\'t have a clear label for how we feel — and that\'s completely valid. '
          'Life often exists in the gray areas between emotions.\n\n'
          'The fact that you took time to reflect means you\'re paying attention to yourself. '
          'That\'s the foundation of emotional awareness.';
      tips = _defaultTips();
    }

    // ── Message count stats ──
    final int userMsgCount = userMessages.length;
    final int aiMsgCount = aiMessages.length;

    return {
      'tag': tag,
      'tagEmoji': tagEmoji,
      'tagColor': tagColor,
      'headline': headline,
      'insight': insight,
      'tips': tips,
      'mood': mood,
      'rating': rating,
      'userMsgCount': userMsgCount,
      'aiMsgCount': aiMsgCount,
    };
  }

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ─────────────────────────────────────────────────────────────
  // TIPS SETS
  // ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _anxietyTips() => [
        {
          'icon': Icons.air_rounded,
          'title': 'Box Breathing',
          'subtitle': 'Inhale 4s → Hold 4s → Exhale 4s. Repeat 4 times.',
        },
        {
          'icon': Icons.remove_red_eye_outlined,
          'title': '5-4-3-2-1 Grounding',
          'subtitle': 'Name 5 things you see, 4 you hear, 3 you can touch.',
        },
        {
          'icon': Icons.self_improvement_rounded,
          'title': 'Body Scan',
          'subtitle': 'Close your eyes. Notice where tension lives in your body.',
        },
      ];

  List<Map<String, dynamic>> _sadnessTips() => [
        {
          'icon': Icons.edit_outlined,
          'title': 'Write It Out',
          'subtitle': 'Let your feelings land on paper without editing them.',
        },
        {
          'icon': Icons.people_outline_rounded,
          'title': 'Reach Out',
          'subtitle': 'Send one message to someone who makes you feel safe.',
        },
        {
          'icon': Icons.bedtime_outlined,
          'title': 'Rest Without Guilt',
          'subtitle': 'Allow yourself to rest. Recovery is productive too.',
        },
      ];

  List<Map<String, dynamic>> _angerTips() => [
        {
          'icon': Icons.directions_walk_rounded,
          'title': 'Move Your Body',
          'subtitle': 'Walk, stretch, or shake — anger needs physical release.',
        },
        {
          'icon': Icons.question_mark_rounded,
          'title': 'Ask Underneath',
          'subtitle': 'What boundary was crossed? What really hurts here?',
        },
        {
          'icon': Icons.timer_outlined,
          'title': '10-Minute Pause',
          'subtitle': 'Wait before responding. Give your cortisol time to drop.',
        },
      ];

  List<Map<String, dynamic>> _stressTips() => [
        {
          'icon': Icons.checklist_rounded,
          'title': 'Unload Tomorrow',
          'subtitle': 'Write 3 things that can wait. Give them a future date.',
        },
        {
          'icon': Icons.block_rounded,
          'title': 'Say No Once Today',
          'subtitle': 'Pick one thing you can decline or delegate right now.',
        },
        {
          'icon': Icons.coffee_outlined,
          'title': 'One-Minute Reset',
          'subtitle': 'Step away. Make tea. Do one thing slowly and fully.',
        },
      ];

  List<Map<String, dynamic>> _positiveTips() => [
        {
          'icon': Icons.star_outline_rounded,
          'title': 'Capture This Feeling',
          'subtitle': 'Write what made today good. You\'ll want to remember it.',
        },
        {
          'icon': Icons.repeat_rounded,
          'title': 'Identify What Worked',
          'subtitle': 'What habit or decision helped today? Do more of that.',
        },
        {
          'icon': Icons.favorite_outline_rounded,
          'title': 'Share Gratitude',
          'subtitle': 'Tell someone today that they made a difference.',
        },
      ];

  List<Map<String, dynamic>> _defaultTips() => [
        {
          'icon': Icons.auto_stories_outlined,
          'title': 'Daily Check-in',
          'subtitle': 'Keep showing up. Consistency builds self-awareness.',
        },
        {
          'icon': Icons.nature_outlined,
          'title': 'Spend Time Outside',
          'subtitle': 'Even 10 minutes of daylight shifts your nervous system.',
        },
        {
          'icon': Icons.nights_stay_outlined,
          'title': 'Protect Your Sleep',
          'subtitle': 'A good night\'s rest resets more than you think.',
        },
      ];

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = _buildSummaryData();
    final tips = data['tips'] as List<Map<String, dynamic>>;
    final String mood = data['mood'] as String;
    final int rating = data['rating'] as int;
    final Color tagColor = data['tagColor'] as Color;
    final int userMsgCount = data['userMsgCount'] as int;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main insight card ──
            _buildInsightCard(data, tagColor),
            const SizedBox(height: 16),

            // ── Session stats row ──
            if (mood.isNotEmpty || rating > 0 || userMsgCount > 1)
              _buildStatsRow(mood, rating, userMsgCount),

            const SizedBox(height: 22),

            // ── Tips section ──
            const Text(
              'GENTLE STEPS FORWARD',
              style: TextStyle(
                color: _textMuted,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => _buildTipCard(tip)),

            const SizedBox(height: 28),

            // ── Closing quote ──
            _buildQuoteCard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cardBg2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 16),
        ),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 16, color: _purple),
          SizedBox(width: 5),
          Text(
            'Safe Space',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _purple,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INSIGHT CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildInsightCard(Map<String, dynamic> data, Color tagColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag pill
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['tagEmoji'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      data['tag'] as String,
                      style: TextStyle(
                        color: tagColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            data['headline'] as String,
            style: TextStyle(
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: tagColor == _purple ? _purple : _textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tagColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Insight text
          Text(
            data['insight'] as String,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STATS ROW
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(String mood, int rating, int msgCount) {
    return Row(
      children: [
        if (mood.isNotEmpty)
          _statChip(
            label: 'Mood',
            value: mood,
            isEmoji: true,
          ),
        if (mood.isNotEmpty) const SizedBox(width: 10),
        if (rating > 0)
          _statChip(
            label: 'Day Rating',
            value: '$rating / 5',
            icon: Icons.star_rounded,
          ),
        if (rating > 0) const SizedBox(width: 10),
        if (msgCount > 1)
          _statChip(
            label: 'Messages',
            value: '$msgCount',
            icon: Icons.chat_bubble_outline_rounded,
          ),
      ],
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    IconData? icon,
    bool isEmoji = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, size: 14, color: _purple),
              if (isEmoji)
                Text(value, style: const TextStyle(fontSize: 16)),
              if (!isEmoji) ...[
                const SizedBox(width: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TIP CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDAC7F7), Color(0xFFF0C9E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tip['icon'] as IconData,
              size: 18,
              color: _purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'] as String,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip['subtitle'] as String,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFBBB6C9), size: 22),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUOTE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withOpacity(0.08),
            _pink.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _purple.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: const [
          Text(
            '"The sun will rise and we will try again"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _purple,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'SAFE SPACE AI',
            style: TextStyle(
              color: _textMuted,
              letterSpacing: 2.5,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

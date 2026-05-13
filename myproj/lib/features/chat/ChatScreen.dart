import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AdviceSummaryScreen.dart';
import 'ai_service.dart';

class ChatScreen extends StatefulWidget {
  final String initialMessage;
  final String? initialMood;
  final int initialRating;
  final int? initialSessionIndex;

  const ChatScreen({
    super.key,
    required this.initialMessage,
    this.initialMood,
    this.initialRating = 0,
    this.initialSessionIndex,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Each session = { 'date': String, 'messages': List<Map> }
  final List<Map<String, dynamic>> _sessions = [];
  int _activeSessionIndex = -1;
  bool _isTyping = false;
  static const String _historyStorageKey = 'chat_sessions_v1';

  // ── Colors (matches HomeScreen) ──
  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _bg = Color(0xFFF4F1F8);
  static const Color _cardBg = Color(0xFFECE9F2);
  static const Color _textPrimary = Color(0xFF1E1F29);
  static const Color _textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ─────────────────────────────────────────────────────────────
  Future<void> _bootstrapChat() async {
    await _loadSessions();

    final int? targetSessionIndex = widget.initialSessionIndex;
    if (targetSessionIndex != null &&
        targetSessionIndex >= 0 &&
        targetSessionIndex < _sessions.length) {
      if (!mounted) return;
      setState(() {
        _activeSessionIndex = targetSessionIndex;
        _isTyping = false;
      });
      _scrollToBottom();
      return;
    }

    final String firstMessage = widget.initialMessage.trim();
    if (firstMessage.isEmpty) return;
    _startNewSession(firstMessage);
  }

  void _startNewSession(String firstMessage) {
    final now = DateTime.now();

    _sessions.add({
      'date': _formatDateLabel(now),
      'createdAt': now,
      'messages': <Map<String, dynamic>>[
        {
          'text': firstMessage,
          'isUser': true,
          'timestamp': now,
          'mood': widget.initialMood,
          'rating': widget.initialRating,
        },
      ],
      'favorite': false,
    });
    _activeSessionIndex = _sessions.length - 1;
    _saveSessions();

    Future.delayed(
      const Duration(milliseconds: 800),
      () => _simulateAIResponse(firstMessage),
    );
  }

  Future<void> _simulateAIResponse(String userMessage) async {
    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();

    String reply;
    try {
      reply = await AIService.sendConversationMessage(
        messages: _currentMessages,
        memoryContext: _buildMemoryContext(),
      );
    } catch (e, st) {
      debugPrint('Gemini initial reply error: $e');
      debugPrint(st.toString());
      reply = kDebugMode
          ? 'Gemini error: $e'
          : "Thank you for sharing that with me. I am here with you, and we can take this one step at a time.";
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _currentMessages.add({
        'text': reply,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    });
    _saveSessions();
    _scrollToBottom();
  }

  List<Map<String, dynamic>> get _currentMessages {
    if (_sessions.isEmpty ||
        _activeSessionIndex < 0 ||
        _activeSessionIndex >= _sessions.length) {
      return [];
    }
    return _sessions[_activeSessionIndex]['messages']
        as List<Map<String, dynamic>>;
  }

  String _buildMemoryContext() {
    if (_sessions.isEmpty || _activeSessionIndex <= 0) {
      return '';
    }

    final buffer = StringBuffer();
    for (var sessionIndex = 0;
        sessionIndex < _activeSessionIndex;
        sessionIndex++) {
      final session = _sessions[sessionIndex];
      final String date =
          (session['date'] as String?) ?? 'Session ${sessionIndex + 1}';
      final messages = session['messages'] as List<Map<String, dynamic>>;

      buffer.writeln('Session ${sessionIndex + 1} [$date]');
      for (final message in messages) {
        final String text = (message['text'] as String? ?? '').trim();
        if (text.isEmpty) continue;

        final bool isUser = (message['isUser'] ?? false) == true;
        buffer.writeln('${isUser ? 'User' : 'Assistant'}: $text');
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────
  // SEND MESSAGE
  // ─────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    final String userMessage = message;

    setState(() {
      _currentMessages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });
    _saveSessions();

    _messageController.clear();
    _scrollToBottom();

    String reply;
    try {
      reply = await AIService.sendConversationMessage(
        messages: _currentMessages,
        memoryContext: _buildMemoryContext(),
      );
    } catch (e, st) {
      debugPrint('Gemini send message error: $e');
      debugPrint(st.toString());
      reply = kDebugMode
          ? 'Gemini error: $e'
          : 'I hear you. That sounds really challenging. Remember, it\'s okay to take things one step at a time.';
    }

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _currentMessages.add({
        'text': reply,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    });
    _saveSessions();
    _scrollToBottom();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_historyStorageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = <Map<String, dynamic>>[];
      for (final session in decoded) {
        if (session is! Map<String, dynamic>) continue;
        final messagesRaw = session['messages'];
        if (messagesRaw is! List) continue;

        final messages = <Map<String, dynamic>>[];
        for (final msg in messagesRaw) {
          if (msg is! Map<String, dynamic>) continue;
          final ts = msg['timestamp'];
          DateTime? timestamp;
          if (ts is String) {
            timestamp = DateTime.tryParse(ts);
          }

          messages.add({
            'text': msg['text'] ?? '',
            'isUser': msg['isUser'] ?? false,
            'timestamp': timestamp,
            'mood': msg['mood'],
            'rating': msg['rating'] ?? 0,
          });
        }

        final createdAtRaw = session['createdAt'];
        DateTime? createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw);
        }

        loaded.add({
          'date': session['date'] ?? '',
          'createdAt': createdAt,
          'messages': messages,
          'favorite': session['favorite'] ?? false,
        });
      }

      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(loaded);
        _activeSessionIndex = _sessions.isEmpty ? -1 : _sessions.length - 1;
      });
    } catch (_) {
      // Ignore invalid cached history and continue with empty history.
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _sessions.map((session) {
      final messages = (session['messages'] as List<Map<String, dynamic>>)
          .map((msg) => {
                'text': msg['text'],
                'isUser': msg['isUser'],
                'timestamp': (msg['timestamp'] as DateTime?)?.toIso8601String(),
                'mood': msg['mood'],
                'rating': msg['rating'],
              })
          .toList();

      return {
        'date': session['date'],
        'createdAt': (session['createdAt'] as DateTime?)?.toIso8601String(),
        'messages': messages,
        'favorite': session['favorite'] ?? false,
      };
    }).toList();

    await prefs.setString(_historyStorageKey, jsonEncode(serialized));
  }

  bool get _currentSessionIsFavorite {
    if (_sessions.isEmpty ||
        _activeSessionIndex < 0 ||
        _activeSessionIndex >= _sessions.length) return false;
    return _sessions[_activeSessionIndex]['favorite'] ?? false;
  }

  void _toggleFavorite() {
    if (_sessions.isEmpty ||
        _activeSessionIndex < 0 ||
        _activeSessionIndex >= _sessions.length) return;
    setState(() {
      final cur = _sessions[_activeSessionIndex];
      cur['favorite'] = !(cur['favorite'] ?? false);
    });
    _saveSessions();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      '',
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
      'Dec'
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _sessionDateLabel(Map<String, dynamic> session) {
    final createdAtRaw = session['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    if (createdAt != null) {
      return _formatDateLabel(createdAt);
    }

    final messagesRaw = session['messages'];
    if (messagesRaw is List && messagesRaw.isNotEmpty) {
      final firstMessage = messagesRaw.first;
      if (firstMessage is Map<String, dynamic>) {
        final firstTimestampRaw = firstMessage['timestamp'];
        DateTime? firstTimestamp;
        if (firstTimestampRaw is DateTime) {
          firstTimestamp = firstTimestampRaw;
        } else if (firstTimestampRaw is String) {
          firstTimestamp = DateTime.tryParse(firstTimestampRaw);
        }

        if (firstTimestamp != null) {
          return _formatDateLabel(firstTimestamp);
        }
      }
    }

    final fallbackLabel = session['date'] as String?;
    if (fallbackLabel != null && fallbackLabel.isNotEmpty) {
      return fallbackLabel;
    }

    return 'Session';
  }

  bool get _canShowSummary {
    if (_sessions.isEmpty ||
        _activeSessionIndex < 0 ||
        _activeSessionIndex >= _sessions.length) {
      return false;
    }

    final messages = _sessions[_activeSessionIndex]['messages']
        as List<Map<String, dynamic>>;
    return messages.length >= 2 && !_isTyping;
  }

  void _openSummaryScreen() {
    if (!_canShowSummary) return;

    final messages = List<Map<String, dynamic>>.from(
      _sessions[_activeSessionIndex]['messages'] as List<Map<String, dynamic>>,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdviceSummaryScreen(messages: messages),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChatBody()),
          if (_canShowSummary)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _openSummaryScreen,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2B38) : _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 15, color: _purple),
                        SizedBox(width: 6),
                        Text(
                          'Summary',
                          style: TextStyle(
                            color: _purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF12131C) : _bg,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2B38) : _cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
            size: 16,
          ),
        ),
      ),
      title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
          Text(
            'AI Companion',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFFA8A6B5) : _textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        // History toggle button
        GestureDetector(
          onTap: _showHistorySheet,
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2B38) : _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.history_rounded, size: 16, color: _purple),
                SizedBox(width: 4),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Favorite toggle
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
          child: GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              width: 42,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2B38) : _cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _currentSessionIsFavorite ? Icons.star : Icons.star_border,
                color: _purple,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT BODY
  // ─────────────────────────────────────────────────────────────
  Widget _buildChatBody() {
    if (_sessions.isEmpty ||
        _activeSessionIndex < 0 ||
        _activeSessionIndex >= _sessions.length) {
      return const SizedBox.shrink();
    }

    final allItems = <dynamic>[];
    final currentSession = _sessions[_activeSessionIndex];

    allItems.add({
      'type': 'divider',
      'label': _sessionDateLabel(currentSession),
    });
    final msgs = currentSession['messages'] as List<Map<String, dynamic>>;
    for (final msg in msgs) {
      allItems.add({'type': 'message', ...msg});
    }

    if (_isTyping) allItems.add({'type': 'typing'});

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        if (item['type'] == 'divider') {
          return _buildDateDivider(item['label'] as String);
        }
        if (item['type'] == 'typing') {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(item as Map<String, dynamic>);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DATE DIVIDER
  // ─────────────────────────────────────────────────────────────
  Widget _buildDateDivider(String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF3A3B4D) : const Color(0xFFDDD9E8),
              thickness: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2B38) : _cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA8A6B5) : _textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF3A3B4D) : const Color(0xFFDDD9E8),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MESSAGE BUBBLE
  // ─────────────────────────────────────────────────────────────
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isUser = message['isUser'] ?? false;
    final String text = message['text'] ?? '';
    final DateTime? timestamp = message['timestamp'] as DateTime?;
    final String? mood = message['mood'] as String?;
    final int rating = (message['rating'] ?? 0) as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Mood + rating badge (only on first user message)
          if (isUser && mood != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2B38) : _cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mood, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  if (rating > 0) ...[
                    const Text('·',
                        style: TextStyle(color: _textMuted, fontSize: 12)),
                    const SizedBox(width: 6),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 13,
                        color: i < rating ? _purple : const Color(0xFFCBC8D3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Bubble
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // AI avatar
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D4A97), Color(0xFFE173B7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6D4A97), Color(0xFF9B6DC5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : (isDark ? const Color(0xFF1A1C27) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? Colors.white
                          : (isDark ? const Color(0xFFF1EEF8) : _textPrimary),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ],
          ),

          // Timestamp
          if (timestamp != null)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isUser ? 0 : 42,
                right: isUser ? 2 : 0,
              ),
              child: Text(
                _formatTime(timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: _textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TYPING INDICATOR
  // ─────────────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D4A97), Color(0xFFE173B7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C27) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INPUT BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C27) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFF1EEF8) : _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Share what\'s on your mind...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFFA09DB0)
                        : const Color(0xFFA5A3AE),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A2B38)
                      : const Color(0xFFF5F3F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D4A97), Color(0xFFE173B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6D4A97).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HISTORY BOTTOM SHEET
  // ─────────────────────────────────────────────────────────────
  void _openHistorySession(int sessionIndex) {
    if (sessionIndex < 0 || sessionIndex >= _sessions.length) return;

    setState(() {
      _activeSessionIndex = sessionIndex;
      _isTyping = false;
    });

    Navigator.pop(context);
    _scrollToBottom();
  }

  Future<void> _confirmDeleteSession(int sessionIndex) async {
    if (sessionIndex < 0 || sessionIndex >= _sessions.length) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation'),
        content:
            const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteSession(sessionIndex);
      // Close the history sheet after deletion so UI updates.
      Navigator.pop(context);
    }
  }

  void _deleteSession(int sessionIndex) {
    if (sessionIndex < 0 || sessionIndex >= _sessions.length) return;

    setState(() {
      _sessions.removeAt(sessionIndex);
      if (_sessions.isEmpty) {
        _activeSessionIndex = -1;
      } else {
        _activeSessionIndex =
            (_sessions.length - 1).clamp(0, _sessions.length - 1);
      }
    });

    _saveSessions();
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C27) : const Color(0xFFF4F1F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF5D5B6C)
                        : const Color(0xFFCBC8D3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: _purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? const Color(0xFFF4F1FA) : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF343647)
                      : const Color(0xFFE0DCF0),
                ),

                // Sessions list
                Expanded(
                  child: _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48,
                                  color: isDark
                                      ? const Color(0xFF646276)
                                      : Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(
                                'No history yet',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFB5B2C4)
                                        : Colors.grey[500],
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _sessions.length,
                          itemBuilder: (_, i) {
                            // Show newest first
                            final int sessionIndex = _sessions.length - 1 - i;
                            final session = _sessions[sessionIndex];
                            final msgs = session['messages']
                                as List<Map<String, dynamic>>;
                            final firstMsg =
                                msgs.isNotEmpty ? msgs.first : null;
                            final msgCount = msgs.length;
                            final String mood =
                                (firstMsg?['mood'] as String?) ?? '';
                            final int rating =
                                (firstMsg?['rating'] as int?) ?? 0;
                            final String preview =
                                (firstMsg?['text'] as String?) ?? '';

                            return GestureDetector(
                              onTap: () => _openHistorySession(sessionIndex),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF232432)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date + mood row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            if (mood.isNotEmpty)
                                              Text(mood,
                                                  style: const TextStyle(
                                                      fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text(
                                              _sessionDateLabel(session),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFFF1EEF8)
                                                    : _textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF2F3141)
                                                    : _cardBg,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$msgCount msgs',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? const Color(0xFFB2AFC1)
                                                      : _textMuted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () =>
                                                  _confirmDeleteSession(
                                                      sessionIndex),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF2F3141)
                                                      : _cardBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: isDark
                                                      ? const Color(0xFFB2AFC1)
                                                      : _purple,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Rating
                                    if (rating > 0) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (j) => Icon(
                                            j < rating
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 14,
                                            color: j < rating
                                                ? _purple
                                                : const Color(0xFFCBC8D3),
                                          ),
                                        ),
                                      ),
                                    ],

                                    // Preview
                                    const SizedBox(height: 8),
                                    Text(
                                      preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? const Color(0xFFB2AFC1)
                                            : _textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

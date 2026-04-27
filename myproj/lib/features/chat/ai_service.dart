import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const apiKey = "AIzaSyCWZ3QPJKGm7j6qkDBDAqZOtxHPu-lk48Y";

  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
  ];

  static Future<String> sendMessage(String message) async {
    final errors = <String>[];

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent([Content.text(message)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
        errors.add('$modelName => Empty response');
      } catch (e) {
        errors.add('$modelName => $e');
      }
    }

    throw Exception('Gemini request failed. ${errors.join(' | ')}');
  }

  static Future<String> sendConversationMessage({
    required List<Map<String, dynamic>> messages,
    String? memoryContext,
  }) async {
    final errors = <String>[];
    final language = _detectConversationLanguage(messages);
    final history = _buildConversationHistory(messages);

    final languageInstruction = language == 'ar'
        ? 'رد بالعربية فقط وبأسلوب طبيعي وداعم.'
        : 'Reply in English only with a natural, supportive tone.';

    final prompt = '''
You are a compassionate mental wellness assistant having an ongoing conversation.
${languageInstruction}
Use the conversation history to remember earlier messages, references, and emotional context.
${memoryContext != null && memoryContext.trim().isNotEmpty ? 'Previous chat memory:\n$memoryContext\n' : ''}
Do not mention that you are an AI with limited memory.
Keep the reply concise, warm, and directly relevant to the latest user message.

Conversation history:
$history

Assistant reply:
''';

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return _cleanGeneratedText(text);
        }
        errors.add('$modelName => Empty response');
      } catch (e) {
        errors.add('$modelName => $e');
      }
    }

    throw Exception(
        'Gemini conversation request failed. ${errors.join(' | ')}');
  }

  static Future<Map<String, String>> generateConversationSummary({
    required List<Map<String, dynamic>> messages,
  }) async {
    final language = _detectConversationLanguage(messages);
    final conversation = messages
        .map((m) {
          final text = (m['text'] as String? ?? '').trim();
          if (text.isEmpty) return '';
          final isUser = (m['isUser'] ?? false) == true;
          return '${isUser ? 'User' : 'AI'}: $text';
        })
        .where((line) => line.isNotEmpty)
        .join('\n');

    final languageInstruction = language == 'ar'
        ? 'اكتب الرد بالكامل باللغة العربية فقط. استخدم العربية الطبيعية الواضحة، ولا تخلطها بالإنجليزية إلا لو كان ذلك ضروريًا جدًا بسبب اسم علم أو مصطلح تقني.'
        : 'Write the entire response in English only. Use clear natural English and do not mix languages unless absolutely necessary for a name or technical term.';

    final prompt = '''
You are a compassionate mental wellness assistant.
${languageInstruction}
Analyze the conversation and return ONLY valid JSON with this exact schema:
{"tag":"ANXIOUS|HEAVY-HEARTED|FRUSTRATED|OVERWHELMED|THRIVING|REFLECTING","headline":"string","insight":"string"}

Rules:
- Keep the headline to 8-16 words.
- Keep insight to 2 short paragraphs max, supportive tone.
- Do not include markdown.
- Do not include any keys other than tag, headline, insight.

Conversation:
$conversation
''';

    final raw = await sendMessage(prompt);
    final parsed = _tryParseJsonObject(raw);
    if (parsed == null) {
      throw Exception('Summary response was not valid JSON. Raw: $raw');
    }

    final tag = (parsed['tag'] as String? ?? '').trim().toUpperCase();
    final headline = _cleanGeneratedText(parsed['headline'] as String? ?? '');
    final insight = _cleanGeneratedText(parsed['insight'] as String? ?? '');

    if (tag.isEmpty || headline.isEmpty || insight.isEmpty) {
      throw Exception('Summary response missing required fields. Raw: $raw');
    }

    return {
      'tag': tag,
      'headline': headline,
      'insight': insight,
    };
  }

  static String _cleanGeneratedText(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[\*_`]+'), '')
        .replaceAll(RegExp(r'^[\s]*[-•–—]+[\s]*', multiLine: true), '')
        .replaceAll(RegExp(r'^[\s]*\d+[\.)][\s]*', multiLine: true), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return normalized;
  }

  static String _buildConversationHistory(List<Map<String, dynamic>> messages) {
    final recentMessages = messages.length > 16
        ? messages.sublist(messages.length - 16)
        : messages;

    return recentMessages
        .map((message) {
          final text = _cleanGeneratedText(message['text'] as String? ?? '');
          if (text.isEmpty) {
            return '';
          }

          final isUser = (message['isUser'] ?? false) == true;
          return '${isUser ? 'User' : 'Assistant'}: $text';
        })
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static String _detectConversationLanguage(
      List<Map<String, dynamic>> messages) {
    final userText = messages
        .where((message) => (message['isUser'] ?? false) == true)
        .map((message) => (message['text'] as String? ?? '').trim())
        .where((text) => text.isNotEmpty)
        .join(' ')
        .toLowerCase();

    if (userText.isEmpty) {
      return 'en';
    }

    final arabicLetters =
        RegExp(r'[\u0600-\u06FF]').allMatches(userText).length;
    final englishLetters = RegExp(r'[a-z]').allMatches(userText).length;

    if (arabicLetters > englishLetters) {
      return 'ar';
    }

    final arabicHints = [
      'انا',
      'إنا',
      'مش',
      'ما',
      'ليه',
      'كده',
      'خايف',
      'حزين',
      'تعبان',
      'قلق',
      'زهقت',
    ];

    if (arabicHints.any(userText.contains)) {
      return 'ar';
    }

    return 'en';
  }

  static Map<String, dynamic>? _tryParseJsonObject(String raw) {
    final trimmed = raw.trim();

    try {
      final direct = jsonDecode(trimmed);
      if (direct is Map<String, dynamic>) return direct;
    } catch (_) {
      // Try extracting a JSON object from wrapped text.
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonPart = trimmed.substring(start, end + 1);
    try {
      final extracted = jsonDecode(jsonPart);
      if (extracted is Map<String, dynamic>) return extracted;
    } catch (_) {
      return null;
    }

    return null;
  }
}

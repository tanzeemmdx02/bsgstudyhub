import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Helper to detect if a text contains Bengali Unicode characters
bool isBanglaText(String text) {
  return RegExp(r'[\u0980-\u09FF]').hasMatch(text);
}

/// Helper to convert English digits to Bangla digits
String toBanglaDigits(dynamic number) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number.toString().split('').map((ch) {
    final n = int.tryParse(ch);
    return n != null ? bn[n] : ch;
  }).join('');
}

class GeneratedMcq {
  final String type;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  GeneratedMcq({
    this.type = 'question',
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  bool get isPassage => type == 'passage';

  static String _stripLeadingSerial(String raw) {
    var t = raw.trim();
    t = t.replaceFirst(
      RegExp(r'^(?:(?:প্রশ্ন|question|q)\s*[:\.]?\s*)?(?:[০-৯]+|[0-9]+)\s*[\.\)\]\|:–-]\s*', caseSensitive: false),
      '',
    );
    return t.trim();
  }

  static String _stripOptionPrefix(String raw) {
    var o = raw.trim();
    o = o.replaceFirst(
      RegExp(r'^\(?[ক-ঘa-dA-D]\)?\s*[\.\)\]\|:–-]?\s*'),
      '',
    );
    return o.trim();
  }

  factory GeneratedMcq.fromJson(Map<String, dynamic> j) {
    final t = (j['type']?.toString() ?? 'question').toLowerCase().trim();
    final isPassage = t == 'passage' ||
        t == 'stimulus' ||
        t == 'uddipok' ||
        t.contains('উদ্দীপক');

    final rawOpts = (j['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    var ci = int.tryParse('${j['correctIndex']}') ?? 0;
    if (ci < 0 || ci > 3) ci = 0;

    while (rawOpts.length < 4) {
      rawOpts.add('Option ${rawOpts.length + 1}');
    }

    var text = (j['text'] ?? j['passage'] ?? j['stimulus'] ?? '').toString().trim();

    if (!isPassage) {
      text = _stripLeadingSerial(text);
    }

    final cleanOpts = isPassage
        ? const <String>[]
        : rawOpts.take(4).map((o) => _stripOptionPrefix(o)).toList();

    return GeneratedMcq(
      type: isPassage ? 'passage' : 'question',
      text: text,
      options: cleanOpts,
      correctIndex: isPassage ? 0 : ci,
      explanation: j['explanation']?.toString() ?? '',
    );
  }
}

class AiMcqService {
  static const String defaultApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  // In-memory / Firestore synced key pool
  static final List<String> _keyPool = [
    if (defaultApiKey.isNotEmpty) defaultApiKey,
  ];

  // Selected active model (editable by teacher from UI)
  static String selectedModel = 'gemini-2.0-flash';

  static const List<String> freeModels = <String>[
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

  static List<String> get keyPool => List.unmodifiable(_keyPool);
  static String get apiKey => _keyPool.isNotEmpty ? _keyPool.first : defaultApiKey;
  static bool get isConfigured => _keyPool.isNotEmpty || defaultApiKey.isNotEmpty;

  /// Load keys & model configuration from Firestore database
  static Future<void> syncFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('ai_config').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['keys'] is List) {
          final dbKeys = List<String>.from(data['keys']);
          for (var k in dbKeys) {
            final trimmed = k.trim();
            if (trimmed.isNotEmpty && !_keyPool.contains(trimmed)) {
              _keyPool.add(trimmed);
            }
          }
        }
        if (data['model'] is String && data['model'].toString().isNotEmpty) {
          selectedModel = data['model'];
        }
      }
    } catch (e) {
      debugPrint('Error syncing AI config from Firestore: $e');
    }
  }

  /// Save keys & model configuration to Firestore database
  static Future<void> _syncToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('settings').doc('ai_config').set({
        'keys': _keyPool,
        'model': selectedModel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving AI config to Firestore: $e');
    }
  }

  static Future<void> addApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isNotEmpty && !_keyPool.contains(trimmed)) {
      _keyPool.add(trimmed);
      await _syncToFirestore();
    }
  }

  static Future<void> removeApiKey(int index) async {
    if (index >= 0 && index < _keyPool.length) {
      _keyPool.removeAt(index);
      await _syncToFirestore();
    }
  }

  static Future<void> editApiKey(int index, String newKey) async {
    final trimmed = newKey.trim();
    if (index >= 0 && index < _keyPool.length && trimmed.isNotEmpty) {
      _keyPool[index] = trimmed;
      await _syncToFirestore();
    }
  }

  static Future<void> setModel(String model) async {
    selectedModel = model;
    await _syncToFirestore();
  }

  // Restored full expert prompts for Bangladeshi SSC/HSC exam extraction & generation
  static const _extractMcqPrompt = '''
You are an expert OCR-based MCQ extractor for Bangladeshi SSC and HSC examination papers.
Carefully examine the provided document or image:
1. Extract all existing MCQ questions and passages/উদ্দীপক in their correct reading order.
2. Treat any উদ্দীপক (passage, stimulus) as a separate first-class item with type 'passage'. Ensure it appears immediately before its related questions.
3. Extract exactly four options for each question, stripping any option prefixes like (ক), (খ), (গ), (ঘ) or (A), (B), (C), (D).
4. Identify the correct answer index (0-3) if an answer key is present; otherwise, determine the correct answer accurately.
5. Provide a short helpful explanation if possible.
Return ONLY a valid JSON array matching this structure without Markdown fences:
[
  {
    "type": "passage",
    "text": " উদ্দীপক text here..."
  },
  {
    "type": "question",
    "text": "Question text here...",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctIndex": 0,
    "explanation": "Explanation here..."
  }
]
''';

  static const _generateFromStudyPrompt = '''
You are an expert exam paper setter for Bangladeshi board examinations (SSC/HSC).
Create high-quality MCQs strictly based on the provided study material.
Ensure questions test conceptual understanding, memory, and application.
Return ONLY a valid JSON array matching this structure without Markdown fences:
[
  {
    "type": "question",
    "text": "Question text here...",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctIndex": 0,
    "explanation": "Explanation here..."
  }
]
''';

  static Future<List<GeneratedMcq>> fromText(
    String content, {
    bool extractOnly = false,
    int? questionCount,
  }) async {
    await syncFromFirestore();
    if (!isConfigured) throw Exception('No API key configured in the pool.');
    
    final prompt = _buildPrompt(extractOnly, questionCount);
    final body = {
      'contents': [
        {
          'parts': [
            {'text': '$prompt\n\nMATERIAL:\n$content'},
          ],
        },
      ],
      'generationConfig': {
        'temperature': extractOnly ? 0.1 : 0.3,
        'responseMimeType': 'application/json',
      },
    };
    return _requestWithPool(body);
  }

  static Future<List<GeneratedMcq>> fromImage({
    required Uint8List bytes,
    required String mimeType,
    bool extractOnly = false,
    int? questionCount,
  }) async {
    await syncFromFirestore();
    if (!isConfigured) throw Exception('No API key configured in the pool.');

    final prompt = _buildPrompt(extractOnly, questionCount);
    final b64 = base64Encode(bytes);
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': mimeType, 'data': b64},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': extractOnly ? 0.1 : 0.3,
        'responseMimeType': 'application/json',
      },
    };
    return _requestWithPool(body);
  }

  static Future<List<GeneratedMcq>> fromPdf(
    Uint8List bytes, {
    bool extractOnly = false,
    int? questionCount,
  }) async {
    await syncFromFirestore();
    if (!isConfigured) throw Exception('No API key configured in the pool.');

    final prompt = _buildPrompt(extractOnly, questionCount);
    final b64 = base64Encode(bytes);
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'application/pdf', 'data': b64},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': extractOnly ? 0.1 : 0.3,
        'responseMimeType': 'application/json',
      },
    };
    return _requestWithPool(body);
  }

  static String _buildPrompt(bool extractOnly, int? questionCount) {
    if (extractOnly) return _extractMcqPrompt;
    final countHint = questionCount != null
        ? '\nGenerate exactly $questionCount questions.\n'
        : '\nGenerate 5 to 10 questions if the material allows.\n';
    return '$_generateFromStudyPrompt$countHint';
  }

  static Future<List<GeneratedMcq>> _requestWithPool(Map<String, dynamic> body) async {
    final errors = <String>[];
    // Rotate through keys and models gracefully to avoid rate limits
    for (final key in _keyPool) {
      if (key.trim().isEmpty) continue;
      final modelsToTry = [selectedModel, ...freeModels.where((m) => m != selectedModel)];
      for (final model in modelsToTry) {
        try {
          final res = await http.post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ?? '';
            if (text.isNotEmpty) {
              final cleaned = text
                  .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
                  .replaceAll(RegExp(r'```\s*', multiLine: true), '')
                  .trim();
              final decoded = jsonDecode(cleaned);
              if (decoded is List) {
                return decoded
                    .whereType()
                    .map((e) => GeneratedMcq.fromJson(Map<String, dynamic>.from(e)))
                    .where((q) => q.text.trim().isNotEmpty)
                    .toList();
              }
            }
          } else {
            errors.add('Key [...${key.substring(key.length - 4)}] | Model $model -> Status ${res.statusCode}');
          }
        } catch (e) {
          errors.add('Key [...${key.substring(key.length - 4)}] | Model $model -> Error $e');
        }
      }
    }
    throw Exception('All AI keys and fallback models exhausted. Errors:\n${errors.join('\n')}');
  }
}
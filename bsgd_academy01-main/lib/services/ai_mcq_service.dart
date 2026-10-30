import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Helper to detect if a text contains Bengali Unicode characters
bool isBanglaText(String text) {
  return RegExp(r'[\u0980-\u09FF]').hasMatch(text);
}

/// Helper to convert English digits (1, 2, 3...) to Bangla digits (১, ২, ৩...)
String toBanglaDigits(dynamic number) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number.toString().split('').map((ch) {
    final n = int.tryParse(ch);
    return n != null ? bn[n] : ch;
  }).join('');
}

class GeneratedMcq {
  /// 'question' or 'passage' (উদ্দীপক)
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
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;

  // Updated to modern, fast, available models (eliminating deprecated 2.0/2.5 models)
  static const freeModels = <String>[
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

 /// OCR extraction prompt with strict instructions against serial numbers
static const _extractMcqPrompt = '''
You are an expert OCR-based MCQ extractor for Bangladeshi SSC and HSC examination papers, including Accounting, Finance, Business Studies, Economics, and other subjects.

Your task is to EXTRACT existing content from the supplied image or document. Do not generate, invent, paraphrase, or solve new questions unless needed to determine a missing correct answer.

Return ONLY a valid JSON array. Do not include Markdown fences, comments, introductory text, or trailing commas.

## CRITICAL RULE 1: NEVER SKIP AN উদ্দীপক / PASSAGE

A passage, stimulus, case study, scenario, data table, transaction description, or shared problem statement is a FIRST-CLASS OUTPUT ITEM, not part of a question.

Recognize passage headings and introductory instructions such as:
- উদ্দীপক
- উদ্দীপকটি পড়ে
- উদ্দীপকটি পড়ো
- নিচের উদ্দীপকটি পড়ে
- উদ্দীপক পড়ো এবং উত্তর দাও
- উদ্দীপক পড়ে ১৮ ও ১৯ নং প্রশ্নের উত্তর দাও
- উদ্দীপকটি পড়ে ২০ ও ২১ নং প্রশ্নের উত্তর দাও
- নিচের তথ্যের আলোকে উত্তর দাও
- অনুচ্ছেদটি পড়ে উত্তর দাও
- Passage
- Read the following passage
- Read the following stimulus
- Study the following information
- Based on the following information
- Answer questions ... using the following data

Also recognize a passage even when:
- The heading "উদ্দীপক" is missing, cropped, faint, or unreadable.
- It begins with a person's name, a business scenario, a transaction, a financial statement, or a numerical description.
- It appears inside a shaded box, bordered box, paragraph, or highlighted area.
- It contains accounting transactions, capital, assets, liabilities, drawings, purchases, sales, profit, wages, or other numerical information.
- Its related questions appear immediately below it or on a subsequent page.
- The passage is followed by multiple numbered questions.

IMPORTANT: A passage does NOT need to contain the word "উদ্দীপক" to qualify as a passage. Determine its role from its structure and context.

## CRITICAL RULE 2: USE A TWO-PASS EXTRACTION PROCESS

PASS 1 — SCAN AND IDENTIFY ALL CONTENT:
Read the entire supplied page or image in reading order. Identify every passage, question stem, option, instruction, number, and continuation. First create an internal sequence of the content. Do not produce the final JSON until this scan is complete.

PASS 2 — EXTRACT AND VALIDATE:
Convert the identified content into JSON items. Check that every visible passage and question is represented, in the correct order, before returning the result.

Never stop extracting after finding the first group of MCQs. Continue until the end of all supplied content.

## CRITICAL RULE 3: PASSAGE EXTRACTION AND PLACEMENT

For each distinct passage or stimulus:
1. Extract the complete passage exactly as printed, including its introductory instruction, names, amounts, dates, percentages, accounting figures, and other relevant details.
2. Preserve the original Bengali or English spelling, punctuation, numerals, and wording as accurately as possible.
3. Include the passage heading and its question-reference sentence when visible.
4. Do not shorten, summarize, explain, correct, or rewrite the passage.
5. Do not merge passage text into a question's "text" field.
6. Output the passage as a separate object with "type": "passage".
7. Place that object immediately before the first question that uses it.
8. If multiple consecutive questions use the same passage, output the passage only once before the first related question. Do not duplicate it before every question.
9. If a new passage appears later, create a new passage object at its correct reading-order position.
10. If a passage continues across lines, columns, or page boundaries, combine its visible parts in their original reading order when the supplied content supports that continuation.
11. Do not accidentally include the first question or its answer options inside the passage.
12. If only part of a passage is visible, extract all visible text. Never fabricate missing text.

If the passage says "উদ্দীপকটি পড়ে ১৮ ও ১৯ নং প্রশ্নের উত্তর দাও", preserve that sentence and extract the associated questions in order.

## CRITICAL RULE 4: QUESTION EXTRACTION

Extract every existing MCQ question visible in the supplied content.

For each question:
- Include the question number when visible, as part of the "text" field.
- Keep the question stem separate from its answer options.
- Extract exactly four options in their original reading order.
- Recognize option markers including (ক), (খ), (গ), (ঘ), ক), খ), গ), ঘ), ক., খ., গ., ঘ., (a), (b), (c), (d), A, B, C, D, i, ii, iii, and similar printed formats.
- Map the four answer options to options[0], options[1], options[2], and options[3] in their original order.
- Do not mistake Roman-numbered statements (i, ii, iii) within a question for the four answer options.
- For questions asking which combination is correct, preserve the statements and the combination choices exactly as printed.
- Preserve mathematical expressions, dates, monetary amounts, percentages, account names, and numerical values.
- Do not combine two separate questions into one.
- Do not omit a question merely because its passage is shared with another question.

## CRITICAL RULE 5: ACCOUNTING AND NUMERICAL PASSAGES

In Accounting and Business Studies papers, a paragraph describing a business or its transactions may be the stimulus for one or more questions.

For example, a passage such as:

"উদ্দীপকটি পড়ে এবং ১৮ ও ১৯ নং প্রশ্নের উত্তর দাও:
মি. জামাল নগদ ৫০,০০০ টাকা, ২০,০০০ টাকার আসবাবপত্র এবং ৫,০০০ টাকা আসবাবপত্র নিয়ে ব্যবসায় আরম্ভ করেন। সঞ্চিত বছরের কারবারের মুনাফা অর্জিত হয় ৩০,০০০ টাকা।"

must be extracted as one separate passage object if those words are visible in the source. Do not discard it because it is descriptive text rather than a question.

This example is illustrative only. Extract the actual supplied content, not this example.

## CRITICAL RULE 6: CORRECT ANSWERS

Set "correctIndex" to the zero-based index of the correct option:
- 0 = first option
- 1 = second option
- 2 = third option
- 3 = fourth option

Use the following priority:
1. If an answer key or an explicitly marked correct answer is provided, follow it.
2. Otherwise, determine the answer using reliable subject knowledge and calculations.
3. For accounting questions, carefully verify the accounting equation, transaction effects, calculations, and terminology before selecting an answer.
4. Never choose an answer randomly.
5. If the question or options are too unclear to determine the correct answer reliably, use 0 as a fallback and state briefly in "explanation" that the answer could not be verified from the visible content. Do not invent certainty.

Provide a short explanation in the language of the question. The explanation must justify the selected answer.

Passage objects do not require "options", "correctIndex", or "explanation".

## CRITICAL RULE 7: OCR AND VISUAL READING

Use the actual visual layout of the supplied image or document, not OCR text order alone.

- Read from top to bottom and left to right, respecting the printed column layout.
- Inspect shaded boxes, borders, headings, and paragraph boundaries.
- Do not ignore bold text or text inside a highlighted box.
- Distinguish passage paragraphs from question stems and options.
- Preserve Bengali numerals (০১২৩৪৫৬৭৮৯) as printed.
- Do not silently replace unreadable text with guessed words or amounts.
- If a character is genuinely unreadable, preserve the readable portion and mark only the uncertain portion as [অস্পষ্ট] when necessary.
- Do not use [অস্পষ্ট] merely because the wording is unfamiliar.

## CRITICAL RULE 8: FINAL VALIDATION BEFORE OUTPUT

Before returning JSON, verify all of the following internally:

1. Every visible passage or stimulus has been extracted.
2. Every passage is a separate object with "type": "passage".
3. Each passage appears before the first question that depends on it.
4. The passage includes its full visible introductory sentence and descriptive content.
5. No passage has been merged into a question.
6. Every visible MCQ has been extracted.
7. Every question has exactly four options.
8. Options remain in the original printed order.
9. Every question has a valid correctIndex between 0 and 3.
10. All objects appear in the original reading order.
11. No content has been invented.
12. The final output is syntactically valid JSON.

If a passage is visible but its related questions are not visible, still extract the passage. If questions are visible but their referenced passage is not present in the supplied content, extract the questions without inventing the missing passage.

## REQUIRED OUTPUT SCHEMA

Return only a JSON array using these object formats:

Passage:
{
  "type": "passage",
  "text": "Full visible passage exactly as printed"
}

Question:
{
  "type": "question",
  "text": "Question number and stem only",
  "options": [
    "First option",
    "Second option",
    "Third option",
    "Fourth option"
  ],
  "correctIndex": 0,
  "explanation": "Short explanation for the correct answer"
}

The array may contain any number of passage and question objects, in their original reading order. Never return a passage as a question. Never omit a visible passage just because the MCQs can be answered without it.''';

  /// Generation prompt for notes
static const _generateFromStudyPrompt = '''
You are an expert exam paper setter for Bangladeshi board examinations (HSC, SSC, Honours, Degree).
Create high-quality MCQs strictly based on the provided study material.

Return ONLY a valid JSON array without Markdown fences.

1. STRICTLY NO SERIAL NUMBERS: Do not start questions with "১.", "1.", "প্রশ্ন ১:". Start directly with the question text.
2. PURE OPTIONS: Do not include option labels like "(ক)", "(A)", "A." in options array.
3. MULTI-STATEMENT MCQS: Use `i.`, `ii.`, `iii.` inside the "text" field separated by `\n`.
4. PRESERVE NUMERALS: Keep Bangla numbers in Bangla and English numbers in English. Do not modify numbers in formulas or amounts.
5. STIMULUS / PASSAGE: Insert type "passage" before related questions if applicable.

JSON format:
[
  {
    "type": "question",
    "text": "দুতরফা দাখিলা পদ্ধতির মূল ভিত্তি কোনটি?",
    "options": ["হিসাব সমীকরণ", "খতিয়ান উদ্বৃত্ত", "রেওয়ামিল", "আর্থিক বিবরণী"],
    "correctIndex": 0,
    "explanation": "দুতরফা দাখিলা পদ্ধতির মূল ভিত্তি হিসাব সমীকরণ (A = L + OE)।"
  }
]
''';

  static Future<List<GeneratedMcq>> fromText(
    String content, {
    bool extractOnly = false,
    int? questionCount,
  }) async {
    _ensureKey();
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
    return _requestWithFallback(body);
  }

  static Future<List<GeneratedMcq>> fromImage({
    required Uint8List bytes,
    required String mimeType,
    bool extractOnly = false,
    int? questionCount,
  }) async {
    _ensureKey();
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
    return _requestWithFallback(body);
  }

  static Future<List<GeneratedMcq>> fromPdf(
    Uint8List bytes, {
    bool extractOnly = false,
    int? questionCount,
  }) async {
    _ensureKey();
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
    return _requestWithFallback(body);
  }

  static String _buildPrompt(bool extractOnly, int? questionCount) {
    if (extractOnly) return _extractMcqPrompt;
    final countHint = questionCount != null
        ? '\nGenerate exactly $questionCount questions.\n'
        : '\nGenerate 5 to 10 questions if the material allows.\n';
    return '$_generateFromStudyPrompt$countHint';
  }

  static void _ensureKey() {
    if (!isConfigured) {
      throw Exception(
        'GEMINI_API_KEY missing. Run with:\n'
        'flutter run ... --dart-define=GEMINI_API_KEY=your_key',
      );
    }
  }

  static Future<List<GeneratedMcq>> _requestWithFallback(
    Map<String, dynamic> body,
  ) async {
    final errors = <String>[];
    // Try primary high-speed model first to prevent long waiting times
    for (final model in freeModels) {
      try {
        return await _request(model, body);
      } catch (e) {
        final msg = e.toString();
        errors.add('$model → $msg');
        final lower = msg.toLowerCase();
        if (lower.contains('403') ||
            lower.contains('401') ||
            lower.contains('api_key') ||
            lower.contains('quota') ||
            lower.contains('resource_exhausted')) {
          rethrow;
        }
      }
    }
    throw Exception('All AI models failed:\n${errors.join('\n')}');
  }

  static Future<List<GeneratedMcq>> _request(
    String model,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey',
    );

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15), // Reduced timeout for speed/responsiveness
          onTimeout: () {
            throw Exception('Timeout (15s) on model $model');
          },
        );

    if (res.statusCode != 200) {
      throw Exception('Gemini ${res.statusCode} ($model): ${res.body}');
    }

    final decodedBody = jsonDecode(res.body);
    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response body from $model');
    }

    final text = decodedBody['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ?? '';

    if (text.isEmpty) {
      throw Exception('Empty response from $model');
    }

    final cleaned = text
        .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*', multiLine: true), '')
        .trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      throw Exception('AI ($model) returned invalid JSON');
    }

    if (decoded is! List) {
      throw Exception('AI ($model) did not return a JSON list');
    }

    return decoded
        .whereType<Map>()
        .map((e) => GeneratedMcq.fromJson(Map<String, dynamic>.from(e)))
        .where((q) => q.text.trim().isNotEmpty)
        .toList();
  }
}
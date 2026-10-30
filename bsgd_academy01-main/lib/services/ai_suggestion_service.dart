import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CqItem {
  final String label; // ক, খ, গ, ঘ
  final String question;
  final String shortAnswer;
  final String detailedAnswer;

  CqItem({
    required this.label,
    required this.question,
    required this.shortAnswer,
    required this.detailedAnswer,
  });

  factory CqItem.fromJson(Map<String, dynamic> j) {
    return CqItem(
      label: j['label']?.toString() ?? '',
      question: j['question']?.toString() ?? '',
      shortAnswer: j['shortAnswer']?.toString() ?? '',
      detailedAnswer: j['detailedAnswer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'question': question,
        'shortAnswer': shortAnswer,
        'detailedAnswer': detailedAnswer,
      };
}

class CqSuggestionData {
  final String title;
  final String passage;
  final List<CqItem> items;

  CqSuggestionData({
    required this.title,
    required this.passage,
    required this.items,
  });

  factory CqSuggestionData.fromJson(Map<String, dynamic> j) {
    final list = (j['items'] as List?)
            ?.map((e) => CqItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return CqSuggestionData(
      title: j['title']?.toString() ?? 'সৃজনশীল প্রশ্ন ও উত্তর',
      passage: j['passage']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'passage': passage,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class ShortSuggestionData {
  final String title;
  final String subject;
  final List<String> keyPoints;
  final List<Map<String, String>> shortQuestions;

  ShortSuggestionData({
    required this.title,
    required this.subject,
    required this.keyPoints,
    required this.shortQuestions,
  });

  factory ShortSuggestionData.fromJson(Map<String, dynamic> j) {
    final points =
        (j['keyPoints'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final sq = (j['shortQuestions'] as List?)?.map((e) {
          final m = Map<String, dynamic>.from(e);
          return {
            'q': m['q']?.toString() ?? '',
            'a': m['a']?.toString() ?? '',
          };
        }).toList() ??
        [];
    return ShortSuggestionData(
      title: j['title']?.toString() ?? 'সংক্ষিপ্ত সাজেশন',
      subject: j['subject']?.toString() ?? 'সাধারণ',
      keyPoints: points,
      shortQuestions: sq,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'keyPoints': keyPoints,
        'shortQuestions': shortQuestions,
      };
}

class AiSuggestionService {
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static bool get isConfigured => apiKey.isNotEmpty;

  // Real, active Gemini models in order of stability and quota
  static const freeModels = <String>[
    'gemini-3.8-flash',
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-3-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

  static const _cqPrompt = r'''
You are an expert Bangladeshi academic teacher, board-exam answer writer, and document extraction specialist for SSC and HSC examinations.

Your task is to extract the complete Creative Question (CQ / সৃজনশীল প্রশ্ন) from the provided image, scanned page, PDF, or document.

The source may be in Bangla, English, or a mixture of both. It may contain printed text, tables, mathematical expressions, accounting data, diagrams, or a boxed/shaded stimulus.

CRITICAL OBJECTIVE:
Extract the original question faithfully, especially the complete উদ্দীপক (stimulus/passage), and provide accurate, textbook-aligned answers for each visible question part.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. FIRST PASS: INSPECT THE ENTIRE SOURCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before generating the output, inspect the entire visible page or document.

Identify:
- The subject, chapter, topic, or question heading, if available.
- The complete উদ্দীপক (stimulus/passage).
- Every visible question part: ক, খ, গ, ঘ.
- Any tables, figures, numerical values, symbols, units, or conditions required to understand or answer the questions.

Do not begin writing the JSON until you have checked the whole source.

If multiple CQ questions are visible, determine whether the application expects one CQ per extraction. For this schema, extract the primary complete CQ. If multiple CQs are present and no single primary CQ is identifiable, do not silently combine them into one; select the first complete CQ in reading order.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. CRITICAL: EXTRACT THE COMPLETE উদ্দীপক
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The উদ্দীপক is mandatory whenever it is visible in the source.

Look for:
- The word "উদ্দীপক", "উদ্দীপকটি", or similar Bangla wording.
- Phrases such as "নিচের উদ্দীপকটি পড়ে প্রশ্নগুলোর উত্তর দাও".
- "Read the following stimulus/passage/scenario".
- A paragraph, story, real-life situation, case study, data table, or accounting/business scenario placed before the four question parts.
- Text inside a box, shaded region, border, diagram, or table that provides context for the questions.

Important:
- Do not assume the stimulus begins with the literal word "উদ্দীপক".
- Do not omit a stimulus simply because it is embedded in a table, image, diagram, or paragraph.
- Preserve every visible sentence, number, name, date, amount, percentage, unit, and relevant symbol.
- Preserve the stimulus in its original reading order.
- Do not merge the stimulus with question ক.
- Do not replace the original stimulus with a summary.
- Do not shorten it, paraphrase it, or rewrite it in more polished language.
- Do not invent text that is missing, cropped, or unreadable.
- If the source visibly has no stimulus, return an empty string for "passage". Never fabricate one.

If part of the stimulus is unreadable, extract the readable text and mark only the uncertain portion as [অস্পষ্ট] or [unreadable], choosing the language that best matches the source.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. EXTRACT ALL FOUR QUESTION PARTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Extract each visible part separately and in its original order:

ক — Knowledge / জ্ঞানমূলক
খ — Comprehension / অনুধাবনমূলক
গ — Application / প্রয়োগমূলক
ঘ — Higher-order thinking / উচ্চতর দক্ষতামূলক

For each part:
- Copy the complete question text.
- Preserve its original Bangla or English wording.
- Preserve subject terminology, names, values, units, and conditions.
- Do not include the answer in the "question" field.
- Do not convert a question into a statement.
- Do not omit sub-questions or clauses.
- Do not create a missing question part.
- Do not assume that the four parts are all visible. If a part is absent or unreadable, represent it according to the schema rules below.

If a question label is printed as (ক), ক), ক., (a), or a similar form, normalize only the label to the appropriate Bangla label: ক, খ, গ, or ঘ. Preserve the question text itself.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4. WRITE THE SHORT ANSWER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The "shortAnswer" field must contain a direct, accurate, exam-focused answer.

Requirements:
- Normally 1–2 sentences.
- Answer the exact question being asked.
- Include the central definition, fact, formula, reason, or conclusion.
- Use correct academic terminology.
- Use Bangla when the question is in Bangla; use English when the question is in English.
- For calculation-based questions, include the essential result and unit.
- For questions requiring a distinction, include the key difference.
- Avoid unnecessary introductions, repetition, and unrelated facts.

Do not make the short answer vague merely to keep it short.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. WRITE THE DETAILED ANSWER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The "detailedAnswer" field must be a high-quality, textbook-aligned, board-exam-standard answer.

Adapt the structure to the subject and question.

For definition or knowledge questions:
- State the correct definition or fact.
- Add a necessary explanation or example if useful.

For comprehension questions:
- Explain the relevant concept clearly.
- Connect the explanation to the question's context.
- Show why the stated concept or result is correct.

For application questions:
- Identify the relevant concept, rule, formula, or principle.
- Apply it to the supplied উদ্দীপক.
- Show the necessary reasoning or calculation.
- Explain the result and its relevance to the question.

For higher-order questions:
- Analyze the relevant facts and relationships.
- Apply appropriate concepts to the stimulus.
- Compare, justify, evaluate, or draw a conclusion as requested.
- Support the conclusion with subject-specific reasoning.

Subject-specific requirements:
- Mathematics and science: show the formula, substitution, steps, final result, and units where applicable.
- Accounting and finance: show relevant calculations, classifications, debit/credit treatment, journal entries, statements, or formulas when required by the question.
- Business studies and economics: explain the applicable principles and connect them to the given situation.
- Humanities and social sciences: explain concepts accurately, support reasoning with relevant context, and avoid unsupported claims.
- Bangla and English: follow the question's required form, literary context, grammar, or writing conventions.

Answer quality rules:
- Use clear paragraphs and numbered steps where appropriate.
- Include equations or calculations when they help demonstrate the solution.
- Explain the reasoning rather than merely giving the final result.
- Keep the answer proportional to the question's marks and difficulty.
- Avoid filler, repetition, fabricated quotations, fake citations, and unsupported textbook references.
- Do not claim that an answer is taken from a specific textbook or page unless that source is actually provided and verified.
- Do not force every answer into the same template.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6. SOURCE ACCURACY AND UNCERTAINTY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Distinguish between:
A. Source extraction: what the document actually says.
B. Answer generation: the academic answer to the extracted question.

Never silently rewrite source text to correct a typo or improve its style.

For answers:
- Use established subject knowledge to solve the question.
- Use the supplied stimulus and all relevant values.
- Do not invent missing facts, numerical values, assumptions, or conditions.
- If the question cannot be answered reliably because essential information is missing or unreadable, explain the limitation briefly in the answer rather than inventing a result.
- Check all arithmetic, formulas, units, and logical conclusions before returning the output.
- Ensure the detailed answer agrees with the short answer.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7. OUTPUT SCHEMA — STRICT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Return exactly one valid JSON object with this structure:

{
  "title": "Topic or Chapter Title",
  "passage": "Complete original stimulus text",
  "items": [
    {
      "label": "ক",
      "question": "Original question text",
      "shortAnswer": "Direct, accurate answer",
      "detailedAnswer": "Comprehensive, textbook-aligned explanation"
    },
    {
      "label": "খ",
      "question": "Original question text",
      "shortAnswer": "Direct, accurate answer",
      "detailedAnswer": "Comprehensive, textbook-aligned explanation"
    },
    {
      "label": "গ",
      "question": "Original question text",
      "shortAnswer": "Direct, accurate answer",
      "detailedAnswer": "Comprehensive, textbook-aligned explanation"
    },
    {
      "label": "ঘ",
      "question": "Original question text",
      "shortAnswer": "Direct, accurate answer",
      "detailedAnswer": "Comprehensive, textbook-aligned explanation"
    }
  ]
}

Schema rules:
- "title" must be a string. Use the printed topic/chapter title if available. Otherwise infer a concise title from the visible content without inventing a specific chapter name.
- "passage" must be a string containing the full visible stimulus, or "" if none is visible.
- "items" must be a JSON array containing only question parts that are actually visible or reliably recoverable.
- Preserve the original order of the visible question parts.
- Each item must contain exactly these keys: "label", "question", "shortAnswer", and "detailedAnswer".
- "label" must be one of "ক", "খ", "গ", or "ঘ".
- Do not create an absent question part just to force four items.
- If the application requires exactly four items, use an empty string for the question and answers of a genuinely missing part, while retaining its correct label. Never invent missing question text.
- All JSON keys and string values must use double quotes.
- Escape internal quotation marks, backslashes, and line breaks correctly.
- Do not include trailing commas.
- Do not include Markdown fences, comments, introductory text, or any text outside the JSON object.
- Do not add fields that are not in the schema.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
8. FINAL VALIDATION BEFORE OUTPUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before returning the JSON, silently verify:

1. Did you inspect the entire provided source?
2. Did you capture the complete visible উদ্দীপক?
3. Did you accidentally omit text inside a box, table, diagram, or shaded area?
4. Are the question parts in the correct reading order?
5. Is each question copied faithfully?
6. Does each included item have a short answer and a detailed answer?
7. Are the answers relevant to the exact question and stimulus?
8. Are calculations and subject-specific reasoning correct?
9. Is the JSON syntactically valid and compliant with the schema?
10. Is there any invented or unsupported source text?

Fix any issue before returning the final JSON.

Return ONLY the JSON object.
''';
static const _shortPrompt = r'''
You are an expert academic curriculum specialist, experienced teacher, and exam-preparation guide for Bangladeshi SSC, HSC, Honors, and Degree examinations.

Analyze the provided study material and create a concise, high-yield suggestion sheet for exam preparation and quick revision.

Your goal is to help students revise the most important concepts, definitions, formulas, rules, facts, and likely question areas efficiently.

The source may contain Bangla or English text, textbook pages, lecture notes, class handouts, tables, formulas, worked examples, or scanned documents.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. UNDERSTAND THE SOURCE FIRST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Inspect the entire provided material before preparing the suggestion sheet.

Identify:
- Subject and topic/chapter.
- Main concepts and learning objectives.
- Definitions, principles, rules, formulas, dates, names, classifications, and important facts.
- Repeated themes, worked examples, and concepts emphasized by the source.
- Important relationships, differences, processes, and applications.
- Any questions or examples explicitly provided in the source.

Use the supplied material as the primary source of truth.

Do not claim to know the official board examination questions, confidential question papers, or guaranteed future questions.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. SELECT HIGH-YIELD KEY POINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create a concise list of the most useful revision points.

Prioritize:
1. Core concepts needed to understand the chapter.
2. Essential definitions and terminology.
3. Important formulas, rules, principles, and conditions.
4. Distinctions and comparisons students frequently need to explain.
5. Processes, steps, classifications, and cause-and-effect relationships.
6. Important examples, applications, and calculations found in the material.
7. Supporting details needed to answer examination questions correctly.

Rules:
- Every point must communicate a meaningful fact or learning objective.
- Keep each point concise, specific, and easy to revise.
- Preserve important Bangla or English terminology from the source.
- Include formulas with variable meanings when needed.
- Avoid duplicate points, vague advice, motivational text, and unnecessary introductions.
- Do not turn every paragraph into a separate point.
- Do not omit essential conditions, units, exceptions, or definitions merely to shorten the sheet.
- Do not invent facts or attribute unsupported content to the source.

Choose the number of points based on the amount and complexity of the supplied material. Prefer a focused list over an arbitrary large number.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. CREATE IMPORTANT SHORT QUESTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generate concise, exam-relevant questions based primarily on the supplied material.

Include a balanced selection where appropriate:
- Definitions and factual recall.
- Understanding and explanation.
- Differences and comparisons.
- Reasons, causes, effects, and relationships.
- Formula, rule, or concept applications.
- Short calculations or subject-specific problems.
- Practical examples or interpretations of the material.

Each question must:
- Be clear and specific.
- Test a meaningful concept.
- Be answerable from the source or established subject knowledge.
- Avoid ambiguity and unnecessary complexity.
- Be distinct from the other questions.
- Use the appropriate academic terminology and language.
- Be suitable for the stated education level and subject.

Do not produce multiple questions that test the same fact with only minor wording changes.

Do not invent official board questions, years, exam references, marks, or predictions.

If the source includes explicit questions, you may use their concepts, but do not misrepresent newly generated questions as exact questions from an official examination.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4. WRITE ACCURATE SHORT ANSWERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For every question, provide a direct and academically accurate answer.

Requirements:
- Answer the question directly in the first sentence where possible.
- Include the essential definition, fact, formula, reason, or result.
- Keep the answer concise but complete.
- Use the same language as the question unless the source or question requires otherwise.
- Include units and essential calculation steps where appropriate.
- Use correct formulas, symbols, terminology, and spelling.
- Ensure the answer is consistent with the key points.
- Avoid filler, circular explanations, unsupported claims, and vague wording.

If a reliable answer requires information not supplied in the material, use established subject knowledge carefully. Do not falsely imply that the information was explicitly stated in the source.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. ADAPT TO THE SUBJECT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For mathematics and science:
- Include important formulas, principles, units, and problem-solving rules.
- Make calculation questions solvable with the supplied data.
- Check numerical results and units.

For accounting and finance:
- Include relevant accounting concepts, classifications, rules, formulas, and calculations.
- Preserve debit/credit distinctions and the correct treatment of transactions.
- Include journal entries or statement formats only when relevant.

For business studies and economics:
- Focus on definitions, principles, classifications, relationships, applications, and practical examples.

For humanities and social sciences:
- Focus on concepts, causes, effects, differences, significant facts, processes, and supported explanations.

For Bangla and English:
- Focus on literary concepts, grammar, vocabulary, writing conventions, and interpretation appropriate to the material.

Do not force subject-specific content into a generic format when it does not apply.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6. LANGUAGE AND ACADEMIC LEVEL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Preserve the source's language and terminology.
- If the material is primarily Bangla, use clear academic Bangla.
- If it is primarily English, use clear academic English.
- Keep answers appropriate to the specified level: SSC, HSC, Honors, or Degree.
- If the level is not stated, infer it cautiously from the material.
- Explain necessary technical terms without making the sheet unnecessarily long.
- Do not fabricate textbook quotations, page numbers, citations, or official syllabus claims.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7. OUTPUT FORMAT — STRICT JSON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Return exactly one valid JSON object:

{
  "title": "Topic or Chapter Name",
  "subject": "Subject Name",
  "keyPoints": [
    "Important revision point 1",
    "Important revision point 2"
  ],
  "shortQuestions": [
    {
      "q": "Important exam-relevant question?",
      "a": "Direct, accurate, concise answer."
    }
  ]
}

Schema rules:
- "title" must be a string.
- "subject" must be a string. Use the source's subject if identifiable; otherwise use "Not specified".
- "keyPoints" must be an array of strings.
- "shortQuestions" must be an array of objects.
- Every question object must contain exactly "q" and "a".
- Both "q" and "a" must be non-empty strings.
- Use only the keys shown in the schema.
- Do not return null in place of a required string or array.
- Do not include Markdown, backticks, comments, or explanatory text outside the JSON object.
- Escape quotation marks, backslashes, and line breaks correctly.
- Do not use trailing commas.
- Keep all content inside the JSON object.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
8. FINAL QUALITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before returning the output, silently check:

1. Did you inspect all supplied material?
2. Are the key points genuinely important and non-repetitive?
3. Are the questions relevant to the actual subject and topic?
4. Does every question have a correct and useful answer?
5. Are formulas, calculations, and terminology correct?
6. Did you avoid unsupported claims about official exams?
7. Is the output concise enough for revision?
8. Does the JSON match the exact schema and parse correctly?
9. Did you avoid inventing details about the source?

Correct any issues and return ONLY the JSON object.
''';
  static Future<CqSuggestionData> generateCq({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final text = await _makeRequest(
      prompt: _cqPrompt,
      bytes: bytes,
      mimeType: mimeType,
    );
    final decoded = _cleanAndDecode(text);
    return CqSuggestionData.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<ShortSuggestionData> generateShort({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final text = await _makeRequest(
      prompt: _shortPrompt,
      bytes: bytes,
      mimeType: mimeType,
    );
    final decoded = _cleanAndDecode(text);
    return ShortSuggestionData.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<String> _makeRequest({
    required String prompt,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'GEMINI_API_KEY is missing. Run with:\n'
        'flutter run ... --dart-define=GEMINI_API_KEY=your_key',
      );
    }

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
        'temperature': 0.2,
      },
    };

    final List<String> errors = [];

    for (final model in freeModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final out = parts[0]['text']?.toString() ?? '';
              if (out.trim().isNotEmpty) return out;
            }
          }
          errors.add('$model: Empty candidate response.');
        } else {
          // Log exact API rejection response
          final errMsg = '$model (${res.statusCode}): ${res.body}';
          debugPrint(errMsg);
          errors.add(errMsg);

          // Stop early on invalid API keys or quota exhaustion
          if (res.statusCode == 400 && res.body.contains('API_KEY_INVALID')) {
            throw Exception('Gemini API key is invalid.');
          }
          if (res.statusCode == 429) {
            throw Exception('Gemini free-tier quota exceeded. Try again in a minute.');
          }
        }
      } catch (e) {
        errors.add('$model: $e');
        continue;
      }
    }

    throw Exception('All AI models failed:\n${errors.take(3).join('\n')}');
  }

  static dynamic _cleanAndDecode(String raw) {
    // Strip markdown codeblocks if Gemini added them
    var cleaned = raw
        .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*', multiLine: true), '')
        .trim();

    // Find bounding JSON object brackets if any conversational text wraps it
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    try {
      return jsonDecode(cleaned);
    } catch (e) {
      throw Exception('AI returned malformed JSON: $e\nOutput was: $raw');
    }
  }
}
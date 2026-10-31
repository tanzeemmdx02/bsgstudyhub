import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GithubReleaseService {
  static String owner = 'tanzeemmdx02';
  static String repo = 'bsgstudyhubvideo';
  static String token = 'YOUR_GITHUB_TOKEN_HERE'; // Classic token starting with ghp_
  static String defaultTag = 'v1.0.0-videos';

  static String cleanOwnerName(String raw) {
    var s = raw.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) {
      final uri = Uri.tryParse(s);
      if (uri != null && uri.pathSegments.isNotEmpty) return uri.pathSegments[0];
    }
    return s.replaceAll('/', '').trim();
  }

  static String cleanRepoName(String raw) {
    var s = raw.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) {
      final uri = Uri.tryParse(s);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments.length >= 2) return uri.pathSegments[1];
        return uri.pathSegments[0];
      }
    }
    if (s.contains('/')) {
      final parts = s.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) return parts[1];
    }
    return s.replaceAll('/', '').trim();
  }

  static Future<void> syncConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('github').get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        if (d['owner'] != null && d['owner'].toString().isNotEmpty) owner = d['owner'];
        if (d['repo'] != null && d['repo'].toString().isNotEmpty) repo = d['repo'];
        if (d['token'] != null && d['token'].toString().isNotEmpty) token = d['token'];
        if (d['tag'] != null && d['tag'].toString().isNotEmpty) defaultTag = d['tag'];
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _getOrCreateRelease(String tag) async {
    final cleanOwner = cleanOwnerName(owner);
    final cleanRepo = cleanRepoName(repo);

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'BSGD-StudyHub-App',
    };

    final getRes = await http.get(
      Uri.parse('https://api.github.com/repos/$cleanOwner/$cleanRepo/releases/tags/$tag'),
      headers: headers,
    );

    if (getRes.statusCode == 200) {
      return jsonDecode(getRes.body) as Map<String, dynamic>;
    }

    // Create release if it does not exist
    final createRes = await http.post(
      Uri.parse('https://api.github.com/repos/$cleanOwner/$cleanRepo/releases'),
      headers: headers,
      body: jsonEncode({
        'tag_name': tag,
        'name': 'Course Videos ($tag)',
        'body': 'Automated video storage release for BSGD Academy courses.',
        'draft': false,
        'prerelease': false,
      }),
    );

    if (createRes.statusCode == 201) {
      return jsonDecode(createRes.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to create release (${createRes.statusCode}): ${createRes.body}');
  }

  /// Uploads video bytes directly from device or browser
  static Future<String> uploadVideoAsset({
    required Uint8List fileBytes,
    required String fileName,
    String? tag,
  }) async {
    await syncConfig();

    if (token.isEmpty || token == 'YOUR_GITHUB_TOKEN_HERE') {
      throw Exception('GitHub token missing. Set it in github_release_service.dart or Firestore settings/github');
    }

    final targetTag = tag ?? defaultTag;
    final release = await _getOrCreateRelease(targetTag);

    final cleanFileName = '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

    String uploadUrlTemplate = release['upload_url'] as String;
    final baseUploadUrl = uploadUrlTemplate.split('{').first;
    String targetUrl = '$baseUploadUrl?name=$cleanFileName';

    // On Web browsers, route through proxy to bypass CORS preflight blocking
    if (kIsWeb) {
      targetUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
    }

    final uploadRes = await http.post(
      Uri.parse(targetUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'video/mp4',
        'User-Agent': 'BSGD-StudyHub-App',
      },
      body: fileBytes,
    );

    if (uploadRes.statusCode == 201) {
      final data = jsonDecode(uploadRes.body) as Map<String, dynamic>;
      return data['browser_download_url'] as String;
    } else {
      throw Exception('Upload failed (${uploadRes.statusCode}): ${uploadRes.body}');
    }
  }
}
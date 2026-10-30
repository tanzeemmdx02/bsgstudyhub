import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Conditional import – prevents dart:html from crashing Android/iOS builds
import 'file_download_stub.if_not_web.dart'
    if (dart.library.html) 'file_download_web.dart' as platform;

/// Download raw bytes as a file (web: triggers browser download; mobile: no-op stub).
Future<void> downloadFile(
  Uint8List bytes,
  String fileName,
  String mime,
) async {
  platform.downloadFile(bytes, fileName, mime);
}

/// Open bytes in a new browser tab (web only).
Future<void> viewFile(Uint8List bytes, String mime) async {
  platform.viewFile(bytes, mime);
}

Future<void> downloadBase64File({
  required BuildContext context,
  required String base64Data,
  required String fileName,
  required String type,
}) async {
  try {
    final bytes = base64Decode(base64Data);
    final mime = type == 'pdf'
        ? 'application/pdf'
        : (fileName.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');

    if (kIsWeb) {
      await downloadFile(bytes, fileName, mime);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File: $fileName (${bytes.length} bytes)')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }
}

/// Open image/PDF in a new browser tab (view without forcing download)
Future<void> viewBase64File({
  required BuildContext context,
  required String base64Data,
  required String type,
  required String fileName,
}) async {
  try {
    final bytes = base64Decode(base64Data);
    final mime = type == 'pdf'
        ? 'application/pdf'
        : (fileName.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');

    if (kIsWeb) {
      await viewFile(bytes, mime);
    } else {
      if (type == 'pdf') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Use Download to open PDF on mobile.'),
            ),
          );
        }
      } else {
        final img = base64Decode(base64Data);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) =>
                Dialog(child: InteractiveViewer(child: Image.memory(img))),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('View failed: $e')));
    }
  }
}

Uint8List? decodeImageBase64(String? b64, String? type) {
  if (b64 == null || b64.isEmpty || type == 'pdf') return null;
  try {
    final bytes = base64Decode(b64);
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return null;
    }
    return bytes;
  } catch (_) {
    return null;
  }
}
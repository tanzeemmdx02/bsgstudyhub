import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

// Conditional import – prevents dart:html from crashing Android/iOS builds
import 'file_download_stub.if_not_web.dart'
    if (dart.library.html) 'file_download_web.dart' as platform;

/// Download raw bytes as a file (web: browser download; mobile: save to Downloads + native share/save).
Future<void> downloadFile(
  Uint8List bytes,
  String fileName,
  String mime,
) async {
  if (kIsWeb) {
    platform.downloadFile(bytes, fileName, mime);
  } else {
    try {
      if (io.Platform.isAndroid) {
        final downloadDir = io.Directory('/storage/emulated/0/Download');
        if (downloadDir.existsSync()) {
          final file = io.File('${downloadDir.path}/$fileName');
          await file.writeAsBytes(bytes);
        }
      }
    } catch (_) {}

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

/// Open bytes in a new browser tab (web) or native PDF viewer (mobile).
Future<void> viewFile(
  Uint8List bytes,
  String mime, {
  String fileName = 'document.pdf',
}) async {
  if (kIsWeb) {
    platform.viewFile(bytes, mime);
  } else {
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: fileName,
    );
  }
}

/// Download base64 encoded document (used across video & suggestion screens)
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading "$fileName"...')),
        );
      }
    } else {
      // Android APK Logic
      bool savedDirectly = false;
      try {
        if (io.Platform.isAndroid) {
          final downloadDir = io.Directory('/storage/emulated/0/Download');
          if (downloadDir.existsSync()) {
            final file = io.File('${downloadDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            savedDirectly = true;
          }
        }
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedDirectly
                  ? 'Saved to Downloads: $fileName'
                  : 'Saving "$fileName"...',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Open Android native save/share sheet
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

/// Open image/PDF in a new browser tab (web) or in-app viewer (mobile)
Future<void> viewBase64File({
  required BuildContext context,
  required String base64Data,
  required String type,
  required String fileName,
}) async {
  try {
    final bytes = base64Decode(base64Data);
    final isPdf = type == 'pdf' ||
        fileName.toLowerCase().endsWith('.pdf') ||
        (bytes.length >= 4 &&
            bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46); // F

    final mime = isPdf
        ? 'application/pdf'
        : (fileName.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg');

    if (kIsWeb) {
      await viewFile(bytes, mime);
    } else {
      if (isPdf) {
        // Launches native Android full interactive PDF previewer
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black87,
              insetPadding: const EdgeInsets.all(8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('View failed: $e')),
      );
    }
  }
}

/// Helper to decode image bytes from base64 safely
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
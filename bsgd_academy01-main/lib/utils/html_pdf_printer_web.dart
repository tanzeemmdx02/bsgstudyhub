// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// Robust web PDF export:
/// 1. Renders HTML in a hidden iframe (waits for Google Fonts / Bengali).
/// 2. Triggers the browser print dialog so the user can choose "Save as PDF".
Future<void> printOrExportHtml(String htmlContent, String title) async {
  final bodyInner = htmlContent.contains('<body')
      ? _extractBody(htmlContent)
      : htmlContent;

  final enhancedHtml = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>${_escape(title)}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    @page { size: A4 portrait; margin: 18mm; }
    * { box-sizing: border-box; }
    body {
      font-family: 'Noto Sans Bengali', 'Noto Sans', Arial, sans-serif;
      color: #111;
      line-height: 1.65;
      font-size: 14px;
      background: #fff;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #1a365d;
      padding-bottom: 12px;
      margin-bottom: 20px;
    }
    .title {
      font-size: 22px;
      font-weight: 800;
      color: #1a365d;
      margin: 0 0 6px 0;
    }
    .meta {
      font-size: 12px;
      color: #555;
      font-weight: 700;
    }
    .content {
      padding: 8px 0;
      word-break: break-word;
      white-space: pre-wrap;
    }
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
$bodyInner
  <script>
    (async function() {
      try {
        if (document.fonts && document.fonts.ready) {
          await document.fonts.ready;
        }
        await new Promise(r => setTimeout(r, 700));
      } catch (e) {}
      window.focus();
      window.print();
    })();
  </script>
</body>
</html>
''';

  final blob = html.Blob(
    [utf8.encode(enhancedHtml)],
    'text/html;charset=utf-8',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);

  final iframe = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..style.top = '0'
    ..style.width = '210mm'
    ..style.height = '297mm'
    ..style.border = 'none'
    ..src = url;

  html.document.body?.append(iframe);

  await Future<void>.delayed(const Duration(milliseconds: 1400));

  try {
    final w = iframe.contentWindow;
    // contentWindow is WindowBase; cast to Window to access print()
    if (w is html.Window) {
      try {
        w.print();
      } catch (_) {}
    } else {
      html.window.open(url, '_blank');
    }
  } catch (_) {
    html.window.open(url, '_blank');
  }

  Future<void>.delayed(const Duration(seconds: 90), () {
    try {
      iframe.remove();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  });
}

String _escape(String s) => const HtmlEscape().convert(s);

String _extractBody(String fullHtml) {
  final bodyMatch = RegExp(
    r'<body[^>]*>([\s\S]*?)</body>',
    caseSensitive: false,
  ).firstMatch(fullHtml);
  if (bodyMatch != null) return bodyMatch.group(1) ?? fullHtml;
  return fullHtml;
}
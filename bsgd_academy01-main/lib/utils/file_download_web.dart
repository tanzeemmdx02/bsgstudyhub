import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String fileName, String mime) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void viewFile(Uint8List bytes, String mime) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 60), () {
    html.Url.revokeObjectUrl(url);
  });
}
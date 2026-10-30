import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Mobile (Android / iOS) – uses the native WebView engine which has
/// full HarfBuzz shaping, so Bengali text is rendered correctly.
Future<void> printOrExportHtml(String htmlContent, String title) async {
  await Printing.layoutPdf(
    name: title.isEmpty ? 'Suggestion' : title,
    onLayout: (PdfPageFormat format) async {
      return await Printing.convertHtml(
        format: format,
        html: htmlContent,
      );
    },
  );
}
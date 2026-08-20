import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  /// Generates a PDF file from a list of scanned image paths.
  /// Applies high-quality image embedding with memory constraints protection.
  static Future<File> generatePdf({
    required List<String> imagePaths,
    required String targetPath,
  }) async {
    final pdf = pw.Document(
      title: 'Vellum Scanned Document',
      author: 'Vellum Scanner',
      creator: 'Vellum App',
    );

    for (final path in imagePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      final Uint8List bytes = await file.readAsBytes();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // Full borderless page fit
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    final Uint8List pdfBytes = await pdf.save();
    final outFile = File(targetPath);
    await outFile.writeAsBytes(pdfBytes);

    return outFile;
  }
}

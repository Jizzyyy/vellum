import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_models.dart';

class OcrService {
  OcrService({TextRecognitionScript script = TextRecognitionScript.latin})
      : _recognizer = TextRecognizer(script: script);

  final TextRecognizer _recognizer;

  Future<OcrResultModel> processImagePath(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _recognizer.processImage(inputImage);

    final blocks = recognizedText.blocks.map((b) {
      final lines = b.lines.map((l) {
        final elements = l.elements.map((e) {
          return OcrElementModel(
            text: e.text,
            boundingBox: e.boundingBox,
          );
        }).toList();

        return OcrLineModel(
          text: l.text,
          boundingBox: l.boundingBox,
          elements: elements,
        );
      }).toList();

      return OcrBlockModel(
        text: b.text,
        boundingBox: b.boundingBox,
        recognizedLanguages: b.recognizedLanguages,
        lines: lines,
      );
    }).toList();

    return OcrResultModel(
      fullText: recognizedText.text,
      blocks: blocks,
      imagePath: filePath,
      processedAt: DateTime.now(),
    );
  }

  Future<void> dispose() async {
    debugPrint('[OcrService] Releasing native ML Kit TextRecognizer resources');
    await _recognizer.close();
  }
}

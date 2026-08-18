import 'package:flutter/material.dart';

enum OcrStatus {
  idle,
  processing,
  success,
  error,
}

@immutable
class OcrElementModel {
  const OcrElementModel({
    required this.text,
    required this.boundingBox,
  });

  final String text;
  final Rect boundingBox;
}

@immutable
class OcrLineModel {
  const OcrLineModel({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });

  final String text;
  final Rect boundingBox;
  final List<OcrElementModel> elements;
}

@immutable
class OcrBlockModel {
  const OcrBlockModel({
    required this.text,
    required this.boundingBox,
    required this.lines,
    this.recognizedLanguages = const [],
  });

  final String text;
  final Rect boundingBox;
  final List<OcrLineModel> lines;
  final List<String> recognizedLanguages;
}

@immutable
class OcrResultModel {
  const OcrResultModel({
    required this.fullText,
    required this.blocks,
    required this.imagePath,
    required this.processedAt,
  });

  final String fullText;
  final List<OcrBlockModel> blocks;
  final String imagePath;
  final DateTime processedAt;

  int get wordCount => fullText.trim().isEmpty 
      ? 0 
      : fullText.trim().split(RegExp(r'\s+')).length;

  int get lineCount => blocks.fold(0, (prev, block) => prev + block.lines.length);

  bool get isEmpty => fullText.trim().isEmpty;
}

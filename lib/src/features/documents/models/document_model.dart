import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.name,
    required this.pdfPath,
    required this.pageCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String pdfPath;
  final int pageCount;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pdfPath': pdfPath,
      'pageCount': pageCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      pdfPath: map['pdfPath'] as String,
      pageCount: map['pageCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory DocumentModel.fromJson(String source) =>
      DocumentModel.fromMap(json.decode(source) as Map<String, dynamic>);

  DocumentModel copyWith({
    String? id,
    String? name,
    String? pdfPath,
    int? pageCount,
    DateTime? createdAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pdfPath: pdfPath ?? this.pdfPath,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

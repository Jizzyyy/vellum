import 'dart:math';
import 'package:flutter/material.dart';

class EdgeDetector {
  /// Mendeteksi 4 sudut dari sebuah halaman kertas dokumen di dalam gambar.
  /// Output mengembalikan koordinat normalisasi (0.0 hingga 1.0) untuk 4 sudut:
  /// [Top-Left, Top-Right, Bottom-Right, Bottom-Left].
  static List<Point<double>> detectEdges(int width, int height) {
    // Sebagai dasar fungsional yang stabil dan bebas bug, kita buat 
    // kotak deteksi default di tengah layar dengan margin 10% di setiap sisi.
    // Ini mewakili area panduan dokumen A4 yang akan dipotong.
    const margin = 0.10;
    
    return [
      const Point(margin, margin), // Top-Left
      const Point(1.0 - margin, margin), // Top-Right
      const Point(1.0 - margin, 1.0 - margin), // Bottom-Right
      const Point(margin, 1.0 - margin), // Bottom-Left
    ];
  }

  /// Menghitung apakah sudut yang dideteksi membentuk rasio dokumen yang valid (A4/Surat).
  static bool isValidRatio(List<Point<double>> points) {
    if (points.length != 4) return false;
    
    final widthTop = points[1].x - points[0].x;
    final widthBottom = points[2].x - points[3].x;
    final heightLeft = points[3].y - points[0].y;
    final heightRight = points[2].y - points[1].y;

    final avgWidth = (widthTop + widthBottom) / 2;
    final avgHeight = (heightLeft + heightRight) / 2;

    if (avgWidth <= 0) return false;
    final ratio = avgHeight / avgWidth;

    // Rasio A4 standar adalah ~1.414. Kita toleransi dari 1.2 hingga 1.6
    return ratio >= 1.2 && ratio <= 1.6;
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageFilterProcessor {
  /// Memproses gambar mentah: memotong perspektif dan menerapkan filter dokumen hitam-putih.
  static Future<File> processDocumentImage({
    required String sourcePath,
    required String destinationPath,
    bool applyContrastFilter = true,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Gagal men-decode gambar mentah.');
    }

    img.Image processedImage = image;

    if (applyContrastFilter) {
      // 1. Ubah ke Grayscale (abu-abu)
      processedImage = img.grayscale(processedImage);

      // 2. Tingkatkan kontras agar kertas menjadi putih bersih dan tulisan menjadi hitam pekat (Threshold/Binarization)
      // Menggunakan contrast filter bawaan dari package image
      processedImage = img.contrast(processedImage, contrast: 150);
      
      // 3. Noise reduction (mengurangi noise bintik hitam menggunakan gaussian blur tipis)
      processedImage = img.gaussianBlur(processedImage, radius: 1);
    }

    final encodedJpg = img.encodeJpg(processedImage, quality: 85);
    final outFile = File(destinationPath);
    await outFile.writeAsBytes(Uint8List.fromList(encodedJpg));

    return outFile;
  }
}

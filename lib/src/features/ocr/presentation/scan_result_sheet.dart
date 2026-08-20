import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../data/ocr_models.dart';
import '../../documents/providers/document_provider.dart';
import '../../documents/models/document_model.dart';
import '../../scanner/utils/pdf_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScanResultSheet extends ConsumerStatefulWidget {
  const ScanResultSheet({super.key, required this.result});

  final OcrResultModel result;

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    // Set default name using timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    _nameController.text = 'Dokumen_$timestamp';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();

    // Clean up temporary image files associated with this scan session
    // to prevent device disk bloat.
    final imagePath = widget.result.imagePath;
    Future.microtask(() async {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('[ScanResultSheet] Deleted source image: $imagePath');
        }

        // Also check and delete unfiltered original if it exists
        final originalPath = imagePath.replaceAll('_filtered.jpg', '');
        final originalFile = File(originalPath);
        if (originalPath != imagePath && await originalFile.exists()) {
          await originalFile.delete();
          debugPrint('[ScanResultSheet] Deleted original image: $originalPath');
        }
      } catch (e) {
        debugPrint('Error cleaning up ocr temp files: $e');
      }
    });

    super.dispose();
  }

  List<TextSpan> _highlightText(String text, String query, ColorScheme colors) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: colors.onSurface))];
    }

    final List<TextSpan> spans = [];
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    var start = 0;
    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(color: colors.onSurface),
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: colors.onSurface),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: const Color(0xFFFFD600).withValues(alpha: 0.3),
          color: const Color(0xFFFFD600),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  Future<void> _saveAsPdf() async {
    final docName = _nameController.text.trim();
    if (docName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dokumen tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final targetPath = '${appDocDir.path}/$id.pdf';

      // Generate PDF from the OCR image
      await PdfGenerator.generatePdf(
        imagePaths: [widget.result.imagePath],
        targetPath: targetPath,
      );

      final doc = DocumentModel(
        id: id,
        name: docName,
        pdfPath: targetPath,
        pageCount: 1,
        createdAt: DateTime.now(),
      );

      // Save to SharedPreferences Vault via Riverpod Notifier
      await ref.read(documentListProvider.notifier).addDocument(doc);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen "$docName" berhasil disimpan ke Vault.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan dokumen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181B22),
        title: Text(
          'Simpan Dokumen',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama File',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveAsPdf();
            },
            child: const Text('SIMPAN', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFF2A2E3D), width: 1),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Header and Action Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HASIL PEMINDAIAN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.result.wordCount} Kata • ${widget.result.lineCount} Baris',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Salin Teks',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: widget.result.fullText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teks berhasil disalin ke papan klip'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Bagikan Teks',
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      SharePlus.instance.share(ShareParams(text: widget.result.fullText));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari kata di dokumen...',
              labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2A2E3D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2A2E3D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Text Display Area
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2E3D)),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: widget.result.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: colors.error,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada teks terdeteksi.\nCobalah memindai gambar dengan pencahayaan yang lebih baik.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: _highlightText(
                          widget.result.fullText,
                          _searchQuery,
                          colors,
                        ),
                        style: GoogleFonts.inter(
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Actions Panel (Save PDF & Close)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'BATAL',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _showSaveDialog,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text(
                    'SIMPAN PDF',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

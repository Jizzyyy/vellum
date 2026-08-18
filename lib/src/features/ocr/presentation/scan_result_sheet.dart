import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../data/ocr_models.dart';

class ScanResultSheet extends StatefulWidget {
  const ScanResultSheet({super.key, required this.result});

  final OcrResultModel result;

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

          // 5. Close Action Button
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'TUTUP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

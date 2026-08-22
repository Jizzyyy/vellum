import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../../../core/utils/custom_snackbar.dart';

class DocumentLibraryDrawer extends ConsumerWidget {
  const DocumentLibraryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentListProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0F1115),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2E3D))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_copy_rounded, color: Color(0xFF38BDF8), size: 40),
                const SizedBox(height: 12),
                Text(
                  'DOKUMEN VAULT',
                  style: GoogleFonts.shareTechMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${docs.length} Berkas PDF Tersimpan',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          // Document List
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: colors.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Kubah dokumen kosong',
                          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return _DocumentTile(doc: doc);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});

  final DocumentModel doc;

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181B22),
        title: Text(
          'Ubah Nama Dokumen',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nama Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != doc.name) {
                await ref.read(documentListProvider.notifier).renameDocument(doc.id, newName);
                if (context.mounted) {
                  CustomSnackbar.show(
                    context,
                    message: 'Nama dokumen diubah menjadi "$newName".',
                    type: SnackbarType.success,
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SIMPAN', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Formatting date
    final dateStr = '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}';

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error.withValues(alpha: 0.4)),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF181B22),
            title: const Text('Hapus Dokumen?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text('Apakah Anda yakin ingin menghapus "${doc.name}" secara permanen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('HAPUS', style: TextStyle(color: colors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Delete physical file from disk
        final file = File(doc.pdfPath);
        if (await file.exists()) {
          await file.delete();
        }
        // Remove from SharedPrefs database state
        await ref.read(documentListProvider.notifier).removeDocument(doc.id);
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            message: 'Dokumen "${doc.name}" berhasil dihapus.',
            type: SnackbarType.success,
          );
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF0F1115),
            child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          title: Text(
            doc.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '$dateStr • ${doc.pageCount} Hlm',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Ubah Nama',
                onPressed: () => _showRenameDialog(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 18),
                tooltip: 'Bagikan PDF',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final file = File(doc.pdfPath);
                  if (await file.exists()) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(doc.pdfPath)],
                        subject: doc.name,
                        text: 'Membagikan dokumen PDF dari Vellum Scanner.',
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      CustomSnackbar.show(
                        context,
                        message: 'File PDF fisik tidak ditemukan.',
                        type: SnackbarType.error,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

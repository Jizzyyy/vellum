import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import '../../ocr/data/ocr_models.dart';
import '../../ocr/providers/ocr_provider.dart';
import '../../ocr/presentation/scan_result_sheet.dart';
import '../../scanner/utils/image_filter.dart';
import 'widgets/document_guide_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  bool _isAligned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inisialisasi izin & kamera
    Future.microtask(() async {
      final perm = await ref.read(permissionProvider.notifier).checkAndRequestCameraPermission();
      if (perm == CameraPermissionState.granted) {
        ref.read(cameraProvider.notifier).initCamera();
      }
    });

    // Deteksi kemiringan/sudut hadap HP menggunakan akselerometer
    // Jika HP datar (z-axis mendekati 9.8 m/s^2), ganti guide box menjadi hijau (aligned)
    _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final isFlat = event.z.abs() > 9.0 && event.x.abs() < 1.5 && event.y.abs() < 1.5;
      if (isFlat != _isAligned) {
        setState(() {
          _isAligned = isFlat;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ref.read(cameraProvider.notifier).disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      final perm = ref.read(permissionProvider);
      if (perm == CameraPermissionState.granted) {
        ref.read(cameraProvider.notifier).initCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(permissionProvider);
    final camState = ref.watch(cameraProvider);
    
    // Performance Tuning: Granular selector to avoid full-screen rebuilds on OCR status tick
    final isProcessing = ref.watch(ocrProvider.select((s) => s.status == OcrStatus.processing));
    final theme = Theme.of(context);

    if (permState == CameraPermissionState.denied || permState == CameraPermissionState.permanentlyDenied) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 64, color: Color(0xFFF87171)),
                const SizedBox(height: 16),
                Text(
                  'Izin Kamera Diperlukan',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vellum membutuhkan akses kamera untuk memindai dokumen fisik Anda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (permState == CameraPermissionState.permanentlyDenied) {
                      ref.read(permissionProvider.notifier).openSettings();
                    } else {
                      ref.read(permissionProvider.notifier).checkAndRequestCameraPermission();
                    }
                  },
                  child: Text(permState == CameraPermissionState.permanentlyDenied
                      ? 'Buka Pengaturan'
                      : 'Izinkan Akses'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (camState.status == CameraStatus.initializing || camState.status == CameraStatus.uninitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (camState.status == CameraStatus.error) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              camState.errorMessage ?? 'Terjadi kesalahan kamera.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ),
      );
    }

    final controller = camState.controller!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview
          Center(
            child: CameraPreview(controller),
          ),

          // 2. Document Frame Overlay Guide
          DocumentGuideOverlay(isAligned: _isAligned),

          // 3. Top Action Bar (Flash, Filter Toggle, Camera Switch)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        switch (camState.flashMode) {
                          FlashMode.torch => Icons.flash_on,
                          FlashMode.auto => Icons.flash_auto,
                          _ => Icons.flash_off,
                        },
                        color: camState.flashMode != FlashMode.off ? const Color(0xFF38BDF8) : Colors.white,
                      ),
                      onPressed: () => ref.read(cameraProvider.notifier).toggleFlash(),
                    ),
                    IconButton(
                      icon: Icon(
                        camState.applyFilter ? Icons.filter_b_and_w : Icons.filter_b_and_w_outlined,
                        color: camState.applyFilter ? const Color(0xFF38BDF8) : Colors.white,
                      ),
                      tooltip: 'Filter Dokumen',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(cameraProvider.notifier).toggleFilter();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_android_outlined, color: Colors.white),
                      onPressed: () => ref.read(cameraProvider.notifier).switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Controls (Shutter Button)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Posisikan dokumen di dalam kotak panduan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: isProcessing
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final file = await ref.read(cameraProvider.notifier).captureImage();
                              if (file != null && context.mounted) {
                                String targetPath = file.path;
                                try {
                                  // Jika filter aktif, proses gambar dulu
                                  if (ref.read(cameraProvider).applyFilter) {
                                    final filteredFile = await ImageFilterProcessor.processDocumentImage(
                                      sourcePath: file.path,
                                      destinationPath: '${file.path}_filtered.jpg',
                                      applyContrastFilter: true,
                                    );
                                    targetPath = filteredFile.path;
                                  }

                                  // Jalankan OCR pada gambar hasil filter
                                  await ref.read(ocrProvider.notifier).recognizeText(targetPath);
                                  
                                  final currentOcrState = ref.read(ocrProvider);
                                  if (currentOcrState.status == OcrStatus.success && currentOcrState.result != null) {
                                    if (context.mounted) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => ScanResultSheet(result: currentOcrState.result!),
                                      );
                                    }
                                  } else if (currentOcrState.status == OcrStatus.error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(currentOcrState.errorMessage ?? 'Gagal mengenali teks.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                } finally {
                                  // Cleanup temp captured & filtered files to prevent disk bloat
                                  final tempFile = File(file.path);
                                  if (await tempFile.exists()) {
                                    await tempFile.delete();
                                  }
                                  final tempFilteredFile = File('${file.path}_filtered.jpg');
                                  if (await tempFilteredFile.exists()) {
                                    await tempFilteredFile.delete();
                                  }
                                }
                              }
                            },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: isProcessing
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF38BDF8),
                                    strokeWidth: 3,
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

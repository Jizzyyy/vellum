import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import 'widgets/document_guide_overlay.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          const DocumentGuideOverlay(),

          // 3. Top Action Bar (Flash, Camera Switch, Resolution)
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
                    Text(
                      'VELLUM SCAN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.bold,
                      ),
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
                      onTap: () async {
                        final file = await ref.read(cameraProvider.notifier).captureImage();
                        if (file != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Foto berhasil ditangkap: ${file.name}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
                          child: Container(
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

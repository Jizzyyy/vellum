import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CameraStatus {
  uninitialized,
  initializing,
  ready,
  capturing,
  error,
}

@immutable
class CameraState {
  const CameraState({
    this.status = CameraStatus.uninitialized,
    this.controller,
    this.availableCameras = const [],
    this.selectedCameraIndex = 0,
    this.flashMode = FlashMode.off,
    this.applyFilter = true, // default active
    this.batchImagePaths = const [],
    this.errorMessage,
  });

  final CameraStatus status;
  final CameraController? controller;
  final List<CameraDescription> availableCameras;
  final int selectedCameraIndex;
  final FlashMode flashMode;
  final bool applyFilter;
  final List<String> batchImagePaths;
  final String? errorMessage;

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    List<CameraDescription>? availableCameras,
    int? selectedCameraIndex,
    FlashMode? flashMode,
    bool? applyFilter,
    List<String>? batchImagePaths,
    String? errorMessage,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      availableCameras: availableCameras ?? this.availableCameras,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      flashMode: flashMode ?? this.flashMode,
      applyFilter: applyFilter ?? this.applyFilter,
      batchImagePaths: batchImagePaths ?? this.batchImagePaths,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  void toggleFilter() {
    state = state.copyWith(applyFilter: !state.applyFilter);
  }

  void addBatchPage(String path) {
    state = state.copyWith(batchImagePaths: [...state.batchImagePaths, path]);
  }

  void clearBatch() {
    state = state.copyWith(batchImagePaths: const []);
  }

  Future<void> initCamera() async {
    if (state.status == CameraStatus.initializing) return;

    state = state.copyWith(status: CameraStatus.initializing, errorMessage: null);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'No camera hardware found on this device.',
        );
        return;
      }

      final controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      state = state.copyWith(
        status: CameraStatus.ready,
        controller: controller,
        availableCameras: cameras,
        selectedCameraIndex: 0,
        flashMode: FlashMode.off,
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to initialize camera: $e',
      );
    }
  }

  Future<void> toggleFlash() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    final nextMode = switch (state.flashMode) {
      FlashMode.off => FlashMode.torch,
      FlashMode.torch => FlashMode.auto,
      FlashMode.auto => FlashMode.off,
      _ => FlashMode.off,
    };

    try {
      await controller.setFlashMode(nextMode);
      state = state.copyWith(flashMode: nextMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> switchCamera() async {
    if (state.availableCameras.length < 2) return;

    final nextIndex = (state.selectedCameraIndex + 1) % state.availableCameras.length;
    await state.controller?.dispose();

    state = state.copyWith(
      status: CameraStatus.initializing,
      controller: null,
      selectedCameraIndex: nextIndex,
    );

    try {
      final controller = CameraController(
        state.availableCameras[nextIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      state = state.copyWith(
        status: CameraStatus.ready,
        controller: controller,
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to switch camera: $e',
      );
    }
  }

  Future<XFile?> captureImage() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized || state.status == CameraStatus.capturing) {
      return null;
    }

    try {
      state = state.copyWith(status: CameraStatus.capturing);
      final file = await controller.takePicture();
      state = state.copyWith(status: CameraStatus.ready);
      return file;
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to capture image: $e',
      );
      return null;
    }
  }

  void disposeCamera() {
    state.controller?.dispose();
    state = const CameraState();
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

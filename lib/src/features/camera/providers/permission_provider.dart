import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionState {
  initial,
  granted,
  denied,
  permanentlyDenied,
}

class PermissionNotifier extends StateNotifier<CameraPermissionState> {
  PermissionNotifier() : super(CameraPermissionState.initial);

  Future<CameraPermissionState> checkAndRequestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      state = CameraPermissionState.granted;
      return state;
    }

    if (status.isPermanentlyDenied) {
      state = CameraPermissionState.permanentlyDenied;
      return state;
    }

    // Minta izin ke OS
    final requestStatus = await Permission.camera.request();
    if (requestStatus.isGranted) {
      state = CameraPermissionState.granted;
    } else if (requestStatus.isPermanentlyDenied) {
      state = CameraPermissionState.permanentlyDenied;
    } else {
      state = CameraPermissionState.denied;
    }

    return state;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, CameraPermissionState>((ref) {
  return PermissionNotifier();
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ocr_models.dart';
import '../data/ocr_service.dart';

@immutable
class OcrState {
  const OcrState({
    this.status = OcrStatus.idle,
    this.result,
    this.errorMessage,
  });

  final OcrStatus status;
  final OcrResultModel? result;
  final String? errorMessage;

  OcrState copyWith({
    OcrStatus? status,
    OcrResultModel? result,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return OcrState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OcrNotifier extends StateNotifier<OcrState> {
  OcrNotifier(this._ocrService) : super(const OcrState());

  final OcrService _ocrService;

  Future<void> recognizeText(String imagePath) async {
    // Clear old result immediately when starting a new scan session
    state = state.copyWith(
      status: OcrStatus.processing, 
      errorMessage: null,
      clearResult: true,
    );

    try {
      final ocrResult = await _ocrService.processImagePath(imagePath);
      state = state.copyWith(
        status: OcrStatus.success,
        result: ocrResult,
      );
    } catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: 'Gagal mengenali teks: $e',
      );
    }
  }

  void reset() {
    state = const OcrState();
  }

  @override
  void dispose() {
    // Ensure native resource disposal is triggered
    _ocrService.dispose();
    super.dispose();
  }
}

// Singleton OCR Service Provider with automatic resource cleanup
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>((ref) {
  final service = ref.watch(ocrServiceProvider);
  return OcrNotifier(service);
});

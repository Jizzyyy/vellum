import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
  }) {
    final color = switch (type) {
      SnackbarType.success => const Color(0xFF34D399),
      SnackbarType.error => const Color(0xFFF87171),
      SnackbarType.info => const Color(0xFF38BDF8),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF181B22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

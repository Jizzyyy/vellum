import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/camera/presentation/camera_screen.dart';
import 'src/features/documents/providers/document_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Portrait untuk scanner dokumen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VellumApp(),
    ),
  );
}

class VellumApp extends StatelessWidget {
  const VellumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vellum',
      debugShowCheckedModeBanner: false,
      theme: VellumTheme.darkTheme,
      home: const CameraScreen(),
    );
  }
}

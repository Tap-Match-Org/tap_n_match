import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/firebase_options.dart';
import 'package:tap_n_match/core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Landscape and Full-screen globally
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (e) {
    debugPrint('SystemChrome error: $e');
  }

  try {
    // Adding a timeout to Firebase initialization to prevent hanging
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('Firebase initialization timed out');
      return Firebase.app(); // Return existing app if possible
    });
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const TapAndMatchApp());
}

class TapAndMatchApp extends StatelessWidget {
  const TapAndMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      title: 'Tap & Match',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.pixelifySansTextTheme(),
      ),
    );
  }
}

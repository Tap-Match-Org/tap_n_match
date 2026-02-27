import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/firebase_options.dart';
import 'package:tap_n_match/core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Landscape and Full-screen globally
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Sets Pixelify Sans for the entire application
        textTheme: GoogleFonts.pixelifySansTextTheme(),
      ),
    );
  }
}
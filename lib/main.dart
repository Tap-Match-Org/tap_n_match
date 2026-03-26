import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/firebase_options.dart';
import 'package:tap_n_match/core/routes.dart';
import 'package:tap_n_match/core/soundmanager.dart';

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
      builder: (context, child) {
        return Listener(
          onPointerDown: (PointerDownEvent event) {
            final hitTestResult = HitTestResult();
            // Use hitTestInView to avoid deprecation warning
            final view = View.of(context);
            WidgetsBinding.instance.hitTestInView(hitTestResult, event.position, view.viewId);
            
            bool hitInteractive = false;
            for (final entry in hitTestResult.path) {
              final target = entry.target;
              if (target is RenderBox) {
                // Check if the hit target or its parents are likely interactive
                // This includes buttons (ElevatedButton, TextButton, etc. which use InkWell/RenderSemanticsAnnotations)
                // and TextFields.
                if (target.runtimeType.toString().contains('RenderSemanticsAnnotations') ||
                    target.runtimeType.toString().contains('RenderPointerListener') ||
                    target.runtimeType.toString().contains('RenderInk')) {
                  hitInteractive = true;
                  break;
                }
              }
            }

            if (hitInteractive) {
              soundManager.playTap();
            }
          },
          child: child,
        );
      },
    );
  }
}
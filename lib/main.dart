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
            final view = View.of(context);
            WidgetsBinding.instance.hitTestInView(hitTestResult, event.position, view.viewId);
            
            bool hitInteractive = false;
            for (final entry in hitTestResult.path) {
              final target = entry.target;

              final typeName = target.runtimeType.toString();
              
              // RenderInk captures most Material-based buttons and list items
              // RenderEditable captures TextFields
              // RenderPointerListener is used by GestureDetector
              // We include RenderParagraph only if it's likely part of an interactive element
              if (typeName.contains('RenderInk') || 
                  typeName.contains('RenderEditable') ||
                  typeName.contains('RenderListTile') ||
                  typeName.contains('RenderDropdownMenu')) {
                hitInteractive = true;
                break;
              }

              // Special handling for RenderPointerListener to avoid background clicks
              // We check if it's a descendant of something that shouldn't be silent
              if (target is RenderPointerListener) {
                if (target.onPointerDown != null) {
                   // This is still a bit broad but usually catches specific UI elements
                   // if they are NOT the top-level page listener.
                   // However, for now, RenderInk covers most cases.
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
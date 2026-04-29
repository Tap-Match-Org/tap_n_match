import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            final path = hitTestResult.path.toList();

            // 1. Explicit check for known Material interactive RenderObjects
            for (final entry in path) {
              final target = entry.target;
              final typeName = target.runtimeType.toString();
              
              if (typeName.contains('RenderInk') || 
                  typeName.contains('RenderEditable') ||
                  typeName.contains('RenderToggleable') ||
                  typeName.contains('RenderSlider') ||
                  typeName.contains('RenderListTile') ||
                  typeName.contains('RenderDropdownMenu')) {
                hitInteractive = true;
                break;
              }
            }

            // 2. If no explicit Material widget found, check for local PointerListeners
            // We ignore listeners that are too high in the tree (Navigator, Scaffold, etc.)
            // by skipping the last 8 entries of the hit path.
            if (!hitInteractive && path.length > 8) {
              final localLimit = path.length - 8;
              for (int i = 0; i < localLimit; i++) {
                final target = path[i].target;
                if (target is RenderPointerListener && target.onPointerDown != null) {
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

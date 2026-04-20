import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    
    // For Android emulators, 10.0.2.2 is the host machine.
    // For iOS simulators or Windows/macOS/Linux desktop, localhost works.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    
    return 'http://localhost:8000';
  }

  static Uri getUri(String path) {
    return Uri.parse('$baseUrl$path');
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    
    // 192.168.1.2 is your PC's local IP address.
    // This allows your physical mobile device to connect to the backend
    // as long as both are on the same Wi-Fi network.
    return 'http://192.168.1.2:8000';
  }

  static Uri getUri(String path) {
    return Uri.parse('$baseUrl$path');
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Edit this value manually for a physical device on your LAN.
  // The phone/tablet must be on the same Wi-Fi network as the backend host.
  // Android emulator: http://10.0.2.2:8000
  // iOS simulator:   http://localhost:8000
  // Physical device: http://<your-computer-lan-ip>:8000
  static const String physicalDeviceBaseUrl = 'http://192.168.1.1:8000';

  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String iosSimulatorBaseUrl = 'http://localhost:8000';

  // Optional compile-time override. Example:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8000
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return iosSimulatorBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidEmulatorBaseUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosSimulatorBaseUrl;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        // Desktop apps run on the same machine as the backend during local dev,
        // so localhost is the safest default. Change `physicalDeviceBaseUrl`
        // or pass `--dart-define=API_BASE_URL=...` when targeting a real phone/tablet.
        return iosSimulatorBaseUrl;
    }
  }
}

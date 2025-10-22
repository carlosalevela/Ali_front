// lib/env.dart
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://web-production-fada9.up.railway.app/', // útil para dev local
  );
}

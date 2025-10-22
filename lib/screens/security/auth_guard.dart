// lib/security/auth_guard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard {
  /// Intenta leer el access token de distintas keys comunes.
  static Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Orden de preferencia: 'access_token' -> 'access' -> 'token'
    final k1 = prefs.getString('access_token');
    if (k1 != null && k1.isNotEmpty) return k1;

    final k2 = prefs.getString('access');
    if (k2 != null && k2.isNotEmpty) return k2;

    final k3 = prefs.getString('token');
    if (k3 != null && k3.isNotEmpty) return k3;

    return null;
  }

  /// Decodifica payload del JWT (sin validar firma). Seguro ante errores.
  static Map<String, dynamic> _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final obj = jsonDecode(decoded);
      return obj is Map<String, dynamic> ? obj : {};
    } catch (_) {
      return {};
    }
  }

  /// ¿Está expirado por el claim `exp`?
  static bool _isExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp is int) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= exp;
    }
    if (exp is double) {
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      return nowSec >= exp;
    }
    // Si no hay exp, no bloqueamos (evitamos falsos negativos).
    return false;
  }

  /// ¿Hay sesión válida?
  static Future<bool> isLoggedIn() async {
    final tok = await _readToken();
    if (tok == null || tok.isEmpty) return false;
    final payload = _decodeJWT(tok);
    if (_isExpired(payload)) return false;
    return true;
  }

  /// Rol desde JWT ('rol') o, si no existe, desde SharedPreferences ('rol').
  static Future<String?> getRoleRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final tok = await _readToken();
    String? fromJwt;
    if (tok != null) {
      final payload = _decodeJWT(tok);
      final v = payload['rol'];
      if (v != null) fromJwt = v.toString();
    }
    final fromPrefs = prefs.getString('rol');
    return fromJwt ?? fromPrefs;
  }

  /// Rol normalizado a MAYÚSCULAS y sin espacios.
  static Future<String?> getRoleNormalized() async {
    final r = await getRoleRaw();
    if (r == null) return null;
    return r.trim().toUpperCase();
  }

  /// Verifica acceso por rol (si no pasas roles, basta con estar logeado).
  static Future<bool> canAccess({List<String>? roles}) async {
    if (!await isLoggedIn()) return false;

    if (roles == null || roles.isEmpty) return true;

    // Normaliza ambos lados
    final needs = roles.map((e) => e.trim().toUpperCase()).toList();
    final userRole = await getRoleNormalized();

    return userRole != null && needs.contains(userRole);
  }

  /// Úsalo en pantallas (post-frame) para redirigir si no cumple
  static Future<void> redirectIfNotAllowed(
    BuildContext context, {
    List<String>? roles,
    String loginRouteName = '/',
  }) async {
    if (!await canAccess(roles: roles)) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(loginRouteName, (_) => false);
    }
  }
}

/// Wrapper de comodidad para rutas protegidas con Navigator 1.0
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<String>? requireRoles;
  final String loginRouteName;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.requireRoles,
    this.loginRouteName = '/',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthGuard.canAccess(roles: requireRoles),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) return child;

        // No permitido → fuera (post-frame para evitar setState durante build)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(loginRouteName, (_) => false);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}

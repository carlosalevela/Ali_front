import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/estudiante_home.dart';
import 'screens/test_grado9_screen.dart';
import 'screens/test_grado_10_11_screen.dart';
import 'screens/historial_test_grado9_screen.dart';
import 'screens/historial_test_10_11_screen.dart';
import 'screens/reset_password_screen.dart';

// 🔒 Guard
import 'screens/security/auth_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALI PSICOORIENTADORA',

      // ─── Localización ───────────────────────────────────────────
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ─── Tema ──────────────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // ─── Rutas de la app ───────────────────────────────────────
      initialRoute: '/',
      routes: {
        // Públicas
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/recuperacion/contrasena-confirmada': (ctx) => const ResetPasswordScreen(),
        '/recuperacion/contrasena-confirmada/': (ctx) => const ResetPasswordScreen(),

        // Protegidas por sesión + rol
        '/admin': (context) => const ProtectedRoute(
              requireRoles: ['ADMIN'],
              child: AdminDashboard(),
              loginRouteName: '/',
            ),
        '/estudiante': (context) => const ProtectedRoute(
              requireRoles: ['ESTUDIANTE', 'ADMIN'],
              child: EstudianteHome(),
              loginRouteName: '/',
            ),
        '/test_grado9': (context) => const ProtectedRoute(
              requireRoles: ['ESTUDIANTE'],
              child: TestGrado9Page(),
              loginRouteName: '/',
            ),
        '/test_grado_10_11': (context) => const ProtectedRoute(
              requireRoles: ['ESTUDIANTE'],
              child: TestGrado1011Screen(),
              loginRouteName: '/',
            ),
        '/historial-test9': (context) => const ProtectedRoute(
              requireRoles: ['ESTUDIANTE', 'ADMIN'],
              child: HistorialTestGrado9Screen(),
              loginRouteName: '/',
            ),
        '/historial-test-10-11': (context) => const ProtectedRoute(
              requireRoles: ['ESTUDIANTE', 'ADMIN'],
              child: HistorialTestGrado1011Screen(),
              loginRouteName: '/',
            ),
      },

      // ⬇️ Maneja URLs con query: /recuperacion/contrasena-confirmada?uid=...&token=...
      onGenerateRoute: (settings) {
        final raw = settings.name ?? '/';
        final uri = Uri.parse(raw);

        if (uri.path == '/recuperacion/contrasena-confirmada' ||
            uri.path == '/recuperacion/contrasena-confirmada/') {
          final args = {
            'uid': uri.queryParameters['uid'],
            'token': uri.queryParameters['token'],
          };

          return MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
            settings: RouteSettings(
              name: '/recuperacion/contrasena-confirmada',
              arguments: args,
            ),
          );
        }

        // deja que 'routes' resuelva las rutas conocidas
        return null;
      },

      // Fallback: URLs desconocidas → login
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

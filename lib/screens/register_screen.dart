import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _nombre   = TextEditingController();
  final TextEditingController _email    = TextEditingController();
  final TextEditingController _edad     = TextEditingController();
  final TextEditingController _password = TextEditingController();

  final List<String> gradosDisponibles = ['9', '10', '11'];
  String? _gradoSeleccionado;

  bool _isLoading = false;
  String? _message;
  bool _obscure = true; // solo UI (ver/ocultar contraseña)

  // ---------- Helpers de estética ----------
  InputDecoration _dec({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.6), width: 1.4),
      ),
    );
  }

  bool get _emailOk {
    final v = _email.text.trim();
    if (v.isEmpty) return false;
    final okBase = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v);
    return okBase && v.toLowerCase().endsWith('@gmail.com');
  }

  double _passwordScore(String v) {
    if (v.isEmpty) return 0;
    var s = 0.0;
    if (v.length >= 8) s += 0.34;
    if (RegExp(r'[A-Z]').hasMatch(v)) s += 0.22;
    if (RegExp(r'[0-9]').hasMatch(v)) s += 0.22;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) s += 0.22;
    return s.clamp(0, 1);
  }

  Color _strengthColor(double score) {
    final cs = Theme.of(context).colorScheme;
    if (score < 0.34) return cs.error;
    if (score < 0.67) return cs.tertiary;
    return cs.primary;
  }

  /// ————————————————————————————————
  /// REGISTRO (sin cambios de lógica)
  /// ————————————————————————————————
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await apiService.register({
      "username": _username.text.trim(),
      "nombre": _nombre.text.trim(),
      "email": _email.text.trim(),
      "grado": _gradoSeleccionado,
      "edad": int.tryParse(_edad.text.trim()) ?? 0,
      "password": _password.text.trim(),
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // 🔄 Redirección inmediata al login
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        _message = "Error: ${result['message']}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F6),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --------- Blobs difusos de fondo (profundidad) ----------
          Positioned(
            left: -60,
            top: -40,
            child: _blurBlob(220, const Color(0xFF1976D2).withOpacity(0.18)),
          ),
          Positioned(
            right: -50,
            bottom: -50,
            child: _blurBlob(260, const Color(0xFF64B5F6).withOpacity(0.16)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: cs.primary.withOpacity(0.06),
                          blurRadius: 12,
                          spreadRadius: -2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // --------- Encabezado con onda decorativa ----------
                        ClipPath(
                          clipper: TopWaveClipper(),
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0D47A1), Color(0xFF64B5F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Registro ALI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // -------------------- Formulario --------------------
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Usuario
                                TextFormField(
                                  controller: _username,
                                  onFieldSubmitted: (_) => _register(),
                                  decoration: _dec(label: 'Usuario', icon: Icons.person),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Requerido' : null,
                                ),
                                const SizedBox(height: 12),

                                // Nombre completo
                                TextFormField(
                                  controller: _nombre,
                                  onFieldSubmitted: (_) => _register(),
                                  decoration: _dec(label: 'Nombre completo', icon: Icons.badge),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    final partes = val.trim().split(' ');
                                    if (partes.length < 2 ||
                                        partes.any((p) => p.trim().length < 2)) {
                                      return 'Ingrese nombre completo';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Correo
                                TextFormField(
                                  controller: _email,
                                  onFieldSubmitted: (_) => _register(),
                                  onChanged: (_) => setState(() {}),
                                  decoration: _dec(
                                    label: 'Correo electrónico',
                                    icon: Icons.email,
                                    suffix: _email.text.isEmpty
                                        ? null
                                        : Icon(_emailOk ? Icons.check_circle : Icons.error_outline),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    final email = val.trim();
                                    if (!email.contains('@')) {
                                      return 'Correo inválido';
                                    }
                                    if (!email.toLowerCase().endsWith('@gmail.com')) {
                                      return 'Solo correos @gmail.com';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Grado (se mantiene dropdown para no tocar tu lógica)
                                DropdownButtonFormField<String>(
                                  decoration: _dec(label: 'Grado', icon: Icons.school),
                                  value: _gradoSeleccionado,
                                  items: gradosDisponibles
                                      .map((g) => DropdownMenuItem(value: g, child: Text('Grado $g')))
                                      .toList(),
                                  onChanged: (value) => setState(() => _gradoSeleccionado = value),
                                  validator: (val) =>
                                      val == null ? 'Seleccione un grado' : null,
                                ),
                                const SizedBox(height: 12),

                                // Edad
                                TextFormField(
                                  controller: _edad,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onFieldSubmitted: (_) => _register(),
                                  decoration: _dec(label: 'Edad', icon: Icons.cake),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    if (int.tryParse(val.trim()) == null) {
                                      return 'Debe ser un número válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Contraseña + barra de fuerza (solo UI)
                                StatefulBuilder(
                                  builder: (context, setInner) {
                                    final score = _passwordScore(_password.text);
                                    return Column(
                                      children: [
                                        TextFormField(
                                          controller: _password,
                                          obscureText: _obscure,
                                          onFieldSubmitted: (_) => _register(),
                                          onChanged: (_) => setInner(() {}),
                                          decoration: _dec(
                                            label: 'Contraseña',
                                            icon: Icons.lock,
                                            suffix: IconButton(
                                              onPressed: () => setState(() => _obscure = !_obscure),
                                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Requerido';
                                            }
                                            if (val.trim().length < 6) {
                                              return 'Mínimo 6 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: score,
                                            minHeight: 8,
                                            color: _strengthColor(score),
                                            backgroundColor:
                                                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            score < 0.34
                                                ? 'Usa 8+ caracteres, números y símbolos'
                                                : score < 0.67
                                                    ? '¡Casi! Añade mayúsculas o símbolos'
                                                    : 'Contraseña segura ✔',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 18),

                                // Botón registrar con gradiente (usa tu _isLoading)
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          style: ButtonStyle(
                                            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                            elevation: const WidgetStatePropertyAll(3),
                                            backgroundColor:
                                                const WidgetStatePropertyAll(Colors.transparent),
                                            shadowColor:
                                                WidgetStatePropertyAll(cs.primary.withOpacity(0.4)),
                                          ),
                                          onPressed: _register,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Registrar',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                // Mensaje de error/ok
                                if (_message != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: Text(
                                      _message!,
                                      style: TextStyle(
                                        color: _message!.startsWith("Error")
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Blob difuso reutilizable ----------
  Widget _blurBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 40)],
      ),
    );
  }
}

/// ClipPath para la cabecera ondulada (se mantiene tu implementación)
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

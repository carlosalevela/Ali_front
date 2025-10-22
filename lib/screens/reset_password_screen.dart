import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// Ruta en Web: /recuperacion/contrasena-confirmada?uid=...&token=...
  static const routeName = '/recuperacion/contrasena-confirmada';

  const ResetPasswordScreen({super.key, this.uid, this.token});

  final String? uid;
  final String? token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ApiService apiService = ApiService();

  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _pass2Ctrl = TextEditingController();

  String? _uid;
  String? _token;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // 1) Prioridad: uid/token del constructor (opcional)
    _uid = widget.uid;
    _token = widget.token;

    // 2) Si no vienen, intentamos leerlos de arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_uid == null || _token == null)) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map) {
          _uid ??= args['uid']?.toString();
          _token ??= args['token']?.toString();
        }
      }

      // 3) Si aún no vienen, intentamos leerlos de la URL
      if (_uid == null || _token == null) {
        // a) Forma “normal”: /ruta?uid=...&token=...
        final qp = Uri.base.queryParameters;
        _uid ??= qp['uid'];
        _token ??= qp['token'];

        // b) Fallback cuando los params van tras el hash:  #/ruta?uid=...&token=...
        if ((_uid == null || _token == null) && Uri.base.fragment.isNotEmpty) {
          final fragUri = Uri.parse(Uri.base.fragment);
          _uid ??= fragUri.queryParameters['uid'];
          _token ??= fragUri.queryParameters['token'];
        }
      }

      // Si faltan, mostramos error visual (pero permitimos seguir por si pegan manual)
      if (mounted && (_uid == null || _token == null)) {
        setState(() {
          _error =
              'Enlace inválido o incompleto. Asegúrate de abrir el link del correo que contiene uid y token.';
        });
      }
      setState(() {});
    });
  }

  Future<void> _confirmar() async {
    setState(() => _error = null);

    final p1 = _passCtrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();

    if ((_uid ?? '').isEmpty || (_token ?? '').isEmpty) {
      setState(() => _error = 'Falta uid o token en el enlace.');
      return;
    }
    if (p1.isEmpty || p2.isEmpty) {
      setState(() => _error = 'Completa ambos campos de contraseña.');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (p1.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    setState(() => _isSubmitting = true);

    final resp = await apiService.confirmarRecuperacion(
      uid: _uid!,
      token: _token!,
      newPassword: p1,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (resp['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente. Inicia sesión.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, '/');
    } else {
      final msg = resp['message']?.toString() ?? 'No se pudo actualizar la contraseña.';
      setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasParams = (_uid ?? '').isNotEmpty && (_token ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: _cardDeco,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      'assets/logo_ali.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.school_outlined,
                        color: Colors.blue.shade300,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Restablecer contraseña',
                  style: TextStyle(
                    color: Color(0xFF1C274C),
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasParams
                      ? 'Ingresa tu nueva contraseña'
                      : 'El enlace no trae uid/token. Verifica la URL.',
                  style: TextStyle(color: Colors.black.withOpacity(.55)),
                ),
                const SizedBox(height: 22),

                // Password fields
                _PasswordField(
                  controller: _passCtrl,
                  hint: 'Nueva contraseña',
                  enabled: hasParams && !_isSubmitting,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _pass2Ctrl,
                  hint: 'Confirmar contraseña',
                  enabled: hasParams && !_isSubmitting,
                ),
                const SizedBox(height: 18),

                // Error
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 12),
                ],

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (!hasParams || _isSubmitting) ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF376AED), Color(0xFF2F55D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Confirmar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password input reutilizable
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey.shade400),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: widget.enabled ? () => setState(() => _obscure = !_obscure) : null,
        ),
        filled: true,
        fillColor: const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF2F55D4), width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade100.withOpacity(.6)),
        ),
      ),
    );
  }
}

final _cardDeco = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ],
);

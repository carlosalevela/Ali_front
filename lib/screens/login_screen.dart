import 'dart:math' as math; // NUEVO: para animación shake
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin { // NUEVO mixin
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final ApiService apiService = ApiService();

  bool _isLoading = false;
  String? _error;

  // ======= NUEVO: errores por campo =======
  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  // ======= NUEVO: animación de “shake” para el botón Iniciar =======
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnim = CurvedAnimation(
    parent: _shakeCtrl,
    curve: Curves.elasticIn,
  );
  // ================================================================

  @override
  void initState() {
    super.initState();
    // Limpia error de campo al tipear
    _emailController.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _passwordController.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
    _usernameController.addListener(() {
      if (_usernameError != null) setState(() => _usernameError = null);
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose(); // NUEVO
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
      // limpia errores previos por campo
      _emailError = null;
      _passwordError = null;
      _usernameError = null;
    });

    final result = await apiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result is Map && result['success'] == true) {
      final rol = result['role'];
      if (rol == 'admin') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/estudiante');
      }
    } else {
      // ======= NUEVO: mapeo de errores a campos + mensaje garantizado =======
      final rawMsg = (result is Map ? result['message'] : null)?.toString();
      final msg = (rawMsg == null || rawMsg.trim().isEmpty)
          ? 'Credenciales inválidas'
          : rawMsg;

      final field = (result is Map
              ? (result['field'] ?? result['error_field'])
              : null)
          ?.toString()
          .toLowerCase();
      final code  = (result is Map ? result['code'] : null)
          ?.toString()
          .toLowerCase();
      final lmsg  = msg.toLowerCase();

      if (field == 'email' || lmsg.contains('correo') || lmsg.contains('email')) {
        _emailError = msg;
      } else if (field == 'password' || lmsg.contains('contraseña') || lmsg.contains('password') || code == 'invalid_credentials') {
        _passwordError = msg;
      } else if (field == 'username' || lmsg.contains('usuario')) {
        _usernameError = msg;
      } else {
        _passwordError = 'Credenciales inválidas';
      }

      setState(() => _error = msg);

      // Dispara animación de “shake” del botón
      _shakeCtrl.forward(from: 0);
      // ================================================================
    }
  }

  // ======= NUEVO: flujo "¿Olvidaste tu contraseña?" (igual al tuyo) =======
  void _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Correo registrado'),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty) return;

                        setState(() => sending = true);
                        final resp = await apiService.solicitarRecuperacion(email);
                        if (ctx.mounted) Navigator.pop(ctx, resp);
                      },
                child: sending
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar enlace'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    final ok = result['success'] == true;
    final msg = (result['detail'] ?? result['message'] ?? (ok
        ? 'Si el correo existe, te enviamos un enlace.'
        : 'No se pudo enviar el enlace.')) as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            final wrapperWidth = isWide ? 980.0 : 420.0;

            final content = isWide
                ? Row(
                    children: const [
                      // --------- PANEL ILUSTRADO IZQUIERDO ---------
                      Expanded(child: _IllustrationCard()),
                      SizedBox(width: 24),
                      // --------- FORMULARIO ---------
                      Expanded(child: _LoginCardWrapper()),
                    ],
                  )
                : const _LoginCardWrapper();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: wrapperWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: content,
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper que inyecta controladores/estado y pasa animación de shake
class _LoginCardWrapper extends StatelessWidget {
  const _LoginCardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>()!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 22), // baja -> arriba
        child: Opacity(opacity: t, child: child),
      ),
      child: _LoginCard(
        usernameController: state._usernameController,
        emailController: state._emailController,
        passwordController: state._passwordController,
        isLoading: state._isLoading,
        error: state._error,
        onLogin: state._login,
        onForgot: state._forgotPassword,
        // NUEVO: errores y animación
        emailError: state._emailError,
        passwordError: state._passwordError,
        usernameError: state._usernameError,
        shake: state._shakeAnim,
      ),
    );
  }
}

/// ================== TARJETA DEL FORMULARIO (derecha / móvil) ==================
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.error,
    required this.onLogin,
    required this.onForgot,
    // NUEVO
    this.emailError,
    this.passwordError,
    this.usernameError,
    this.shake,
  });

  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback onForgot;

  // NUEVO
  final String? emailError;
  final String? passwordError;
  final String? usernameError;
  final Animation<double>? shake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo ALI arriba
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
          Text(
            'ALI ORIENTADOR VOCACIONAL',
            style: TextStyle(
              color: const Color(0xFF1C274C),
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenido de nuevo',
            style: TextStyle(color: Colors.black.withOpacity(.55)),
          ),
          const SizedBox(height: 22),

          _Input(
            controller: emailController,
            hint: 'Email',
            icon: Icons.alternate_email,
            onSubmit: onLogin,
            errorText: emailError,
            isError: emailError != null,
          ),
          const SizedBox(height: 14),

          _PasswordInput(
            controller: passwordController,
            hint: 'Contraseña',
            onSubmit: onLogin,
            errorText: passwordError,
            isError: passwordError != null,
          ),
          const SizedBox(height: 14),

          _Input(
            controller: usernameController,
            hint: 'Usuario',
            icon: Icons.person_outline,
            onSubmit: onLogin,
            errorText: usernameError,
            isError: usernameError != null,
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),

          const SizedBox(height: 10),

          // ======= NUEVO: botón con efecto “shake” en fallo =======
          _ShakeX(
            animation: shake,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
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
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Iniciar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          // =========================================================

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/register'),
            child: const Text(
              'Registrarse',
              style: TextStyle(
                color: Color(0xFF2F55D4),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],

          const SizedBox(height: 8),
          Opacity(
            opacity: .6,
            child: Text(
              '© 2025 ALI',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

  /// ================== PANEL ILUSTRADO IZQUIERDO (centrado + burbujas) ==================
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const PositionedFillGradient(),
          const Positioned(
            top: 40, left: -30,
            child: _Blob(size: 140, c1: Color(0xFFBFD7FF), c2: Color(0xFFE6F0FF)),
          ),
          const Positioned(
            bottom: 60, right: -20,
            child: _Blob(size: 160, c1: Color(0xFFD9E7FF), c2: Color(0xFFF2F7FF)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FractionallySizedBox(
                widthFactor: 0.86,
                child: Image.asset(
                  'assets/orientacion_vocacional.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extract pequeño solo para mantener limpio (no cambia nombres previos)
class PositionedFillGradient extends StatelessWidget {
  const PositionedFillGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.c1, required this.c2});
  final double size;
  final Color c1, c2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c1, c2]),
        boxShadow: [BoxShadow(color: c1.withOpacity(.35), blurRadius: 24, spreadRadius: 6)],
      ),
    );
  }
}

/// ================== INPUTS ==================
class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    required this.onSubmit,
    // ======= NUEVO =======
    this.errorText,
    this.isError = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback onSubmit;

  // NUEVO
  final String? errorText;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.blueGrey.shade100),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
    );

    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isError ? Colors.redAccent : Colors.blueGrey.shade400,
        ),
        filled: true,
        fillColor: const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: isError ? errorBorder : baseBorder,
        focusedBorder: isError
            ? errorBorder
            : const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF2F55D4), width: 1.6),
              ),
        errorText: errorText,
      ),
    );
  }
}

// Password con toggle (UI)
class _PasswordInput extends StatefulWidget {
  const _PasswordInput({
    required this.controller,
    required this.hint,
    required this.onSubmit,
    // ======= NUEVO =======
    this.errorText,
    this.isError = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;

  // NUEVO
  final String? errorText;
  final bool isError;

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.blueGrey.shade100),
    );
    final errorBorder = const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Colors.redAccent, width: 1.6),
    );

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onSubmitted: (_) => widget.onSubmit(),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(
          Icons.lock_outline,
          color: widget.isError ? Colors.redAccent : Colors.blueGrey.shade400,
        ),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: widget.isError ? errorBorder : baseBorder,
        focusedBorder: widget.isError
            ? errorBorder
            : const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF2F55D4), width: 1.6),
              ),
        errorText: widget.errorText,
      ),
    );
  }
}

// ======= NUEVO: widget reutilizable para “shake” horizontal =======
class _ShakeX extends StatelessWidget {
  const _ShakeX({required this.child, this.animation});
  final Widget child;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) {
        // Pequeña oscilación horizontal
        final t = animation!.value;
        final dx = math.sin(t * math.pi * 6) * 8; // 3 ciclos, 8px amplitud
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
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

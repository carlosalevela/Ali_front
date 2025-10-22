    import 'dart:math' as math;
    import 'dart:ui' as ui;
    import 'package:flutter/material.dart';

    // =================== PALETA ALI (global) ===================
    const _blue      = Color(0xFF1976D2);
    const _blueDark  = Color(0xFF0D47A1);
    const _lightBg   = Color(0xFFE0F2FF);
    const _bubbleBG  = Color(0xFFF1F8FF);
    const _neonCyan  = Color(0xFF7FDBFF); // brillo sutil en gama fría

    class ComoCalificarScreen extends StatefulWidget {
    const ComoCalificarScreen({super.key});
    @override
    State<ComoCalificarScreen> createState() => _ComoCalificarScreenState();
    }

    class _ComoCalificarScreenState extends State<ComoCalificarScreen>
        with TickerProviderStateMixin {
    late final AnimationController _introCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 750))
            ..forward();
    late final AnimationController _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
            ..repeat(reverse: true);

    @override
    void dispose() {
        _introCtrl.dispose();
        _glowCtrl.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final wide = MediaQuery.of(context).size.width >= 900;

        return Scaffold(
        backgroundColor: _lightBg,
        body: SafeArea(
            child: Stack(
            children: [
                // Fondo
                Positioned.fill(
                child: const DecoratedBox(
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_lightBg, Colors.white],
                    ),
                    ),
                ),
                ),
                const Positioned.fill(child: _StarDust(opacity: .035, count: 60)),

                // Contenido
                Column(
                children: [
                    Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                    child: Row(
                        children: [
                        _HeaderChip(text: 'Antes de empezar'),
                        const Spacer(),
                        _CloseBtn(onTap: () => Navigator.of(context).maybePop()),
                        ],
                    ),
                    ),

                    Expanded(
                    child: Center(
                        child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1060),
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                            child: AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) {
                                final t = 0.45 + 0.35 * math.sin(_glowCtrl.value * 2 * math.pi);
                                return _NeonPanel(
                                glowIntensity: t,
                                // ====== scroll interno para evitar overflow ======
                                child: _PanelScroll(
                                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                                    child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        _FadeSlide(
                                        controller: _introCtrl,
                                        delay: 0.00,
                                        child: ShaderMask(
                                            shaderCallback: (r) => const LinearGradient(
                                            colors: [_blue, _neonCyan],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            ).createShader(r),
                                            child: const Text(
                                            '¿Cómo funcionan las opciones de respuesta?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: .2,
                                                color: Colors.white,
                                            ),
                                            ),
                                        ),
                                        ),
                                        const SizedBox(height: 8),
                                        _FadeSlide(
                                        controller: _introCtrl,
                                        delay: 0.04,
                                        child: const Text(
                                            'Elige la opción que mejor diga qué tanto te gusta o te interesa. '
                                            'No hay respuestas buenas o malas: ¡es sobre ti!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.35,
                                            color: Colors.black87,
                                            ),
                                        ),
                                        ),
                                        const SizedBox(height: 22),

                                        _FadeSlide(
                                        controller: _introCtrl,
                                        delay: 0.08,
                                        child: wide
                                            ? Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: const [
                                                    // CAMBIO: emoji ❤️ también en web
                                                    Expanded(child: _OptionTile(
                                                    color: Color(0xFF3FA9F5),
                                                    emoji: '❤️',
                                                    title: 'ME ENCANTA',
                                                    line: 'Lo disfruto muchísimo y me hace feliz.',
                                                    example: 'Me ENCANTA ayudar a mis amigos con proyectos creativos.',
                                                    )),
                                                    SizedBox(width: 16),
                                                    Expanded(child: _OptionTile(
                                                    color: Color(0xFF64B5F6),
                                                    emoji: '💡',
                                                    title: 'ME INTERESA',
                                                    line: 'Me da curiosidad y quiero saber más.',
                                                    example: 'Me INTERESA aprender cómo funcionan las apps y sitios web.',
                                                    )),
                                                    SizedBox(width: 16),
                                                    Expanded(child: _OptionTile(
                                                    color: Color(0xFF90CAF9),
                                                    emoji: '🙅‍♂️',
                                                    title: 'NO ME GUSTA',
                                                    line: 'No es lo mío, prefiero evitarlo.',
                                                    example: 'NO ME GUSTA hablar en frente de muchas personas.',
                                                    )),
                                                ],
                                                )
                                            : const Column(
                                                children: [
                                                    // NUEVO: mismo alto mínimo para las tres cards en responsive
                                                    _OptionTile(
                                                    color: Color(0xFF3FA9F5),
                                                    emoji: '❤️',
                                                    title: 'ME ENCANTA',
                                                    line: 'Lo disfruto muchísimo y me hace feliz.',
                                                    example: 'Me ENCANTA ayudar a mis amigos con proyectos creativos.',
                                                    minHeight: 260,
                                                    ),
                                                    SizedBox(height: 14),
                                                    _OptionTile(
                                                    color: Color(0xFF64B5F6),
                                                    emoji: '💡',
                                                    title: 'ME INTERESA',
                                                    line: 'Me da curiosidad y quiero saber más.',
                                                    example: 'Me INTERESA aprender cómo funcionan las apps y sitios web.',
                                                    minHeight: 260,
                                                    ),
                                                    SizedBox(height: 14),
                                                    _OptionTile(
                                                    color: Color(0xFF90CAF9),
                                                    emoji: '🙅‍♂️',
                                                    title: 'NO ME GUSTA',
                                                    line: 'No es lo mío, prefiero evitarlo.',
                                                    example: 'NO ME GUSTA hablar en frente de muchas personas.',
                                                    minHeight: 260,
                                                    ),
                                                ],
                                                ),
                                        ),

                                        const SizedBox(height: 20),
                                        _FadeSlide(
                                        controller: _introCtrl,
                                        delay: 0.14,
                                        child: const _TipsChips(),
                                        ),

                                        const SizedBox(height: 22),
                                        _FadeSlide(
                                        controller: _introCtrl,
                                        delay: 0.20,
                                        child: Column(
                                            children: [
                                            SizedBox(
                                                width: 320,
                                                child: ElevatedButton.icon(
                                                onPressed: () => Navigator.of(context).maybePop(),
                                                icon: const Icon(Icons.play_circle_fill_rounded),
                                                label: const Text(
                                                    '¡Listo! Empezar',
                                                    style: TextStyle(fontWeight: FontWeight.w800),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: _blue,
                                                    foregroundColor: Colors.white,
                                                    elevation: 2,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    ),
                                                ),
                                                ),
                                            ),
                                            TextButton(
                                                onPressed: () => Navigator.of(context).maybePop(),
                                                child: const Text(
                                                'Saltar por ahora',
                                                style: TextStyle(
                                                    color: _blueDark,
                                                    fontWeight: FontWeight.w600,
                                                ),
                                                ),
                                            ),
                                            ],
                                        ),
                                        ),
                                    ],
                                    ),
                                ),
                                );
                            },
                            ),
                        ),
                        ),
                    ),
                    ),
                ],
                ),
            ],
            ),
        ),
        );
    }
    }

    // =================== OPTION TILE (limpio + ejemplo colapsable) ===================
    class _OptionTile extends StatefulWidget {
    const _OptionTile({
        required this.color,
        required this.emoji,
        required this.title,
        required this.line,
        required this.example,
        this.minHeight, // NUEVO: alto mínimo opcional para igualar cards
    });

    final Color color;
    final String emoji;
    final String title;
    final String line;
    final String example;
    final double? minHeight; // NUEVO

    @override
    State<_OptionTile> createState() => _OptionTileState();
    }

    class _OptionTileState extends State<_OptionTile> with SingleTickerProviderStateMixin {
    bool _open = false;
    late final AnimationController _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    @override
    void dispose() {
        _floatCtrl.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final borderColor = widget.color.withOpacity(.58);

        // NUEVO: ConstrainedBox para aplicar minHeight uniforme cuando se pida
        return ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x221976D2)),
            boxShadow: const [BoxShadow(color: Color(0x13000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, __) {
                    final y = 2 * math.sin(_floatCtrl.value * 2 * math.pi);
                    return Transform.translate(
                    offset: Offset(0, y),
                    child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [widget.color.withOpacity(.18), Colors.white]),
                        boxShadow: [BoxShadow(color: widget.color.withOpacity(.30), blurRadius: 10, spreadRadius: 1)],
                        border: Border.all(color: borderColor, width: 3),
                        ),
                        child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 36))),
                    ),
                    );
                },
                ),
                const SizedBox(height: 10),
                Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.2, fontWeight: FontWeight.w900, color: _blueDark),
                ),
                const SizedBox(height: 6),
                Text(
                widget.line,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.6, height: 1.26, color: Colors.black87),
                ),

                const SizedBox(height: 8),
                InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _open = !_open),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                    color: _bubbleBG,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x221976D2)),
                    ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18, color: _blueDark),
                        const SizedBox(width: 6),
                        const Text('Ver ejemplo', style: TextStyle(color: _blueDark, fontWeight: FontWeight.w700)),
                    ],
                    ),
                ),
                ),

                AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: _bubbleBG,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x221976D2)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: _blueDark),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                            widget.example,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.3, height: 1.26, color: _blueDark),
                            ),
                        ),
                        ],
                    ),
                    ),
                ),
                crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                ),
            ],
            ),
        ),
        );
    }
    }

    // =================== TIPS (chips compactos) ===================
    class _TipsChips extends StatelessWidget {
    const _TipsChips();

    @override
    Widget build(BuildContext context) {
        return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: const [
            _TipChip('Responde con sinceridad.'),
            _TipChip('Piensa en la vida real.'),
            _TipChip('Si dudas, elige lo que más se acerque.'),
        ],
        );
    }
    }

    class _TipChip extends StatelessWidget {
    const _TipChip(this.text);
    final String text;

    @override
    Widget build(BuildContext context) {
        return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x221976D2)),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Icon(Icons.check_circle, size: 18, color: _blue),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
            ],
        ),
        );
    }
    }

    // =================== Panel/Marco Neón ===================
    class _NeonPanel extends StatelessWidget {
    const _NeonPanel({required this.child, required this.glowIntensity});
    final Widget child;
    final double glowIntensity;

    @override
    Widget build(BuildContext context) {
        return CustomPaint(
        painter: _NeonFramePainter(glowIntensity: glowIntensity),
        child: Container(padding: const EdgeInsets.all(12), child: child),
        );
    }
    }

    class _NeonFramePainter extends CustomPainter {
    _NeonFramePainter({required this.glowIntensity});
    final double glowIntensity;

    @override
    void paint(Canvas canvas, Size size) {
        final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
        );

        final glowPaint = Paint()
        ..color = _neonCyan.withOpacity(0.22 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.outer, 9);

        final stroke = Paint()
        ..color = _blue.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

        final inner = Paint()
        ..color = _neonCyan.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

        canvas.drawRRect(rect, glowPaint);
        canvas.drawRRect(rect, stroke);
        canvas.drawRRect(rect.deflate(6), inner);
    }

    @override
    bool shouldRepaint(covariant _NeonFramePainter oldDelegate) =>
        oldDelegate.glowIntensity != glowIntensity;
    }

    // =================== Encabezado y cierre ===================
    class _HeaderChip extends StatelessWidget {
    const _HeaderChip({required this.text});
    final String text;

    @override
    Widget build(BuildContext context) {
        return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: _bubbleBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x221976D2)),
        ),
        child: Row(
            children: [
            const Icon(Icons.auto_awesome, color: _blueDark, size: 18),
            const SizedBox(width: 6),
            Text(
                text,
                style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _blueDark,
                ),
            ),
            ],
        ),
        );
    }
    }

    class _CloseBtn extends StatelessWidget {
    const _CloseBtn({required this.onTap});
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x221976D2)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: const Icon(Icons.close_rounded, color: _blueDark),
        ),
        );
    }
    }

    // =================== Anim util & fondo estrellitas ===================
    class _FadeSlide extends StatelessWidget {
    const _FadeSlide({required this.controller, required this.child, required this.delay});
    final AnimationController controller;
    final Widget child;
    final double delay;

    @override
    Widget build(BuildContext context) {
        final start = delay;
        final end = (delay + 0.55).clamp(0.0, 1.0);
        final curved = CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOut));
        return FadeTransition(
        opacity: curved,
        child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(curved),
            child: child,
        ),
        );
    }
    }

    class _StarDust extends StatelessWidget {
    const _StarDust({this.opacity = .03, this.count = 60});
    final double opacity;
    final int count;

    @override
    Widget build(BuildContext context) => CustomPaint(painter: _StarPainter(opacity: opacity, count: count));
    }

    class _StarPainter extends CustomPainter {
    _StarPainter({required this.opacity, required this.count});
    final double opacity; final int count;
    final rnd = math.Random(42);
    @override
    void paint(Canvas canvas, Size size) {
        final p = Paint()..color = _blueDark.withOpacity(opacity);
        for (int i = 0; i < count; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = rnd.nextDouble() * size.height;
        canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.9 + 0.3, p);
        }
    }
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
    }

    // ======= Wrapper de scroll interno para el panel (ya agregado) =======
    class _PanelScroll extends StatelessWidget {
    const _PanelScroll({required this.child, required this.padding});
    final Widget child;
    final EdgeInsets padding;

    @override
    Widget build(BuildContext context) {
        return LayoutBuilder(
        builder: (ctx, cons) {
            return SingleChildScrollView(
            padding: padding,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                minWidth: cons.maxWidth,
                ),
                child: child,
            ),
            );
        },
        );
    }
    }

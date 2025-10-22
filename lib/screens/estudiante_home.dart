// estudiante_home.dart
import 'dart:ui' show ImageFilter;              // blur para botón glass
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

// >>> NUEVO: importa la pantalla explicativa (misma carpeta /screens)
import 'como_calificar_screen.dart';

const _blue     = Color(0xFF1976D2);
const _blueDark = Color(0xFF0D47A1);
const _bubbleBG = Color(0xFFF1F8FF);

class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome>
    with SingleTickerProviderStateMixin {
  String nombre = '';
  String grado  = '';
  String edad   = '';

  late final AnimationController _zoom =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      nombre = p.getString('nombre') ?? 'Estudiante';
      grado  = p.getString('grado')  ?? 'N/A';
      edad   = p.getString('edad')   ?? 'N/A';
    });
  }

  String _tipoTest(String g) {
    final n = int.tryParse(g) ?? 0;
    if (n == 9)  return 'Test para Recomendación de un Técnico';
    if (n >= 10) return 'Test para Recomendación de una Carrera';
    return 'Test Vocacional';
  }

  // ---------------------------- UI ----------------------------
  @override
  Widget build(BuildContext context) {
    final tipoTest = _tipoTest(grado);
    final wide     = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // mini botón (glass)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Spacer(),
                        TinyGlassButton(
                          icon: Icons.history_edu_rounded,
                          tooltip: 'Historial',
                          onTap: () {
                            final n = int.tryParse(grado) ?? 0;
                            if (n == 9) {
                              Navigator.pushNamed(context, '/historial-test9');
                            } else if (n >= 10) {
                              Navigator.pushNamed(context, '/historial-test-10-11');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configura tu grado para ver el historial.'),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        TinyGlassButton(
                          icon: Icons.logout,
                          tooltip: 'Cerrar sesión',
                          onTap: () => Navigator.pushReplacementNamed(context, '/'),
                        ),
                      ],
                    ),
                  ),

                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _HeaderSection(
                      nombre: nombre,
                      edad: edad,
                      grado: grado,
                      tipoTest: tipoTest,
                      controller: _zoom,
                      wide: wide,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // botón principal (fancy)
                  Center(
                    child: FancyPrimaryButton(
                      text: (grado == '9')
                          ? 'Iniciar Test Grado 9'
                          : 'Iniciar Test Grado $grado',
                      onTap: () {
                        // >>> NUEVO: primero mostramos la explicación;
                        // al cerrarla, navegamos al test correspondiente.
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const ComoCalificarScreen(),
                                fullscreenDialog: true, // modal de pantalla completa
                              ),
                            )
                            .then((_) {
                              if (!mounted) return;
                              final ruta = (grado == '9')
                                  ? '/test_grado9'
                                  : '/test_grado_10_11';
                              Navigator.pushNamed(context, ruta);
                            });
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Título de sección para ordenar visualmente
                  const _SectionTitle(
                    title: 'Conoce el test',
                    subtitle: 'Todo lo esencial en un vistazo',
                  ),

                  const SizedBox(height: 8),

                  _InfoCards(wide: wide),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//                       HEADER SECTION
// ============================================================
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.nombre,
    required this.edad,
    required this.grado,
    required this.tipoTest,
    required this.controller,
    required this.wide,
  });

  final String nombre, edad, grado, tipoTest;
  final AnimationController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final greetSize = wide ? 38.0 : 26.0;
    final imgSize   = wide ? 220.0 : 160.0;

    // avatar
    Widget avatar = ClipOval(
      child: Container(
        width: imgSize,
        height: imgSize,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.04)
              .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
          child: Image.asset('assets/nino_home.png', fit: BoxFit.contain),
        ),
      ),
    );

    // texto + chips
    Widget textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Hola, ${nombre.toLowerCase()}!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: greetSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ],
            )),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.cake,  'Edad: $edad'),
            _chip(Icons.grade, 'Grado: $grado'),
            _chip(Icons.star,  tipoTest),
          ],
        ),
      ],
    );

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: wide
            ? Row(children: [
                Expanded(child: textBlock),
                const SizedBox(width: 12),
                avatar,
              ])
            : Column(children: [
                avatar,
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: textBlock),
              ]),
      ),
    );
  }

  Widget _chip(IconData ic, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: _bubbleBG, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 16, color: _blueDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text,
                  softWrap: true,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ),
          ],
        ),
      );
}

// ============================================================
//                     INFO CARDS GRID
// ============================================================
class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.wide});
  final bool wide;

  @override
    Widget build(BuildContext context) {
          final items = <_CardData>[
    const _CardData(Icons.question_answer, '¿Qué es un Test Vocacional?',
        'Herramienta para descubrir tus intereses, fortalezas y preferencias y orientar tu futuro académico.'),
    const _CardData(Icons.settings_suggest_rounded, 'Metodología RIASEC',
        'Modelo RIASEC: Realista, Investigativa, Artística, Social, Emprendedora y Convencional.'),
    const _CardData(Icons.compare_arrows_rounded, '¿Cómo funciona?',
        'Respondes 40 preguntas. Analizamos tus respuestas y te recomendamos una modalidad.'),
    const _CardData(Icons.emoji_events, 'Beneficios',
        '• Identificas tus gustos\n• Tomas decisiones seguras\n• Recibes orientación\n• Evitas equivocaciones'),
  ];

    final cross = wide ? 2 : 1;
    const cardHeight = 150.0; // altura fija para filas compactas y sin huecos

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          mainAxisExtent: cardHeight, // clave: filas uniformes, se ve ordenado
        ),
        itemBuilder: (context, i) => _card(items[i].icon, items[i].title, items[i].desc),
      ),
    );
  }

  Widget _card(IconData ic, String title, String desc) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: _blue, radius: 24, child: Icon(ic, color: Colors.white, size: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.2, height: 1.28),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CardData {
  final IconData icon;
  final String title;
  final String desc;
  const _CardData(this.icon, this.title, this.desc);
}

// ============================================================
//      FANCY PRIMARY BUTTON (gradiente animado azul-turquesa)
// ============================================================
  class FancyPrimaryButton extends StatefulWidget {
  const FancyPrimaryButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  State<FancyPrimaryButton> createState() => _FancyPrimaryButtonState();
}

class _FancyPrimaryButtonState extends State<FancyPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  bool _hover = false;
  bool _pressed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp:   (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;                    // 0..1
            final angle = t * 2 * math.pi;            // giro completo
            final begin = Alignment(math.cos(angle), math.sin(angle));
            final end   = Alignment(-math.cos(angle), -math.sin(angle));

            // Paleta fría satinada
            const c1 = Color(0xFF00B4DB);
            const c2 = Color(0xFF2196F3);
            const c3 = Color(0xFF64B5F6);
            final gradient = LinearGradient(
              begin: begin,
              end: end,
              colors: const [c1, c2, c3, c2],
              stops: const [0.0, 0.35, 0.7, 1.0],
            );

            // Glow “respirando”
            final glow = 12.0 + 8.0 * (0.5 + 0.5 * math.sin(angle));

            // Escala hover/press
            final scale = _pressed ? 0.98 : (_hover ? 1.02 : 1.0);

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fondo con gradiente animado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x802196F3),
                            blurRadius: glow,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            widget.text,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Brillo diagonal (gloss) que cruza el botón
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform.rotate(
                          angle: -0.45, // ~ -26°
                          child: FractionalTranslation(
                            translation: Offset(2 * t - 1, 0), // de -1 → 1
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withOpacity(0.00),
                                      Colors.white.withOpacity(0.45),
                                      Colors.white.withOpacity(0.00),
                                    ],
                                    stops: const [0, 0.5, 1],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// ============================================================
//          TINY GLASS BUTTON (vidrio azulado, ícono oscuro)
// ============================================================
class TinyGlassButton extends StatefulWidget {
  const TinyGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<TinyGlassButton> createState() => _TinyGlassButtonState();
}

class _TinyGlassButtonState extends State<TinyGlassButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Tooltip(
            message: widget.tooltip ?? '',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _hover
                      ? [const Color(0x662196F3), const Color(0x5500B4DB)]
                      : [const Color(0x442196F3), const Color(0x3300B4DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  if (_hover)
                    const BoxShadow(
                        color: Color(0x552196F3),
                        blurRadius: 12,
                        spreadRadius: 1)
                ],
                border: Border.all(color: Colors.white38, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Icon(widget.icon,
                      size: 22,
                      color: _hover
                          ? Colors.white
                          : const Color(0xFF0D47A1) /* azul oscuro */),
                ),
              ),
            ),
          ),
        ),
      );
}

// ============================================================
//                  SECTION TITLE (estético)
// ============================================================
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 22,
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: _blueDark,
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        color: Colors.black54,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

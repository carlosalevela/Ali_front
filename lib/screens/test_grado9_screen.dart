import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resultado_test9_screen.dart';
import 'estudiante_home.dart';
import '../services/api_service.dart';

class TestGrado9Page extends StatefulWidget {
  const TestGrado9Page({Key? key}) : super(key: key);

  @override
  State<TestGrado9Page> createState() => _TestGrado9PageState();
}

class _TestGrado9PageState extends State<TestGrado9Page>
    with TickerProviderStateMixin {
  // ----------- NUEVA PALETA (más suave)
  static const Color azulFondoSuave = Color(0xFF8DB9E4); // fondo base
  static const Color azulSeleccion   = Color(0xFFA7D8F5); // selección opción
  static const Color azulAcento      = Color(0xFF4FC3F7); // acento / barras

  // ---------------------- 57 preguntas completas
  final List<String> preguntas = [
    // COMERCIO — Emprendimiento y Fomento Empresarial (5)
    '¿Te gustaría aprender a organizar gastos, tareas y avances de un proyecto sencillo?',
    'En tu familia, colegio o barrio, ¿te gustaría identificar necesidades y pensar soluciones simples y prácticas?',
    '¿Te gustaría hablar con personas para entender qué necesitan o qué les gustaría comprar?',
    '¿Te animarías a explicar una idea en pocas palabras diciendo qué problema resuelve y a qué población va dirigida?',
    '¿Te gustaría crear una marca y usar redes, afiches o recomendaciones para dar a conocer una idea?',

    // COMERCIO — Diseño Gráfico (5)
    '¿Te gustaría crear diseños para redes sociales, afiches, logos o caricaturas?',
    '¿Te gustaría aprender a elegir colores, tipografías y orden para que un diseño se vea bien?',
    '¿Te gustaría aprender el manejo digital para generar archivos listos para imprimir y publicar?',
    '¿Te gustaría recibir comentarios y usarlos para mejorar tus diseños?',
    '¿Te gustaría diseñar la imagen completa de una marca o empresa (colores, logo y estilo)?',

    // COMERCIO — Contabilidad y Finanzas (5)
    '¿Te gustaría aprender a llevar los movimientos financieros (entradas y salidas de dinero) usando documentos o soportes contables?',
    '¿Te gustaría elaborar documentos o soportes contables (como recibos, cuentas o facturas) con cuidado y evitando equivocarte?',
    '¿Te gustaría aprender a guardar papeles y archivos en orden para encontrarlos rápido?',
    '¿Te gustaría revisar resúmenes de ingresos y gastos para entender si un proyecto va bien o mal?',
    '¿Te gustaría cuidar la confidencialidad de la información financiera de otras personas o negocios?',

    // INDUSTRIAL — Mantenimiento de Hardware y Software (5)
    '¿Te gustaría aprender a descubrir por qué un computador no funciona y seguir pasos para solucionarlo?',
    '¿Te gustaría aprender a instalar programas y dejar un computador listo para usar?',
    '¿Te gustaría aprender a armar y desarmar un computador con cuidado para no dañar piezas?',
    '¿Te gustaría aprender a conectar un computador a internet por cable o Wi-Fi y resolver problemas de conexión?',
    '¿Te gustaría aprender a registrar lo que hiciste y hacer copias de seguridad para no perder información?',

    // INDUSTRIAL — Electricidad y Electrónica (5)
    '¿Te gustaría aprender sobre circuitos y entender cómo hacen funcionar luces o equipos?',
    '¿Te gustaría aprender a instalar cables y enchufes siguiendo normas de seguridad?',
    '¿Te interesa aprender a usar herramientas para revisar si hay corriente de forma segura?',
    '¿Te gustaría aprender a armar y probar paneles o equipos siguiendo un paso a paso?',
    '¿Te gustaría aprender a protegerte (guantes, gafas y más) para experimentar con proyectos eléctricos de forma segura y sentirte confiado al hacerlo?',

    // INDUSTRIAL — Robótica (5)
    '¿Te gustaría programar una tarjeta que haga prender luces o mover motores?',
    '¿Te llama la atención aprender programación paso a paso para automatizar movimientos o procesos con controladores básicos?',
    '¿Te gustaría probar tu proyecto, encontrar y corregir errores y mejorarlo hasta que funcione como lo imaginaste?',
    '¿Te gusta dibujar y explicar tu proyecto para que otros lo entiendan?',
    '¿Te emociona la idea de aprender a crear un robot que resuelva un reto real en el colegio o tu comunidad y mostrarlo en ferias o concursos?',

    // AGROPECUARIA — Agroindustria (6)
    '¿Te gustaría aprender a cuidar plantas desde la semilla (siembra, riego, compost) y ver cómo crecen los cultivos?',
    '¿Te interesa conocer cuidados básicos de animales (alimentación, higiene y bienestar) de forma responsable y segura?',
    '¿Te motiva proteger la naturaleza cuidando agua, suelo y bosques con prácticas sencillas y útiles?',
    '¿Te gustaría aprender técnicas seguras para producir y transformar alimentos (higiene, conservación y calidad)?',
    '¿Te gustaría realizar actividades al aire libre, trabajando en huertas o granjas escolares y observando el entorno natural?',
    '¿Te gustaría participar en la elaboración de alimentos (recetas, medidas, empaque simple) y probar los resultados con tus compañeros?',

    // ACADÉMICO — Científico/Humanista (6)
    '¿Te gusta hacer preguntas y proponer una idea posible (hipótesis) para explicarlas?',
    '¿Te interesa hacer experimentos simples, anotar resultados y compararlos?',
    '¿Te gustaría explicar con tus palabras fenómenos de Física, Química y Biología usando ejemplos cercanos, como por qué frena una bici, cómo el jabón quita la grasa o cómo cicatriza un raspón?',
    '¿Te gustaría usar matemáticas (porcentajes, gráficas, medidas) para resolver situaciones de la vida cotidiana?',
    '¿Te animas a escribir un texto corto y presentar tus ideas con respeto?',
    '¿Te gustaría resolver retos ambientales del colegio o tu barrio (ahorro de agua, reciclaje, calidad del aire) usando experimentos y tecnología?',

    // PROMOCIÓN SOCIAL — Primera Infancia (5)
    '¿Te gustaría aprender el papel de la salud en la primera infancia (rutinas de higiene, alimentación y sueño) para cuidar mejor a niños y niñas?',
    '¿Te interesa aprender a planear actividades según la edad (juegos, cuentos, arte) que apoyen su desarrollo?',
    '¿Te gustaría trabajar junto a familias y docentes para promover hábitos saludables (higiene, alimentación, movimiento)?',
    '¿Te interesa aprender primeros auxilios básicos para niños y niñas y saber qué hacer en situaciones comunes?',
    '¿Te gustaría promover el cuidado del entorno con rutinas simples (ahorro de agua, reciclaje) y explicar a los niños cómo eso protege su salud?',

    // PROMOCIÓN SOCIAL — Seguridad y Salud en el Trabajo (5)
    '¿Te gustaría aprender a que los espacios del colegio sean más seguros para todos?',
    '¿Te gustaría aprender a reconocer cosas que pueden causar accidentes (piso mojado, objetos en el suelo, cables tirados) y decir qué hacer para evitarlos?',
    '¿Te gustaría proponer acciones simples para cuidarnos (secar un derrame, despejar pasillos, ordenar cables) y explicar al grupo cómo hacerlo?',
    '¿Te gustaría llenar registros sencillos (listas de chequeo, notas) de forma ordenada y sin errores?',
    '¿Te gustaría participar en prácticas (simulacros, primeros auxilios básicos, recorridos de verificación) apoyando a las personas y anotando lo observado?',

    // PROMOCIÓN SOCIAL — Promoción de la Salud (5)
    '¿Te gusta participar en campañas para mejorar hábitos saludables (agua, actividad física, alimentación)?',
    '¿Te gustaría explicar temas de salud con palabras simples a niños, jóvenes o adultos?',
    '¿Te gustaría hacer talleres o jornadas en tu barrio o colegio para hablar de salud?',
    '¿Te gustaría anotar de forma sencilla lo que se hizo (actividad, fecha) y luego revisar con tu grupo si ayudó a mejorar un hábito o cuidado de salud?',
    '¿Te ves estudiando o trabajando en proyectos de salud o trabajo social?',
  ];

  final Map<String, String> opciones = {
    'A': 'Me gusta',
    'B': 'Me interesa',
    'C': 'No me gusta',
  };

  final Map<String, String> respuestas = {};
  int preguntaActual = 0;
  bool mostrarModal = false;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  // ---------- PERSISTENCIA
  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('grado9_pregunta_actual') ?? 0;
    final savedResp = prefs.getString('grado9_respuestas');

    // Protege índice por si cambió el número total de preguntas
    final nuevoIndex = savedIndex.clamp(0, preguntas.length - 1);

    setState(() {
      preguntaActual = nuevoIndex;
    });

    if (savedResp != null) {
      final Map<String, dynamic> respDecoded = jsonDecode(savedResp);
      setState(() {
        respuestas.addAll(respDecoded.map((k, v) => MapEntry(k, v.toString())));
      });
    }
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grado9_pregunta_actual', preguntaActual);
    await prefs.setString('grado9_respuestas', jsonEncode(respuestas));
  }

  // ---------- NAVEGACIÓN
  void siguientePregunta() {
    if (preguntaActual < preguntas.length - 1) {
      setState(() => preguntaActual++);
      _guardarProgreso();
    } else {
      setState(() => mostrarModal = true);
    }
  }

  void anteriorPregunta() {
    if (preguntaActual > 0) {
      setState(() => preguntaActual--);
      _guardarProgreso();
    }
  }

    Future<void> enviarTest() async {
  // Mapa esperado por el backend: pregunta_1..pregunta_57 -> 'A'|'B'|'C'
  final respuestasFinales = {
    for (var i = 0; i < preguntas.length; i++)
      'pregunta_${i + 1}': respuestas['pregunta_$i'] ?? ''
  };

  // Llama al servicio centralizado (lee token/userId desde SharedPreferences)
  final api = ApiService();
  final resp = await api.enviarTestGrado9(respuestasFinales);

  if (resp['success'] == true) {
    // Limpia progreso local del cuestionario en este dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('grado9_pregunta_actual');
    await prefs.remove('grado9_respuestas');

    // Extrae el “resultado” devuelto por el backend
    final data = resp['resultado'];
    // si tu backend devuelve {"resultado": "..."}:
    final resultado = (data is Map && data['resultado'] != null)
        ? data['resultado'].toString()
        : data.toString();

    // Calcula porcentajes locales para la pantalla de resultado
    final contador = {'A': 0, 'B': 0, 'C': 0};
    for (final v in respuestas.values) {
      if (contador.containsKey(v)) contador[v] = contador[v]! + 1;
    }
    final total = respuestas.isEmpty ? 1 : respuestas.length;
    final porcentajes = {
      'Me gusta': (contador['A']! * 100 / total),
      'Me interesa': (contador['B']! * 100 / total),
      'No me gusta': (contador['C']! * 100 / total),
    };

    // Navega al resultado
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoTest9Screen(
          resultado: resultado,
          porcentajes: porcentajes,
          icono: Icons.lightbulb,
          color: azulFondoSuave,
        ),
      ),
    );
  } else {
    // Muestra error del servicio
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resp['message'] ?? 'No se pudo enviar el test')),
    );
  }
}
  // #################################### UI
  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    final progreso = respuestas.length / preguntas.length;

    if (mostrarModal) {
      Future.microtask(() {
        setState(() => mostrarModal = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('¿Enviar respuestas?'),
            content: const Text(
                'Una vez enviadas no podrás modificarlas. ¿Estás seguro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  enviarTest();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondoSuave,
                    shape: const StadiumBorder()),
                child: const Text('Enviar'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: azulFondoSuave,
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedBackground()),
          // -------- Overlay degradado animado ------------
          const Positioned.fill(child: _GradientOverlay()),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EstudianteHome()),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: 1.0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PROGRESO
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progreso,
                            backgroundColor: azulSeleccion.withOpacity(.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                azulAcento),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: azulAcento,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Pregunta ${preguntaActual + 1} de ${preguntas.length}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          pregunta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 30),

                        // OPCIONES
                        ...opciones.entries.map((opcion) {
                          final estaSeleccionado =
                              respuestaSeleccionada == opcion.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() => respuestas[
                                      'pregunta_$preguntaActual'] =
                                  opcion.key);
                              _guardarProgreso();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: estaSeleccionado
                                    ? azulSeleccion
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: estaSeleccionado
                                        ? azulAcento
                                        : azulSeleccion.withOpacity(0.3),
                                    width: 2),
                                boxShadow: [
                                  if (estaSeleccionado)
                                    BoxShadow(
                                      color: azulSeleccion.withOpacity(.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: estaSeleccionado
                                        ? Colors.white
                                        : azulSeleccion,
                                    child: Text(
                                      opcion.key,
                                      style: TextStyle(
                                          color: estaSeleccionado
                                              ? azulSeleccion
                                              : Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      opcion.value,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: estaSeleccionado
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: estaSeleccionado
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 26),

                        // BOTONES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (preguntaActual > 0)
                              _BotonRounded(
                                texto: 'Anterior',
                                color: Colors.grey.shade500,
                                onTap: anteriorPregunta,
                              ),
                            _BotonRounded(
                              texto: preguntaActual == preguntas.length - 1
                                  ? 'Finalizar'
                                  : 'Siguiente',
                              color: azulAcento,
                              enabled: respuestaSeleccionada.isNotEmpty,
                              onTap: siguientePregunta,
                            ),
                          ],
                        )
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
}

// BOTÓN ANIMADO
class _BotonRounded extends StatefulWidget {
  final String texto;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _BotonRounded(
      {required this.texto,
      required this.color,
      required this.onTap,
      this.enabled = true});

  @override
  State<_BotonRounded> createState() => _BotonRoundedState();
}

class _BotonRoundedState extends State<_BotonRounded>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        lowerBound: 0.0,
        upperBound: 0.05);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _ctrl.value;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.enabled ? widget.onTap : null,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(widget.texto,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

// FONDO ANIMADO (ondas + íconos)
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrlOndas =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);
  late final Animation<double> _shift =
      Tween<double>(begin: -40, end: 40).animate(
          CurvedAnimation(parent: _ctrlOndas, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrlOndas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrlOndas,
      builder: (_, __) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _WavePainter(offset: _shift.value, color: Colors.white24),
            ),
          ),
          Positioned.fill(
            top: 60,
            child: CustomPaint(
              painter: _WavePainter(
                  offset: _shift.value * .6, color: Colors.white30),
            ),
          ),
          const _IconFloat(top: 100, left: 40, icon: Icons.menu_book),
          const _IconFloat(bottom: 120, right: 60, icon: Icons.computer),
          const _IconFloat(top: 220, right: 20, icon: Icons.school),
          const _IconFloat(bottom: 40, left: 30, icon: Icons.pedal_bike),
        ],
      ),
    );
  }
}

class _IconFloat extends StatelessWidget {
  final double? top, left, right, bottom;
  final IconData icon;
  const _IconFloat(
      {this.top, this.left, this.right, this.bottom, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Icon(icon, size: 48, color: Colors.white.withOpacity(0.08)),
    );
  }
}

// ---------- OVERLAY DEGRADADO (sutil animación de opacidad)
class _GradientOverlay extends StatefulWidget {
  const _GradientOverlay();
  @override
  State<_GradientOverlay> createState() => _GradientOverlayState();
}

class _GradientOverlayState extends State<_GradientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.05 + 0.1 * _ctrl.value),
              Colors.white.withOpacity(0.12 + 0.05 * _ctrl.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// PINTOR DE ONDAS
class _WavePainter extends CustomPainter {
  final double offset;
  final Color color;
  _WavePainter({required this.offset, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height * 0.7 + offset)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.6 + offset,
          size.width * 0.5, size.height * 0.7 + offset)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8 + offset,
          size.width, size.height * 0.7 + offset)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.offset != offset;
}

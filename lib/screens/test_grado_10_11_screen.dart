import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resultado_test_10_11_screen.dart';
import 'estudiante_home.dart';
import 'dart:math' as math; // (ok dejarlo)
import '../services/api_service.dart';

class TestGrado1011Screen extends StatefulWidget {
  const TestGrado1011Screen({Key? key}) : super(key: key);

  @override
  State<TestGrado1011Screen> createState() => _TestGrado1011ScreenState();
}

class _TestGrado1011ScreenState extends State<TestGrado1011Screen>
    with TickerProviderStateMixin {
  // ------------------ LÓGICA (misma lista) ------------------
  final List<String> preguntas = [
    '¿Te gustaría aprender cómo funciona el cuerpo humano para ayudar a otros?',
    '¿Disfrutas cuidar a personas enfermas o vulnerables?',
    '¿Te interesa la biología y la investigación médica?',
    '¿Te llama la atención trabajar en hospitales o clínicas?',
    '¿Te interesan los sistemas mecánicos, eléctricos o industriales?',
    '¿Disfrutas resolver problemas técnicos de manera lógica?',
    '¿Te gustaría diseñar estructuras, objetos o soluciones para el mundo real?',
    '¿Te apasionan las matemáticas y su aplicación práctica?',
    '¿Te gustaría liderar una empresa o equipo de trabajo?',
    '¿Te interesa aprender cómo funcionan las organizaciones?',
    '¿Te atrae el mundo de los negocios, ventas y estrategias?',
    '¿Disfrutas planificar y tomar decisiones importantes?',
    '¿Te interesa entender cómo piensan y sienten las personas?',
    '¿Te gustaría ayudar a otros a resolver sus conflictos emocionales?',
    '¿Disfrutas escuchar y comprender a quienes te rodean?',
    '¿Te atrae analizar el comportamiento humano en diferentes contextos?',
    '¿Te gustaría defender los derechos de las personas?',
    '¿Te interesa la justicia, las leyes y su aplicación?',
    '¿Disfrutas debatir y argumentar con lógica?',
    '¿Te atrae la idea de trabajar en juzgados o asesorías legales?',
    '¿Te gustaría enseñar y compartir tus conocimientos con otros?',
    '¿Te interesa guiar procesos de aprendizaje en niños o jóvenes?',
    '¿Disfrutas explicar ideas de manera clara y creativa?',
    '¿Sientes vocación por la formación de nuevas generaciones?',
    '¿Te gustaría crear programas, aplicaciones o videojuegos?',
    '¿Te interesa la inteligencia artificial o el desarrollo web?',
    '¿Disfrutas resolver problemas de lógica a través del código?',
    '¿Te atrae la idea de trabajar en tecnología e innovación?',
    '¿Te interesa el manejo del dinero y las finanzas personales o empresariales?',
    '¿Disfrutas organizar información numérica o contable?',
    '¿Te gustaría trabajar en bancos, oficinas o asesorías financieras?',
    '¿Te sientes cómodo/a siguiendo normas y procedimientos exactos?',
    '¿Te gusta expresarte a través de imágenes, colores y formas?',
    '¿Te gustaría crear campañas visuales o publicitarias?',
    '¿Disfrutas usar programas de diseño como Photoshop o Illustrator?',
    '¿Te interesa el mundo del arte digital y la creatividad visual?',
    '¿Te interesa investigar fenómenos de la naturaleza como el clima o los ecosistemas?',
    '¿Disfrutas hacer experimentos científicos en laboratorio o campo?',
    '¿Te gustaría trabajar como biólogo, físico o químico?',
    '¿Te atrae el pensamiento crítico y la búsqueda de evidencias?',
  ];

  // 🔁 Escala a 3 opciones (alineada con tu backend: A/B/C o texto)
  final Map<String, String> opciones = const {
    'A': 'Me encanta',
    'B': 'Me interesa',
    'C': 'No me gusta',
  };

  final Map<String, String> respuestas = {};
  int preguntaActual = 0;
  bool mostrarModal = false;

  // Colores (sin cambiar nombres)
  Color azulFondo = const Color(0xFF8db9e4);
  Color azulSeleccion = const Color(0xFF59bde9);

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      preguntaActual = (prefs.getInt('pregunta_actual_1011') ?? 0)
          .clamp(0, preguntas.length - 1);
      for (int i = 0; i < preguntas.length; i++) {
        final respuesta = prefs.getString('respuesta_$i');
        if (respuesta != null) {
          respuestas['pregunta_$i'] = respuesta;
        }
      }
    });
  }

  Future<void> _guardarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pregunta_actual_1011', preguntaActual);
    // ✅ Guardar todas las respuestas por índice real, no por respuestas.length
    for (int i = 0; i < preguntas.length; i++) {
      final r = respuestas['pregunta_$i'];
      if (r != null) {
        await prefs.setString('respuesta_$i', r);
      }
    }
  }

  Future<void> _borrarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pregunta_actual_1011');
    for (int i = 0; i < preguntas.length; i++) {
      await prefs.remove('respuesta_$i');
    }
  }

  void siguientePregunta() {
    if (preguntaActual < preguntas.length - 1) {
      setState(() {
        preguntaActual++;
      });
      _guardarProgreso();
    } else {
      setState(() {
        mostrarModal = true;
      });
    }
  }

  void anteriorPregunta() {
    if (preguntaActual > 0) {
      setState(() {
        preguntaActual--;
      });
      _guardarProgreso();
    }
  }

  // *** Lógica de envío (igual a la tuya) ***
  void enviarTest() async {
    await _borrarProgreso();

    final respuestasTransformadas = <String, String>{};
    for (int i = 0; i < preguntas.length; i++) {
      final original = respuestas['pregunta_$i'];
      if (original != null) {
        respuestasTransformadas['pregunta_${i + 1}'] = original; // A/B/C
      }
    }

    try {
      final response =
          await ApiService().enviarTestGrado10y11(respuestasTransformadas);

      if (response['success'] == true) {
        final data = response['resultado']; // JSON/Map del backend
        final carrera = _extraerCarreraSugerida(data);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultadoTest1011Screen(
              respuestas: respuestasTransformadas,
              resultado: carrera,
            ),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar test: $e')),
      );
    }
  }

  // Helper (igual)
  String _extraerCarreraSugerida(dynamic data) {
    if (data is String) return data.trim();
    if (data is Map) {
      for (final k in [
        'carrera',
        'carrera_sugerida',
        'nombre_carrera',
        'resultado',
        'recomendacion',
        'recomendación',
        'tecnico',
        'tecnico_sugerido',
        'sugerencia',
        'label',
        'titulo',
        'nombre'
      ]) {
        final v = data[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      String? best;
      void walk(dynamic v) {
        if (v == null) return;
        if (v is String) {
          final t = v.trim();
          if (t.isNotEmpty &&
              t.length <= 60 &&
              !t.contains('{') &&
              !t.contains('[')) {
            best ??= t;
          }
        } else if (v is Map) {
          for (final e in v.values) walk(e);
        } else if (v is List) {
          for (final e in v) walk(e);
        }
      }

      walk(data);
      return (best ?? '').trim();
    }
    if (data is List) {
      for (final e in data) {
        final s = _extraerCarreraSugerida(e);
        if (s.isNotEmpty) return s;
      }
    }
    return 'Resultado no disponible';
  }

  // ------------------ DISEÑO (UI) ------------------
  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    final double progreso =
        preguntas.isEmpty ? 0 : (respuestas.length / preguntas.length);

    // Modal confirmación
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
                style: ElevatedButton.styleFrom(backgroundColor: azulFondo),
                child: const Text('Enviar'),
              ),
            ],
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: azulFondo,
      body: Stack(
        children: [
          // Fondo animado con íconos académicos
          const Positioned.fill(child: _AnimatedBackground()),

          // Botón volver
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EstudianteHome()),
                    );
                  },
                ),
              ),
            ),
          ),

          // Card central
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 640),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barra de progreso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progreso.clamp(0, 1),
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(azulFondo),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: azulFondo,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Título pregunta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pregunta ${preguntaActual + 1}',
                              style: TextStyle(
                                color: azulFondo,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'de ${preguntas.length}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Enunciado
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(.25),
                            ),
                          ),
                          child: Text(
                            pregunta,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Opciones (A/B/C)
                        ...opciones.entries.map((opcion) {
                          final estaSeleccionado =
                              respuestaSeleccionada == opcion.key;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                respuestas['pregunta_$preguntaActual'] =
                                    opcion.key;
                              });
                              _guardarProgreso();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(vertical: 7),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: estaSeleccionado
                                    ? azulSeleccion
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: estaSeleccionado
                                      ? azulSeleccion
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (estaSeleccionado)
                                    BoxShadow(
                                      color: azulSeleccion.withOpacity(.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: estaSeleccionado
                                        ? Colors.white
                                        : azulFondo,
                                    child: Text(
                                      opcion.key,
                                      style: TextStyle(
                                        color: estaSeleccionado
                                            ? azulSeleccion
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opcion.value,
                                      style: TextStyle(
                                        color: estaSeleccionado
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: estaSeleccionado
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 26),

                        // Navegación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (preguntaActual > 0)
                              ElevatedButton(
                                onPressed: anteriorPregunta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[500],
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 14),
                                ),
                                child: const Text('Anterior'),
                              ),
                            ElevatedButton(
                              onPressed: respuestaSeleccionada.isNotEmpty
                                  ? siguientePregunta
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: azulFondo,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    azulFondo.withOpacity(.35),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 14),
                              ),
                              child: Text(preguntaActual == preguntas.length - 1
                                  ? 'Finalizar'
                                  : 'Siguiente'),
                            ),
                          ],
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
}

// ------------------ Fondo animado (diseño) ------------------
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground({super.key});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _animation2 = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: [
            Positioned(
              top: 100 + _animation1.value,
              left: 40,
              child: Icon(
                Icons.menu_book,
                size: 48,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Positioned(
              bottom: 120 + _animation2.value,
              right: 60,
              child: Icon(
                Icons.computer,
                size: 48,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Positioned(
              top: 220 + _animation2.value,
              right: 20,
              child: Icon(
                Icons.school,
                size: 48,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: 40 + _animation1.value,
              left: 30,
              child: Icon(
                Icons.pedal_bike,
                size: 48,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        );
      },
    );
  }
}

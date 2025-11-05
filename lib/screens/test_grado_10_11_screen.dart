import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'resultado_test_10_11_screen.dart';
import 'estudiante_home.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

class TestGrado1011Screen extends StatefulWidget {
  const TestGrado1011Screen({Key? key}) : super(key: key);

  @override
  State<TestGrado1011Screen> createState() => _TestGrado1011ScreenState();
}

class _TestGrado1011ScreenState extends State<TestGrado1011Screen>
    with TickerProviderStateMixin {
  // ------------------ LÓGICA (sin cambios) ------------------
  final List<String> preguntas = [
    '¿Te gustaría aprender cómo funciona el cuerpo humano para ayudar a otros?',
    '¿Te gustaria cuidar a personas enfermas o vulnerables?',
    '¿Te interesa la biología y la investigación médica?',
    '¿Te llama la atención trabajar en hospitales o clínicas?',
    '¿Te interesan los sistemas mecánicos, eléctricos o industriales?',
    '¿Te gustaría resolver problemas técnicos de manera lógica?',
    '¿Te gustaría diseñar estructuras, objetos o soluciones para el mundo real?',
    '¿Te apasionan las matemáticas y su aplicación práctica?',
    '¿Te gustaría liderar una empresa o equipo de trabajo?',
    '¿Te interesa aprender cómo funcionan las organizaciones?',
    '¿Te gustaría conocer mas el mundo de los negocios, ventas y estrategias?',
    '¿Te gustaría planificar y tomar decisiones importantes?',
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
    '¿Te gustaría explicar ideas de manera clara y creativa?',
    '¿Sientes vocación por la formación de nuevas generaciones?',
    '¿Te gustaría crear programas, aplicaciones o videojuegos?',
    '¿Te interesa la inteligencia artificial o el desarrollo web?',
    '¿Te gustaría resolver problemas de lógica a través del código?',
    '¿Te atrae la idea de trabajar en tecnología e innovación?',
    '¿Te interesa el manejo del dinero y las finanzas personales o empresariales?',
    '¿Te gustaria organizar información numérica o contable?',
    '¿Te gustaría trabajar en bancos, oficinas o asesorías financieras?',
    '¿Te sientes cómodo/a siguiendo normas y procedimientos exactos?',
    '¿Te gusta expresarte a través de imágenes, colores y formas?',
    '¿Te gustaría crear campañas visuales o publicitarias?',
    '¿Te gustaría usar programas de diseño como Photoshop o Illustrator?',
    '¿Te interesa el mundo del arte digital y la creatividad visual?',
    '¿Te interesa investigar fenómenos de la naturaleza como el clima o los ecosistemas?',
    '¿Te gustaría hacer experimentos científicos en laboratorio o campo?',
    '¿Te gustaría trabajar como biólogo, físico o químico?',
    '¿Te atrae el pensamiento crítico y la búsqueda de evidencias?',
    '¿Te gustaría aprender primeros auxilios y actuar en emergencias?',
    '¿Te gustaría investigar nuevos tratamientos para enfermedades?',
    '¿Te gustaría construir prototipos o maquetas para probar ideas?',
    '¿Te interesa trabajar con energías renovables, robótica o automatización?',
    '¿Te gustaría organizar recursos y personas para que un proyecto salga bien?',
    '¿Te gustaría crear tu propio emprendimiento y gestionarlo?',
    '¿Te sientes cómodo/a escuchando a alguien y guardando confidencialidad?',
    '¿Te interesa aprender estrategias para mejorar el bienestar emocional de jóvenes?',
    '¿Te gustaría participar en debates o simulacros de juicio?',
    '¿Te gustaría analizar normas y proponer soluciones justas a problemas reales?',
    '¿Disfrutas preparar actividades creativas para explicar un tema?',
    '¿Te gustaría acompañar procesos de aprendizaje inclusivos y diversos?',
    '¿Te gustaría crear proyectos con programación, IoT o microcontroladores?',
    '¿Te interesa la ciberseguridad y proteger información en internet?',
    '¿Te gustaría llevar el registro de ingresos y gastos de forma ordenada?',
    '¿Te interesa aprender sobre presupuestos, costos e impuestos básicos?',
    '¿Te gustaría crear logos, tipografías o identidades visuales para marcas?',
    '¿Te gustaría diseñar contenido para redes sociales y campañas digitales?',
    '¿Te gustaría observar la naturaleza y anotar lo que ves para aprender?',
    '¿Te interesa el cuidado del medio ambiente mediante proyectos científicos?',
  ];

  final Map<String, String> opciones = const {
    'A': 'Me encanta',
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

  void enviarTest() async {
    await _borrarProgreso();
    final respuestasTransformadas = <String, String>{};
    for (int i = 0; i < preguntas.length; i++) {
      final original = respuestas['pregunta_$i'];
      if (original != null) {
        respuestasTransformadas['pregunta_${i + 1}'] = original;
      }
    }

    try {
      final response =
          await ApiService().enviarTestGrado10y11(respuestasTransformadas);

      if (response['success'] == true) {
        final data = response['resultado'];
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

  // ------------------ DISEÑO ------------------
  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    final double progreso =
        preguntas.isEmpty ? 0 : (respuestas.length / preguntas.length);

    if (mostrarModal) {
      Future.microtask(() {
        setState(() => mostrarModal = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _buildModernDialog(),
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con objetos académicos dispersos
          const Positioned.fill(child: _AcademicBackground()),

          // Card principal centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _buildQuestionCard(
                pregunta,
                respuestaSeleccionada,
                progreso,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      String pregunta, String respuestaSeleccionada, double progreso) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF93C5FD).withOpacity(0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withOpacity(0.10),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón de atrás y barra de progreso
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EstudianteHome()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _buildProgressBar(progreso)),
            ],
          ),

          const SizedBox(height: 24),

          // Pregunta
          _buildQuestionText(pregunta),

          const SizedBox(height: 24),

          // Opciones
          ...opciones.entries.map((opcion) {
            return _buildOptionButton(
              opcion.key,
              opcion.value,
              respuestaSeleccionada == opcion.key,
            );
          }).toList(),

          const SizedBox(height: 28),

          // Botones de navegación
          _buildNavigationButtons(respuestaSeleccionada),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progreso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pregunta ${preguntaActual + 1}/${preguntas.length}',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${(progreso * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: progreso.clamp(0.0, 1.0)),
            builder: (context, value, _) {
              return Stack(
                children: [
                  Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF93C5FD),
                            Color(0xFF60A5FA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF60A5FA).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionText(String pregunta) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF0F6FF),
            const Color(0xFFE0EFFE).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF93C5FD).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Text(
        pregunta,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E3A8A),
          height: 1.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildOptionButton(String key, String value, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              respuestas['pregunta_$preguntaActual'] = key;
            });
            _guardarProgreso();
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        const Color(0xFFF0F6FF).withOpacity(0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFFDEEAFE).withOpacity(0.8),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF93C5FD).withOpacity(0.20),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E3A8A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E3A8A),
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(String respuestaSeleccionada) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (preguntaActual > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildNavButton(
                label: 'Anterior',
                icon: Icons.arrow_back_rounded,
                onPressed: anteriorPregunta,
                isPrimary: false,
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: preguntaActual > 0 ? 8 : 0),
            child: _buildNavButton(
              label: preguntaActual == preguntas.length - 1
                  ? 'Finalizar'
                  : 'Siguiente',
              icon: preguntaActual == preguntas.length - 1
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: respuestaSeleccionada.isNotEmpty
                  ? siguientePregunta
                  : null,
              isPrimary: true,
              iconAtEnd: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool iconAtEnd = false,
  }) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            gradient: isPrimary && isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                  )
                : null,
            color: !isPrimary
                ? const Color(0xFFE5E7EB).withOpacity(0.8)
                : isEnabled
                    ? null
                    : const Color(0xFFDEEAFE).withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (isPrimary && isEnabled)
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!iconAtEnd) ...[
                Icon(
                  icon,
                  color: isPrimary
                      ? (isEnabled ? Colors.white : Colors.grey.shade400)
                      : const Color(0xFF1E3A8A),
                  size: 19,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? (isEnabled ? Colors.white : Colors.grey.shade400)
                      : const Color(0xFF1E3A8A),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (iconAtEnd) ...[
                const SizedBox(width: 8),
                Icon(
                  icon,
                  color: isPrimary
                      ? (isEnabled ? Colors.white : Colors.grey.shade400)
                      : const Color(0xFF1E3A8A),
                  size: 19,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF0F6FF),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFF93C5FD).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withOpacity(0.20),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Enviar respuestas?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Una vez enviadas no podrás modificarlas. ¿Estás seguro?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _buildDialogButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialogButton(
                    label: 'Enviar',
                    onPressed: () {
                      Navigator.of(context).pop();
                      enviarTest();
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                  )
                : null,
            color: !isPrimary ? const Color(0xFFE5E7EB).withOpacity(0.8) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ FONDO ACADÉMICO CON OBJETOS DISPERSOS ------------------
class _AcademicBackground extends StatefulWidget {
  const _AcademicBackground();

  @override
  State<_AcademicBackground> createState() => _AcademicBackgroundState();
}

class _AcademicBackgroundState extends State<_AcademicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Stack(
          children: [
            // Gradiente base suave
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.9, -1),
                  end: Alignment(1, 1),
                  colors: [
                    Color(0xFFE0F2FE),
                    Color(0xFFBAE6FD),
                    Color(0xFF93C5FD),
                  ],
                ),
              ),
            ),

            // Orbes suaves
            CustomPaint(
              painter: _SoftOrbsPainter(_animation.value),
              size: Size.infinite,
            ),

            // Profesor (izquierda)
            Positioned(
              left: -30,
              bottom: 40,
              child: Opacity(
                opacity: 0.18,
                child: CustomPaint(
                  size: const Size(300, 380),
                  painter: _TeacherPainter(_animation.value),
                ),
              ),
            ),

            // Objetos académicos dispersos
            CustomPaint(
              painter: _AcademicObjectsPainter(_animation.value),
              size: Size.infinite,
            ),

            // Símbolos matemáticos flotantes
            CustomPaint(
              painter: _MathSymbolsPainter(_animation.value),
              size: Size.infinite,
            ),

            // Partículas brillantes
            CustomPaint(
              painter: _ShiningParticlesPainter(_animation.value),
              size: Size.infinite,
            ),

            // Overlay suave
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Profesor
class _TeacherPainter extends CustomPainter {
  final double t;
  _TeacherPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final offsetY = 10 * math.sin(t * 2 * math.pi);
    canvas.translate(0, offsetY);

    // Mesa
    paint.color = const Color(0xFFD4A574);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, size.height - 130, 200, 18),
        const Radius.circular(9),
      ),
      paint,
    );

    // Patas
    paint.color = const Color(0xFF8B6F47);
    canvas.drawRect(Rect.fromLTWH(60, size.height - 130, 12, 65), paint);
    canvas.drawRect(Rect.fromLTWH(200, size.height - 130, 12, 65), paint);

    // Cuerpo
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.48, size.width * 0.40,
            size.height * 0.28),
        const Radius.circular(12),
      ),
      paint,
    );

    // Corbata
    paint.color = const Color(0xFF60A5FA);
    final tiePath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.46)
      ..lineTo(size.width * 0.45, size.height * 0.74)
      ..lineTo(size.width * 0.50, size.height * 0.70)
      ..lineTo(size.width * 0.55, size.height * 0.74)
      ..close();
    canvas.drawPath(tiePath, paint);

    // Brazos
    paint.color = const Color(0xFFFDB074);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.60), 22, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.60), 22, paint);

    // Cabeza
    paint.color = const Color(0xFFFDB074);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.36), 48, paint);

    // Cabello
    paint.color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.28), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.28), 30, paint);

    // Ojos
    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.36), 4, paint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.36), 4, paint);

    // Sonrisa
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    final smilePath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.46,
          size.width * 0.60, size.height * 0.42);
    canvas.drawPath(smilePath, paint);

    // Pantalón
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1E3A8A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.76, size.width * 0.40,
            size.height * 0.14),
        const Radius.circular(8),
      ),
      paint,
    );

    // Maletín
    paint.color = const Color(0xFF92400E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, size.height - 90, 50, 38),
        const Radius.circular(6),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TeacherPainter oldDelegate) => oldDelegate.t != t;
}

// Orbes suaves
class _SoftOrbsPainter extends CustomPainter {
  final double t;
  _SoftOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void drawOrb(
        Offset center, double radius, Color color, double dx, double dy) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

      final animatedCenter = Offset(
        center.dx + dx * math.sin(t * 2 * math.pi),
        center.dy + dy * math.cos(t * 2 * math.pi),
      );

      canvas.drawCircle(animatedCenter, radius, paint);
    }

    drawOrb(
      Offset(size.width * 0.25, size.height * 0.25),
      size.width * 0.30,
      const Color(0xFF93C5FD),
      25,
      20,
    );

    drawOrb(
      Offset(size.width * 0.75, size.height * 0.22),
      size.width * 0.35,
      const Color(0xFF60A5FA),
      -20,
      25,
    );

    drawOrb(
      Offset(size.width * 0.50, size.height * 0.75),
      size.width * 0.38,
      const Color(0xFF7DD3FC),
      18,
      -18,
    );
  }

  @override
  bool shouldRepaint(_SoftOrbsPainter oldDelegate) => oldDelegate.t != t;
}

// Objetos académicos dispersos
class _AcademicObjectsPainter extends CustomPainter {
  final double t;
  _AcademicObjectsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Libros dispersos
    _drawBook(canvas, paint, 
        Offset(size.width * 0.12 + 12 * math.sin(t * 2 * math.pi),
            size.height * 0.20 + 10 * math.cos(t * 2 * math.pi)),
        0.15 + 0.08 * math.sin(t * 2 * math.pi),
        const Color(0xFF60A5FA));

    _drawBook(canvas, paint,
        Offset(size.width * 0.85 + 10 * math.cos((t + 0.3) * 2 * math.pi),
            size.height * 0.28 + 12 * math.sin((t + 0.3) * 2 * math.pi)),
        -0.12 + 0.08 * math.cos(t * 2 * math.pi),
        const Color(0xFF93C5FD));

    _drawBook(canvas, paint,
        Offset(size.width * 0.18 + 8 * math.sin((t + 0.6) * 2 * math.pi),
            size.height * 0.65 + 9 * math.cos((t + 0.6) * 2 * math.pi)),
        0.10 + 0.06 * math.sin((t + 0.5) * 2 * math.pi),
        const Color(0xFF7DD3FC));

    // Globos terráqueos
    _drawGlobe(canvas, paint,
        Offset(size.width * 0.88 + 11 * math.cos(t * 2 * math.pi),
            size.height * 0.18 + 13 * math.sin(t * 2 * math.pi)));

    _drawGlobe(canvas, paint,
        Offset(size.width * 0.15 + 9 * math.sin((t + 0.4) * 2 * math.pi),
            size.height * 0.75 + 11 * math.cos((t + 0.4) * 2 * math.pi)));

    // Calculadoras
    _drawCalculator(canvas, paint,
        Offset(size.width * 0.82 + 10 * math.sin((t + 0.2) * 2 * math.pi),
            size.height * 0.70 + 8 * math.cos((t + 0.2) * 2 * math.pi)));

    _drawCalculator(canvas, paint,
        Offset(size.width * 0.10 + 8 * math.cos((t + 0.7) * 2 * math.pi),
            size.height * 0.35 + 10 * math.sin((t + 0.7) * 2 * math.pi)));

    // Microscopios
    _drawMicroscope(canvas, paint,
        Offset(size.width * 0.90 + 9 * math.sin((t + 0.5) * 2 * math.pi),
            size.height * 0.55 + 7 * math.cos((t + 0.5) * 2 * math.pi)));

    // Diplomas
    _drawDiploma(canvas, paint,
        Offset(size.width * 0.50 + 7 * math.sin((t + 0.8) * 2 * math.pi),
            size.height * 0.12 + 9 * math.cos((t + 0.8) * 2 * math.pi)),
        -0.10 + 0.08 * math.cos(t * 2 * math.pi));

    // Diccionarios
    _drawDictionary(canvas, paint,
        Offset(size.width * 0.08 + 10 * math.cos((t + 0.9) * 2 * math.pi),
            size.height * 0.50 + 8 * math.sin((t + 0.9) * 2 * math.pi)));
  }

  void _drawBook(Canvas canvas, Paint paint, Offset pos, double rotation, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    
    paint.color = color.withOpacity(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -28, 40, 56),
        const Radius.circular(4),
      ),
      paint,
    );
    
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawRect(const Rect.fromLTWH(-15, -23, 30, 6), paint);
    
    canvas.restore();
  }

  void _drawGlobe(Canvas canvas, Paint paint, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    
    paint.color = const Color(0xFF60A5FA).withOpacity(0.20);
    canvas.drawCircle(Offset.zero, 28, paint);
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = const Color(0xFF93C5FD).withOpacity(0.35);
    canvas.drawCircle(Offset.zero, 28, paint);
    canvas.drawLine(const Offset(-28, 0), const Offset(28, 0), paint);
    canvas.drawLine(const Offset(0, -28), const Offset(0, 28), paint);
    
    paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  void _drawCalculator(Canvas canvas, Paint paint, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    
    paint.color = const Color(0xFF93C5FD).withOpacity(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-17, -25, 34, 50),
        const Radius.circular(5),
      ),
      paint,
    );
    
    paint.color = const Color(0xFF60A5FA).withOpacity(0.30);
    canvas.drawRect(const Rect.fromLTWH(-12, -20, 24, 12), paint);
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(Offset(-7 + j * 7.0, -2 + i * 7.0), 2, paint);
      }
    }
    
    canvas.restore();
  }

  void _drawMicroscope(Canvas canvas, Paint paint, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    
    paint.color = const Color(0xFF60A5FA).withOpacity(0.22);
    canvas.drawRect(const Rect.fromLTWH(-3, 15, 6, 30), paint);
    canvas.drawCircle(const Offset(0, 8), 10, paint);
    canvas.drawRect(const Rect.fromLTWH(-12, 45, 24, 3), paint);
    
    canvas.restore();
  }

  void _drawDiploma(Canvas canvas, Paint paint, Offset pos, double rotation) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    
    paint.color = const Color(0xFF93C5FD).withOpacity(0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, -17, 50, 34),
        const Radius.circular(3),
      ),
      paint,
    );
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = const Color(0xFF60A5FA).withOpacity(0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, -14, 44, 28),
        const Radius.circular(2),
      ),
      paint,
    );
    
    paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  void _drawDictionary(Canvas canvas, Paint paint, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    
    paint.color = const Color(0xFF7DD3FC).withOpacity(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, -25, 36, 50),
        const Radius.circular(4),
      ),
      paint,
    );
    
    paint.color = Colors.white.withOpacity(0.25);
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(-13, -18 + i * 9.0, 26, 2), paint);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AcademicObjectsPainter oldDelegate) =>
      oldDelegate.t != t;
}

// Símbolos matemáticos flotantes
class _MathSymbolsPainter extends CustomPainter {
  final double t;
  _MathSymbolsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    _drawMathSymbol(canvas, paint, '+',
        Offset(size.width * 0.22,
            size.height * 0.15 + 10 * math.sin((t + 0.1) * 2 * math.pi)),
        const Color(0xFF60A5FA));

    _drawMathSymbol(canvas, paint, '×',
        Offset(size.width * 0.78,
            size.height * 0.35 + 12 * math.cos((t + 0.3) * 2 * math.pi)),
        const Color(0xFF93C5FD));

    _drawMathSymbol(canvas, paint, '÷',
        Offset(size.width * 0.15,
            size.height * 0.82 + 8 * math.sin((t + 0.6) * 2 * math.pi)),
        const Color(0xFF7DD3FC));

    _drawMathSymbol(canvas, paint, '=',
        Offset(size.width * 0.85,
            size.height * 0.82 + 10 * math.cos((t + 0.8) * 2 * math.pi)),
        const Color(0xFF60A5FA));

    _drawMathSymbol(canvas, paint, 'π',
        Offset(size.width * 0.92,
            size.height * 0.45 + 9 * math.sin((t + 0.4) * 2 * math.pi)),
        const Color(0xFF93C5FD));

    _drawMathSymbol(canvas, paint, '√',
        Offset(size.width * 0.05,
            size.height * 0.28 + 11 * math.cos((t + 0.7) * 2 * math.pi)),
        const Color(0xFF7DD3FC));
  }

  void _drawMathSymbol(Canvas canvas, Paint paint, String symbol, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_MathSymbolsPainter oldDelegate) => oldDelegate.t != t;
}

// Partículas brillantes
class _ShiningParticlesPainter extends CustomPainter {
  final double t;
  _ShiningParticlesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(789);
    final paint = Paint();

    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final phase = i * 0.15 + t * 2 * math.pi;
      final opacity = 0.10 + 0.20 * math.sin(phase);
      final radius = 0.8 + 1.4 * math.cos(phase);

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ShiningParticlesPainter oldDelegate) =>
      oldDelegate.t != t;
}

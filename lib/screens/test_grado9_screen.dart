import 'dart:ui';
import 'dart:math' as math;
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
  // ---------------------- 57 preguntas completas (SIN CAMBIOS)
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

  Future<void> _cargarProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('grado9_pregunta_actual') ?? 0;
    final savedResp = prefs.getString('grado9_respuestas');

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
  final prefs = await SharedPreferences.getInstance();

  // Armar el payload exactamente como lo espera tu backend:
  final respuestasFinales = {
    for (var i = 0; i < preguntas.length; i++)
      'pregunta_${i + 1}': respuestas['pregunta_$i'] ?? ''
  };

  // Enviar vía tu servicio centralizado
  final api = ApiService();
  final resp = await api.enviarTestGrado9(respuestasFinales);

  if (resp['success'] == true) {
    // Limpiar progreso local
    await prefs.remove('grado9_pregunta_actual');
    await prefs.remove('grado9_respuestas');

    // Extraer el "resultado" para la pantalla (acepta map o string)
    final data = resp['resultado'];
    final resultadoStr = (data is Map && data['resultado'] != null)
        ? data['resultado'].toString()
        : data.toString();

    // Calcular porcentajes locales (igual que antes)
    final contador = {'A': 0, 'B': 0, 'C': 0};
    for (final v in respuestas.values) {
      if (contador.containsKey(v)) {
        contador[v] = contador[v]! + 1;
      }
    }
    final total = respuestas.isEmpty ? 1 : respuestas.length;
    final porcentajes = {
      'Me gusta': (contador['A']! * 100 / total),
      'Me interesa': (contador['B']! * 100 / total),
      'No me gusta': (contador['C']! * 100 / total),
    };

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoTest9Screen(
          resultado: resultadoStr,
          porcentajes: porcentajes,
          icono: Icons.lightbulb,
          color: const Color(0xFF93C5FD),
        ),
      ),
    );
  } else {
    // Mostrar error del servicio
    final msg = resp['message']?.toString() ?? 'No se pudo enviar el test.';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}


  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[preguntaActual];
    final respuestaSeleccionada = respuestas['pregunta_$preguntaActual'] ?? '';
    final double progreso = preguntas.isEmpty ? 0 : (respuestas.length / preguntas.length);

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
          const Positioned.fill(child: _AcademicBackground()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _buildQuestionCard(pregunta, respuestaSeleccionada, progreso),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String pregunta, String respuestaSeleccionada, double progreso) {
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
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const EstudianteHome()),
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
          _buildQuestionText(pregunta),
          const SizedBox(height: 24),
          ...opciones.entries.map((opcion) {
            return _buildOptionButton(
              opcion.key,
              opcion.value,
              respuestaSeleccionada == opcion.key,
            );
          }).toList(),
          const SizedBox(height: 28),
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
                          colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
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
                      color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
              label: preguntaActual == preguntas.length - 1 ? 'Finalizar' : 'Siguiente',
              icon: preguntaActual == preguntas.length - 1
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: respuestaSeleccionada.isNotEmpty ? siguientePregunta : null,
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
                ? const LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)])
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
            colors: [Colors.white, Color(0xFFF0F6FF)],
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
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 30),
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
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
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
                ? const LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)])
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

// FONDO ACADÉMICO
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
            CustomPaint(
              painter: _SoftOrbsPainter(_animation.value),
              size: Size.infinite,
            ),
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
            CustomPaint(
              painter: _AcademicObjectsPainter(_animation.value),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: _MathSymbolsPainter(_animation.value),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: _ShiningParticlesPainter(_animation.value),
              size: Size.infinite,
            ),
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

// Painters (idénticos a test 10-11)
class _TeacherPainter extends CustomPainter {
  final double t;
  _TeacherPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final offsetY = 10 * math.sin(t * 2 * math.pi);
    canvas.translate(0, offsetY);

    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.50, size.width * 0.40, size.height * 0.25),
        const Radius.circular(12),
      ),
      paint,
    );

    paint.color = const Color(0xFF60A5FA);
    final tiePath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.48)
      ..lineTo(size.width * 0.46, size.height * 0.72)
      ..lineTo(size.width * 0.50, size.height * 0.68)
      ..lineTo(size.width * 0.54, size.height * 0.72)
      ..close();
    canvas.drawPath(tiePath, paint);

    paint.color = const Color(0xFFFDB074);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.60), 22, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.60), 22, paint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.38), 48, paint);

    paint.color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.30), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.30), 30, paint);

    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.38), 4, paint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.38), 4, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    final smilePath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.48, size.width * 0.60, size.height * 0.44);
    canvas.drawPath(smilePath, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1E3A8A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.76, size.width * 0.40, size.height * 0.14),
        const Radius.circular(8),
      ),
      paint,
    );

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

class _SoftOrbsPainter extends CustomPainter {
  final double t;
  _SoftOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void drawOrb(Offset center, double radius, Color color, double dx, double dy) {
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

    drawOrb(Offset(size.width * 0.25, size.height * 0.25), size.width * 0.30,
        const Color(0xFF93C5FD), 25, 20);
    drawOrb(Offset(size.width * 0.75, size.height * 0.22), size.width * 0.35,
        const Color(0xFF60A5FA), -20, 25);
    drawOrb(Offset(size.width * 0.50, size.height * 0.75), size.width * 0.38,
        const Color(0xFF7DD3FC), 18, -18);
  }

  @override
  bool shouldRepaint(_SoftOrbsPainter oldDelegate) => oldDelegate.t != t;
}

class _AcademicObjectsPainter extends CustomPainter {
  final double t;
  _AcademicObjectsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    _drawBook(canvas, paint,
        Offset(size.width * 0.12 + 12 * math.sin(t * 2 * math.pi),
            size.height * 0.20 + 10 * math.cos(t * 2 * math.pi)),
        0.15 + 0.08 * math.sin(t * 2 * math.pi), const Color(0xFF60A5FA));

    _drawBook(canvas, paint,
        Offset(size.width * 0.85 + 10 * math.cos((t + 0.3) * 2 * math.pi),
            size.height * 0.28 + 12 * math.sin((t + 0.3) * 2 * math.pi)),
        -0.12 + 0.08 * math.cos(t * 2 * math.pi), const Color(0xFF93C5FD));

    _drawGlobe(canvas, paint,
        Offset(size.width * 0.88 + 11 * math.cos(t * 2 * math.pi),
            size.height * 0.18 + 13 * math.sin(t * 2 * math.pi)));

    _drawCalculator(canvas, paint,
        Offset(size.width * 0.82 + 10 * math.sin((t + 0.2) * 2 * math.pi),
            size.height * 0.70 + 8 * math.cos((t + 0.2) * 2 * math.pi)));

    _drawDiploma(canvas, paint,
        Offset(size.width * 0.50 + 7 * math.sin((t + 0.8) * 2 * math.pi),
            size.height * 0.12 + 9 * math.cos((t + 0.8) * 2 * math.pi)),
        -0.10 + 0.08 * math.cos(t * 2 * math.pi));
  }

  void _drawBook(Canvas canvas, Paint paint, Offset pos, double rotation, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    paint.color = color.withOpacity(0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -28, 40, 56), const Radius.circular(4)),
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
      RRect.fromRectAndRadius(const Rect.fromLTWH(-17, -25, 34, 50), const Radius.circular(5)),
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

  void _drawDiploma(Canvas canvas, Paint paint, Offset pos, double rotation) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);
    paint.color = const Color(0xFF93C5FD).withOpacity(0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-25, -17, 50, 34), const Radius.circular(3)),
      paint,
    );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = const Color(0xFF60A5FA).withOpacity(0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -14, 44, 28), const Radius.circular(2)),
      paint,
    );
    paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AcademicObjectsPainter oldDelegate) => oldDelegate.t != t;
}

class _MathSymbolsPainter extends CustomPainter {
  final double t;
  _MathSymbolsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawMathSymbol(canvas, '+',
        Offset(size.width * 0.22, size.height * 0.15 + 10 * math.sin((t + 0.1) * 2 * math.pi)));
    _drawMathSymbol(canvas, '×',
        Offset(size.width * 0.78, size.height * 0.35 + 12 * math.cos((t + 0.3) * 2 * math.pi)));
    _drawMathSymbol(canvas, '÷',
        Offset(size.width * 0.15, size.height * 0.82 + 8 * math.sin((t + 0.6) * 2 * math.pi)));
    _drawMathSymbol(canvas, '=',
        Offset(size.width * 0.85, size.height * 0.82 + 10 * math.cos((t + 0.8) * 2 * math.pi)));
  }

  void _drawMathSymbol(Canvas canvas, String symbol, Offset pos) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF93C5FD).withOpacity(0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(_MathSymbolsPainter oldDelegate) => oldDelegate.t != t;
}

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
  bool shouldRepaint(_ShiningParticlesPainter oldDelegate) => oldDelegate.t != t;
}

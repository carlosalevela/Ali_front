import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

class ResultadoTest1011Screen extends StatefulWidget {
  final Map<String, String> respuestas;
  final String resultado;

  const ResultadoTest1011Screen({
    Key? key,
    required this.respuestas,
    required this.resultado,
  }) : super(key: key);

  @override
  State<ResultadoTest1011Screen> createState() =>
      _ResultadoTest1011ScreenState();
}

class _ResultadoTest1011ScreenState extends State<ResultadoTest1011Screen>
    with TickerProviderStateMixin {
  late Map<String, double> porcentajes;
  late IconData icono;
  late Color accentColor;
  late String carreraLabel;
  late String explicacion;
  late List<Map<String, dynamic>> topCarreras;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _calcularPorcentajes();
    carreraLabel = _extractCareerLabel(widget.resultado).trim();
    if (carreraLabel.isEmpty) {
      carreraLabel = _pretty(widget.resultado).trim();
    }
    explicacion = _extractExplanation(widget.resultado).trim();
    if (explicacion.isEmpty) {
      explicacion =
          'Estamos preparando tu explicación personalizada según tus respuestas.';
    }
    _configurarIconoYColor(carreraLabel);
    _generarTopCarreras();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _calcularPorcentajes() {
    final conteo = {'A': 0, 'B': 0, 'C': 0};
    for (final r in widget.respuestas.values) {
      if (conteo.containsKey(r)) conteo[r] = conteo[r]! + 1;
    }
    final total =
        widget.respuestas.isEmpty ? 1.0 : widget.respuestas.length.toDouble();
    porcentajes = {
      for (final k in conteo.keys) k: (conteo[k]! / total * 100).toDouble()
    };
  }

    void _generarTopCarreras() {
  // Extraer Top-3 desde el texto del backend
  final top3Extraido = _extractTop3FromText(widget.resultado);
  
  final colores = [
    accentColor,  // Color principal para la carrera #1
    const Color(0xFF8B5CF6),  // Púrpura para #2
    const Color(0xFFEC4899),  // Rosa para #3
  ];
  
  final iconos = [
    icono,  // Icono principal para la carrera #1
    FontAwesomeIcons.lightbulb,
    FontAwesomeIcons.star,
  ];
  
  topCarreras = [];
  for (int i = 0; i < top3Extraido.length && i < 3; i++) {
    final entry = top3Extraido[i];
    final nombre = entry.key;
    final scoreStr = entry.value;
    
    // Convertir el score (0.58) a porcentaje (58%)
    double porcentaje = 0.0;
    try {
      final scoreNum = double.parse(scoreStr);
      porcentaje = scoreNum * 100;  // 0.58 -> 58.0
    } catch (_) {
      porcentaje = 0.0;
    }
    
    topCarreras.add({
      'nombre': nombre,
      'porcentaje': porcentaje,
      'color': colores[i],
      'icono': iconos[i],
    });
  }
}

// ✅ Agregar este método para extraer el Top-3
List<MapEntry<String, String>> _extractTop3FromText(String texto) {
  final re = RegExp(r'Top-3:\s*(.+)', caseSensitive: false);
  final m = re.firstMatch(texto);
  if (m == null) return [];
  final listRaw = m.group(1)!;
  final parts = listRaw.split(',');
  final out = <MapEntry<String, String>>[];
  for (final p in parts.take(3)) {
    final t = p.trim();
    final name = t.replaceAll(RegExp(r'\([^\)]*\)'), '').trim();
    final score = RegExp(r'\(([^)]*)\)').firstMatch(t)?.group(1) ?? '';
    if (name.isNotEmpty) out.add(MapEntry(name, score));
  }
  return out;
}


  String _pretty(String s) {
    if (s.contains(RegExp(r'[ÃÂ]'))) {
      try {
        return utf8.decode(const Latin1Codec().encode(s), allowMalformed: true);
      } catch (_) {}
    }
    return s;
  }

  String _stripDiacritics(String s) {
    return s
        .replaceAll(RegExp(r'[áàäâãÁÀÄÂÃ]'), 'a')
        .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
        .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
        .replaceAll(RegExp(r'[óòöôõÓÒÖÔÕ]'), 'o')
        .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u')
        .replaceAll(RegExp(r'[ñÑ]'), 'n')
        .replaceAll(RegExp(r'[çÇ]'), 'c');
  }

  String _norm(String s) => _stripDiacritics(_pretty(s).toLowerCase());

  bool _looksLikeCareer(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains('{') || t.contains('[') || t.contains(':')) return false;
    if (t.length > 60) return false;
    final lettersOnly =
        RegExp(r'^[\p{L}\s\-\(\)\/&]+$', unicode: true).hasMatch(t);
    if (lettersOnly) return true;
    final norm = _stripDiacritics(t.toLowerCase());
    const keys = [
      'ingenier',
      'disen',
      'diseñ',
      'medic',
      'derech',
      'psicol',
      'admin',
      'contad',
      'sistem',
      'softw',
      'biolog',
      'quimic',
      'fisic',
      'docen',
      'educac',
      'finanz',
      'marketing',
      'comunic',
      'arquite',
      'enfermer',
      'graf',
      'turism',
      'gastron',
      'veterin',
      'agro',
      'comerc',
      'natur'
    ];
    return keys.any((k) => norm.contains(k));
  }

  String _pickFromDecodedJson(dynamic dec) {
    if (dec is String) return _pretty(dec);
    if (dec is Map) {
      for (final k in [
        'carrera',
        'carrera_sugerida',
        'nombre_carrera',
        'resultado',
        'recomendacion',
        'recomendación',
        'label',
        'titulo',
        'nombre'
      ]) {
        final v = dec[k];
        if (v is String && v.trim().isNotEmpty) return _pretty(v);
      }
      String? best;
      void walk(dynamic v) {
        if (v == null) return;
        if (v is String) {
          if (_looksLikeCareer(v)) {
            if (best == null || v.length < best!.length) best = v;
          }
        } else if (v is Map) {
          for (final e in v.values) walk(e);
        } else if (v is List) {
          for (final e in v) walk(e);
        }
      }

      walk(dec);
      return _pretty(best ?? '');
    }
    if (dec is List) {
      for (final e in dec) {
        final s = _pickFromDecodedJson(e);
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  String _extractCareerLabel(String raw) {
    final s = _pretty(raw).trim();
    if (s.isEmpty) return '';
    if ((s.startsWith('{') && s.endsWith('}')) ||
        (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);
        final fromJson = _pickFromDecodedJson(dec);
        if (fromJson.isNotEmpty) return fromJson;
      } catch (_) {}
    }
    final lines = s
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (final line in lines) {
      final norm = _norm(line);
      if (norm.contains('carrera recomendada') ||
          norm.contains('recomendacion') ||
          norm.contains('recomendación') ||
          norm.contains('area sugerida') ||
          norm.contains('área sugerida')) {
        final idx = line.indexOf(':');
        if (idx != -1 && idx + 1 < line.length) {
          final candidate = line.substring(idx + 1).trim();
          if (_looksLikeCareer(candidate)) return candidate;
        }
      }
    }
    for (final line in lines) {
      if (_looksLikeCareer(line)) return line;
    }
    return s.length <= 60 ? s : s.substring(0, 60);
  }

  String _extractExplanation(String raw) {
    final s = _pretty(raw).trim();
    if (s.isEmpty) return '';
    if ((s.startsWith('{') && s.endsWith('}')) ||
        (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);
        String findInMap(Map m) {
          for (final k in [
            'explicacion',
            'explicación',
            'justificacion',
            'justificación',
            'detalle',
            'motivo',
            'razon',
            'razón',
            'explanation',
            'why',
            'mensaje'
          ]) {
            final v = m[k];
            if (v is String && v.trim().isNotEmpty) return _pretty(v);
          }
          for (final k in ['resultado', 'output', 'data', 'response']) {
            final v = m[k];
            if (v is Map) {
              final got = findInMap(v);
              if (got.isNotEmpty) return got;
            }
          }
          for (final v in m.values) {
            if (v is List) {
              for (final e in v) {
                if (e is Map) {
                  final got = findInMap(e);
                  if (got.isNotEmpty) return got;
                } else if (e is String && e.trim().length > 20) {
                  return _pretty(e.trim());
                }
              }
            }
          }
          return '';
        }

        if (dec is Map) {
          final got = findInMap(dec);
          if (got.isNotEmpty) return got;
        } else if (dec is List) {
          for (final e in dec) {
            if (e is Map) {
              final got = findInMap(e);
              if (got.isNotEmpty) return got;
            } else if (e is String && e.trim().length > 20) {
              return _pretty(e.trim());
            }
          }
        }
      } catch (_) {}
    }
    final lines = s.split(RegExp(r'\r?\n'));
    final joined = lines.join('\n');
    final expIdx = _norm(joined).indexOf('explicacion');
    if (expIdx != -1) {
      final after = joined.substring(expIdx);
      final colon = after.indexOf(':');
      if (colon != -1 && colon + 1 < after.length) {
        final text = after.substring(colon + 1).trim();
        if (text.isNotEmpty) return _pretty(text);
      }
    }
    if (lines.isNotEmpty && _looksLikeCareer(lines.first)) {
      final rest = lines.skip(1).join(' ').trim();
      if (rest.length > 15) return _pretty(rest);
    }
    if (!_looksLikeCareer(s) && s.length > 20) return _pretty(s);
    return '';
  }

  void _configurarIconoYColor(String resultadoEtiqueta) {
    final c = _norm(resultadoEtiqueta);

    IconData pickIcon() {
      if (c.contains('ingenier')) return FontAwesomeIcons.gears;
      if (c.contains('medic')) return FontAwesomeIcons.userDoctor;
      if (c.contains('psicol')) return FontAwesomeIcons.brain;
      if (c.contains('derech')) return FontAwesomeIcons.scaleBalanced;
      if (c.contains('educac') || c.contains('docen'))
        return FontAwesomeIcons.bookOpen;
      if (c.contains('sistem') || c.contains('softw'))
        return FontAwesomeIcons.laptopCode;
      if (c.contains('admin')) return FontAwesomeIcons.chartColumn;
      if (c.contains('contad')) return FontAwesomeIcons.calculator;
      if (c.contains('disen') || c.contains('diseñ') || c.contains('graf'))
        return FontAwesomeIcons.penNib;
      return FontAwesomeIcons.graduationCap;
    }

    Color pickColor() {
      if (c.contains('ingenier')) return const Color(0xFF60A5FA);
      if (c.contains('medic')) return const Color(0xFF10B981);
      if (c.contains('psicol')) return const Color(0xFF8B5CF6);
      if (c.contains('derech')) return const Color(0xFFF59E0B);
      if (c.contains('educac') || c.contains('docen'))
        return const Color(0xFF3B82F6);
      if (c.contains('sistem') || c.contains('softw'))
        return const Color(0xFF06B6D4);
      if (c.contains('admin')) return const Color(0xFF10B981);
      if (c.contains('contad')) return const Color(0xFF14B8A6);
      if (c.contains('disen') || c.contains('diseñ') || c.contains('graf'))
        return const Color(0xFFEC4899);
      return const Color(0xFF93C5FD);
    }

    icono = pickIcon();
    accentColor = pickColor();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeroSection(isWide),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 60 : 20,
                    vertical: 16,
                  ),
                  child: _buildMainCards(isWide),
                ),
              ),
              SliverToBoxAdapter(child: _buildTeachersIllustration(size)),
              SliverToBoxAdapter(child: _buildFooter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF93C5FD).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'ALI ORIENTADOR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _volverInicio,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.home_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Volver al inicio',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isWide) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20, vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(width: 2, color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.2),
                        accentColor.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FaIcon(icono, color: accentColor, size: 48),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Resultado de tu test!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            carreraLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E3A8A),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCards(bool isWide) {
    return Column(
      children: [
        // Card destacada de Recomendación (arriba, sola)
        _buildExplicacionCardHero(isWide),
        
        const SizedBox(height: 24),

        // Resto de cards en fila
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildTopCarrerasCard(),
                  const SizedBox(height: 16),
                  _buildEstadisticasCard(),
                  const SizedBox(height: 16),
                  _buildAccionCard(),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTopCarrerasCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEstadisticasCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAccionCard()),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildExplicacionCardHero(bool isWide) {
    return _LiquidGlassCard(
      delay: 100,
      borderColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.2),
                      accentColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tu Recomendación Personalizada',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            explicacion,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCarrerasCard() {
    return _CompactGlassCard(
      delay: 200,
      borderColor: const Color(0xFF8B5CF6),
      icon: FontAwesomeIcons.medal,
      iconColor: const Color(0xFF8B5CF6),
      title: 'Top 3 Carreras',
      child: Column(
        children: topCarreras.take(3).map((carrera) {
          final index = topCarreras.indexOf(carrera);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        carrera['color'].withOpacity(0.2),
                        carrera['color'].withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: carrera['color'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    carrera['nombre'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${carrera['porcentaje'].toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: carrera['color'],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    return _CompactGlassCard(
      delay: 300,
      borderColor: const Color(0xFF60A5FA),
      icon: FontAwesomeIcons.chartPie,
      iconColor: const Color(0xFF60A5FA),
      title: 'Estadísticas',
      child: _buildCompactStats(),
    );
  }

  Widget _buildAccionCard() {
    return _CompactGlassCard(
      delay: 400,
      borderColor: const Color(0xFF10B981),
      icon: FontAwesomeIcons.calendarCheck,
      iconColor: const Color(0xFF10B981),
      title: 'Próximo Paso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Agenda una asesoría personalizada con nuestros orientadores',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openContact,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Agendar Ahora',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.3,
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

  Widget _buildCompactStats() {
    final stats = {
      'Me encanta': porcentajes['A'] ?? 0,
      'Me interesa': porcentajes['B'] ?? 0,
      'No me gusta': porcentajes['C'] ?? 0,
    };

    final colors = {
      'Me encanta': const Color(0xFF10B981),
      'Me interesa': const Color(0xFF60A5FA),
      'No me gusta': const Color(0xFFF59E0B),
    };

    return Column(
      children: stats.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[entry.key],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[entry.key]!.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${entry.value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors[entry.key],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeachersIllustration(Size size) {
    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 40),
      child: Stack(
        children: [
          Positioned(
            left: size.width * 0.08,
            bottom: 0,
            child: Opacity(
              opacity: 0.20,
              child: CustomPaint(
                size: const Size(180, 250),
                painter: _TeacherPainter(0.5),
              ),
            ),
          ),
          Positioned(
            right: size.width * 0.08,
            bottom: 0,
            child: Opacity(
              opacity: 0.20,
              child: CustomPaint(
                size: const Size(180, 250),
                painter: _TeacherFemalePainter(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF93C5FD).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.auto_graph, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'ALI Orientadora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2025 ALI Orientadora - Acompañamos tus decisiones',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _volverInicio() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null) {
      await prefs.remove('test_grado_1011_respuestas_$id');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EstudianteHome()),
      (_) => false,
    );
  }

  void _openContact() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
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
                  ),
                  child: const Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contáctanos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 24),
                _buildContactOption(
                  Icons.mail_outline,
                  'Correo electrónico',
                  'soporte@ali-orientadora.edu.co',
                  const Color(0xFF60A5FA),
                ),
                const SizedBox(height: 16),
                _buildContactOption(
                  Icons.chat_bubble_outline,
                  'Chat institucional',
                  'Lunes a viernes, 8:00 - 17:00',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// LIQUID GLASS CARD HERO (para recomendación)
class _LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final int delay;

  const _LiquidGlassCard({
    required this.child,
    required this.borderColor,
    this.delay = 0,
  });

  @override
  State<_LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<_LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
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
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  width: 2,
                  color: widget.borderColor
                      .withOpacity(0.2 + 0.15 * _animation.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.borderColor
                        .withOpacity(0.1 + 0.1 * _animation.value),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

// COMPACT GLASS CARD (para las 3 cards inferiores)
class _CompactGlassCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final int delay;

  const _CompactGlassCard({
    required this.child,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.delay = 0,
  });

  @override
  State<_CompactGlassCard> createState() => _CompactGlassCardState();
}

class _CompactGlassCardState extends State<_CompactGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
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
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(minHeight: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 2,
                  color: widget.borderColor
                      .withOpacity(0.25 + 0.15 * _animation.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.borderColor
                        .withOpacity(0.08 + 0.08 * _animation.value),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.iconColor.withOpacity(0.15),
                              widget.iconColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  widget.child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Painters (sin cambios)
class _TeacherPainter extends CustomPainter {
  final double t;
  _TeacherPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final offsetY = 8 * math.sin(t * 2 * math.pi);
    canvas.translate(0, offsetY);

    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.50, size.width * 0.40,
            size.height * 0.25),
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
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.60), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.60), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.38), 44, paint);

    paint.color = const Color(0xFF92400E);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.30), 28, paint);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.30), 28, paint);

    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.38), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.38), 3, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    final smilePath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.44)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.48,
          size.width * 0.60, size.height * 0.44);
    canvas.drawPath(smilePath, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1E3A8A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.75, size.width * 0.40,
            size.height * 0.18),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TeacherPainter oldDelegate) => oldDelegate.t != t;
}

class _TeacherFemalePainter extends CustomPainter {
  final double t;
  _TeacherFemalePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final offsetY = 10 * math.cos(t * 2 * math.pi);
    canvas.translate(0, offsetY);

    paint.color = const Color(0xFFFCE7F3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.52, size.width * 0.40,
            size.height * 0.23),
        const Radius.circular(12),
      ),
      paint,
    );

    paint.color = const Color(0xFFFDB074);
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.62), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.62), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.40), 44, paint);

    paint.color = const Color(0xFF451A03);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.32), 32, paint);
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.32), 32, paint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.28), 30, paint);
    canvas.drawOval(
        Rect.fromLTWH(size.width * 0.20, size.height * 0.35, 35, 50), paint);
    canvas.drawOval(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.35, 35, 50), paint);

    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.43, size.height * 0.40), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.57, size.height * 0.40), 3, paint);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    final smilePath = Path()
      ..moveTo(size.width * 0.38, size.height * 0.46)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.50,
          size.width * 0.62, size.height * 0.46);
    canvas.drawPath(smilePath, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.30, size.height * 0.75, size.width * 0.40,
            size.height * 0.18),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TeacherFemalePainter oldDelegate) => oldDelegate.t != t;
}

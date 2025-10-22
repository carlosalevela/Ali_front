import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

/// Paleta sobria
const _bgPage    = Color(0xFFF8F9FB);
const _ink       = Color(0xFF0F172A);
const _muted     = Color(0xFF6B7280);
const _brand     = Color(0xFF1465BB);
const _card      = Colors.white;
const _sectionAlt= Color(0xFFF1F5F9);
const _footer    = Color(0xFF0B2447);

/// Logo (reemplaza por tu ruta si es distinta)
const _logoAsset = 'assets/logo_ali.png';

class ResultadoTest1011Screen extends StatefulWidget {
  final Map<String, String> respuestas; // A/B/C/D
  final String resultado;               // string o JSON

  const ResultadoTest1011Screen({
    Key? key,
    required this.respuestas,
    required this.resultado,
  }) : super(key: key);

  @override
  State<ResultadoTest1011Screen> createState() => _ResultadoTest1011ScreenState();
}

class _ResultadoTest1011ScreenState extends State<ResultadoTest1011Screen>
    with TickerProviderStateMixin {
  late Map<String, double> porcentajes;
  late IconData icono;
  late Color accentColor;

  late String carreraLabel;
  late String explicacion;

  late final AnimationController _bounceCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _bounceAnim =
      CurvedAnimation(parent: _bounceCtl, curve: Curves.easeOutBack);

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
      explicacion = 'Estamos preparando tu explicación personalizada según tus respuestas. ¡Vuelve pronto!';
    }

    _configurarIconoYColor(carreraLabel);
  }

  @override
  void dispose() {
    _bounceCtl.dispose();
    super.dispose();
  }

  // --------- Porcentajes A/B/C/D ---------
  void _calcularPorcentajes() {
    final conteo = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (final r in widget.respuestas.values) {
      if (conteo.containsKey(r)) conteo[r] = conteo[r]! + 1;
    }
    final total = widget.respuestas.isEmpty ? 1.0 : widget.respuestas.length.toDouble();
    porcentajes = {for (final k in conteo.keys) k: (conteo[k]! / total * 100).toDouble()};
  }

  // --------- Helpers de texto ---------
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
  String _decodeUTF8(String s) => _pretty(s);

  bool _looksLikeCareer(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains('{') || t.contains('[') || t.contains(':')) return false;
    if (t.length > 60) return false;

    final lettersOnly = RegExp(r'^[\p{L}\s\-\(\)\/&]+$', unicode: true).hasMatch(t);
    if (lettersOnly) return true;

    final norm = _stripDiacritics(t.toLowerCase());
    const keys = [
      'ingenier','disen','diseñ','medic','derech','psicol','admin','contad','sistem','softw',
      'biolog','quimic','fisic','docen','educac','finanz','marketing','comunic','arquite',
      'enfermer','graf','turism','gastron','veterin','agro','comerc','natur'
    ];
    return keys.any((k) => norm.contains(k));
  }

  String _pickFromDecodedJson(dynamic dec) {
    if (dec is String) return _pretty(dec);
    if (dec is Map) {
      for (final k in [
        'carrera','carrera_sugerida','nombre_carrera','resultado','recomendacion','recomendación',
        'label','titulo','nombre'
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

    if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);
        final fromJson = _pickFromDecodedJson(dec);
        if (fromJson.isNotEmpty) return fromJson;
      } catch (_) {}
    }

    final lines = s.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (final line in lines) {
      final norm = _norm(line);
      if (norm.contains('carrera recomendada') ||
          norm.contains('recomendacion') || norm.contains('recomendación') ||
          norm.contains('area sugerida') || norm.contains('área sugerida')) {
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

    if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final dec = jsonDecode(s);

        String findInMap(Map m) {
          for (final k in [
            'explicacion','explicación','justificacion','justificación',
            'detalle','motivo','razon','razón','explanation','why','mensaje'
          ]) {
            final v = m[k];
            if (v is String && v.trim().isNotEmpty) return _pretty(v);
          }
          for (final k in ['resultado','output','data','response']) {
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

  // --------- Icono & color por carrera ---------
  void _configurarIconoYColor(String resultadoEtiqueta) {
    final c = _norm(resultadoEtiqueta);

    IconData pickIcon() {
      if (c.contains('ingenier')) return FontAwesomeIcons.gears;
      if (c.contains('comerc')) return FontAwesomeIcons.cartShopping;
      if (c.contains('promocion social')) return FontAwesomeIcons.handHoldingHeart;
      if (c.contains('agro')) return FontAwesomeIcons.wheatAwn;

      if (c.contains('medic')) return FontAwesomeIcons.userDoctor;
      if (c.contains('psicol')) return FontAwesomeIcons.brain;
      if (c.contains('derech')) return FontAwesomeIcons.scaleBalanced;
      if (c.contains('educac') || c.contains('docen')) return FontAwesomeIcons.bookOpen;
      if (c.contains('sistem') || c.contains('softw')) return FontAwesomeIcons.laptopCode;
      if (c.contains('admin')) return FontAwesomeIcons.chartColumn;
      if (c.contains('contad')) return FontAwesomeIcons.calculator;
      if (c.contains('disen') || c.contains('diseñ') || c.contains('graf')) return FontAwesomeIcons.penNib;
      if (c.contains('arquite')) return FontAwesomeIcons.rulerCombined;
      if (c.contains('enfermer')) return FontAwesomeIcons.userNurse;
      if (c.contains('marketing')) return FontAwesomeIcons.bullhorn;
      if (c.contains('comunic')) return FontAwesomeIcons.microphoneLines;
      if (c.contains('turism')) return FontAwesomeIcons.suitcaseRolling;
      if (c.contains('gastron')) return FontAwesomeIcons.utensils;
      if (c.contains('veterin')) return FontAwesomeIcons.paw;
      if (c.contains('biolog')) return FontAwesomeIcons.dna;
      if (c.contains('quimic')) return FontAwesomeIcons.flaskVial;
      if (c.contains('fisic')) return FontAwesomeIcons.atom;
      if (c.contains('natur')) return FontAwesomeIcons.leaf;
      return FontAwesomeIcons.question;
    }

    Color pickColor() {
      if (c.contains('ingenier')) return Colors.blueGrey;
      if (c.contains('comerc')) return Colors.indigo;
      if (c.contains('promocion social')) return Colors.purple;
      if (c.contains('agro')) return Colors.green.shade700;

      if (c.contains('medic')) return Colors.teal;
      if (c.contains('psicol')) return Colors.deepPurple;
      if (c.contains('derech')) return Colors.brown;
      if (c.contains('educac') || c.contains('docen')) return Colors.indigo;
      if (c.contains('sistem') || c.contains('softw')) return Colors.blue;
      if (c.contains('admin')) return Colors.green;
      if (c.contains('contad')) return Colors.cyan;
      if (c.contains('disen') || c.contains('diseñ') || c.contains('graf')) return Colors.pink;
      if (c.contains('arquite')) return Colors.orange;
      if (c.contains('enfermer')) return Colors.redAccent;
      if (c.contains('marketing')) return Colors.amber.shade800;
      if (c.contains('comunic')) return Colors.blueGrey;
      if (c.contains('turism')) return Colors.deepOrange;
      if (c.contains('gastron')) return Colors.deepOrange.shade400;
      if (c.contains('veterin')) return Colors.green.shade800;
      if (c.contains('biolog')) return Colors.lightGreen;
      if (c.contains('quimic')) return Colors.deepPurple;
      if (c.contains('fisic')) return Colors.blueGrey.shade700;
      if (c.contains('natur')) return Colors.green;
      return Colors.grey;
    }

    icono = pickIcon();
    accentColor = pickColor();
  }

  // --------- UI ---------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final carrera = _decodeUTF8(carreraLabel);
    final desc    = _decodeUTF8(explicacion);

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== Header (solo logo + "ALI ORIENTADOR" + Volver al inicio) =====
            SliverToBoxAdapter(
              child: _Header(
                onHome: _volverInicio,
              ),
            ),

            // ===== Hero (sin botón “Ver detalle”) =====
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
                color: _card,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _bounceAnim,
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icono, color: accentColor, size: 34),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resultado de tu test',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(color: _muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            carrera,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: _ink, fontWeight: FontWeight.w800, height: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== “Sobre la recomendación” =====
            SliverToBoxAdapter(
              child: Container(
                color: _bgPage,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 26),
                child: _SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sobre la recomendación',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 10),
                      _ExpandableText(
                        text: desc.isEmpty
                            ? 'Pronto verás una explicación personalizada generada por ALI según tus intereses.'
                            : desc,
                        maxLines: 5,
                        textStyle: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(height: 1.45, color: _ink),
                        moreLabel: 'Ver más',
                        lessLabel: 'Ver menos',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Acciones recomendadas =====
            SliverToBoxAdapter(
              child: Container(
                color: _sectionAlt,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acciones recomendadas',
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (ctx, cts) {
                        final cross = cts.maxWidth >= 980 ? 3 : (cts.maxWidth >= 620 ? 2 : 1);
                        return GridView.count(
                          crossAxisCount: cross,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.6,
                          children: [
                            _ServiceCard(
                              icon: FontAwesomeIcons.calendarCheck,
                              title: 'Agendar asesoría',
                              desc: 'Reserva una charla rápida para resolver dudas de la carrera.',
                              cta: 'Agendar →',
                              onTap: _openContact,
                            ),
                            _ServiceCard(
                              icon: FontAwesomeIcons.filePdf,
                              title: 'Guardar en PDF',
                              desc: 'Exporta tu recomendación y estadísticas para compartir.',
                              cta: 'Exportar →',
                              onTap: _notImplemented,
                            ),
                            _ServiceCard(
                              icon: FontAwesomeIcons.magnifyingGlass,
                              title: 'Explorar áreas afines',
                              desc: 'Descubre carreras similares según tus intereses.',
                              cta: 'Explorar →',
                              onTap: _notImplemented,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ===== Estadísticas =====
            SliverToBoxAdapter(
              child: Container(
                color: _bgPage,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
                child: _SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estadísticas del test',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 16),
                      _StatsGrid(pct: {
                        'Me gusta': porcentajes['A'] ?? 0,
                        'Me interesa': porcentajes['B'] ?? 0,
                        'No me gusta': porcentajes['C'] ?? 0,
                        'No me interesa': porcentajes['D'] ?? 0,
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Footer =====
            SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }

  // --------- Acciones ---------
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
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 46, height: 5, decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 14),
            Text('Contáctanos', style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.mail_outline, color: _brand),
              title: const Text('Escríbenos por correo'),
              subtitle: const Text('soporte@ali-orientadora.edu.co'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: _brand),
              title: const Text('Chat institucional'),
              subtitle: const Text('Lunes a viernes, 8:00–17:00'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _notImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estamos construyendo esta opción.')),
    );
  }
}

/* ========================= WIDGETS PRIVADOS ========================= */

/// Header simplificado: logo + texto “ALI ORIENTADOR” y botón “Volver al inicio”
class _Header extends StatelessWidget {
  final VoidCallback onHome;
  const _Header({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Row(
            children: [
              Image.asset(
                _logoAsset,
                height: 28,
                fit: BoxFit.contain,
                semanticLabel: 'ALI ORIENTADOR',
                errorBuilder: (_, __, ___) => const Icon(Icons.auto_graph, color: _brand),
              ),
              const SizedBox(width: 10),
              const Text(
                'ALI ORIENTADOR',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home_outlined, size: 16),
            label: const Text('Volver al inicio'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brand,
              side: const BorderSide(color: _brand),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12.withOpacity(.05)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: child,
      );
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String cta;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _brand, size: 22),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Expanded(child: Text(desc, style: const TextStyle(color: _muted, height: 1.4))),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: _brand, padding: EdgeInsets.zero),
            child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, double> pct;
  const _StatsGrid({required this.pct});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> col = {
      'Me gusta': const Color(0xFF10B981),
      'Me interesa': const Color(0xFF0ea5e9),
      'No me gusta': Colors.redAccent,
      'No me interesa': Colors.grey,
    };

    return Wrap(
      alignment: WrapAlignment.start,
      runSpacing: 16,
      spacing: 16,
      children: col.keys.map((k) {
        return _CircleStat(
          label: k,
          color: col[k]!,
          value: (pct[k] ?? 0).clamp(0, 100),
          icon: k == 'Me gusta'
              ? FontAwesomeIcons.thumbsUp
              : k == 'No me gusta'
                  ? FontAwesomeIcons.thumbsDown
                  : k == 'Me interesa'
                      ? FontAwesomeIcons.solidHeart
                      : FontAwesomeIcons.star,
        );
      }).toList(),
    );
  }
}

class _CircleStat extends StatelessWidget {
  final String label;
  final double value; // 0–100
  final IconData icon;
  final Color color;
  const _CircleStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0, 100)) / 100;
    const sz = 86.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => SizedBox(
            width: sz,
            height: sz,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: sz,
                  height: sz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(.10),
                  ),
                ),
                SizedBox(
                  width: sz, height: sz,
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 7,
                    backgroundColor: Colors.black12.withOpacity(.06),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                FaIcon(icon, color: color, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${value.toStringAsFixed(0)}%',
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _footer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Compacto: logo + copy
          _FooterRow(),
          SizedBox(height: 12),
          Divider(color: Colors.white24, height: 1),
          SizedBox(height: 12),
          Text('© 2025 ALI Orientadora', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_graph, color: Colors.white),
        const SizedBox(width: 8),
        const Text('ALI Orientadora',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const Spacer(),
        const Text('Acompañamos tus decisiones con datos y orientación.',
            style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// -------- Texto expandible reutilizable --------
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;
  final String moreLabel;
  final String lessLabel;
  const _ExpandableText({
    required this.text,
    this.maxLines = 4,
    this.textStyle,
    this.moreLabel = 'Ver más',
    this.lessLabel = 'Ver menos',
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? Theme.of(context).textTheme.bodyMedium!;
    final text = widget.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(text, style: style, maxLines: widget.maxLines, overflow: TextOverflow.ellipsis),
          secondChild: Text(text, style: style),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Text(
            expanded ? widget.lessLabel : widget.moreLabel,
            style: style.copyWith(color: _brand, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

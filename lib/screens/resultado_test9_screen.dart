import 'dart:convert'; // <- necesario para decodificar JSON si viene crudo
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'estudiante_home.dart';

/// ===================== PALETA / CONSTANTES =====================
const _bgPage     = Color(0xFFF8F9FB);
const _ink        = Color(0xFF0F172A);
const _muted      = Color(0xFF6B7280);
const _brand      = Color(0xFF1465BB);
const _card       = Colors.white;
const _sectionAlt = Color(0xFFF1F5F9);
const _footer     = Color(0xFF0B2447);

const _logoAsset = 'assets/logo_ali.png';

class ResultadoTest9Screen extends StatefulWidget {
  final String resultado;                   // "Industrial", etc. (o JSON crudo si así lo guardaste)
  final Map<String, double> porcentajes;    // {'Me gusta':..., 'Me interesa':..., ...}
  final IconData icono;                     // fallback icon
  final Color color;                        // acento
  final String? explicacion;                // texto Markdown o JSON crudo del body

  const ResultadoTest9Screen({
    super.key,
    required this.resultado,
    required this.porcentajes,
    required this.icono,
    required this.color,
    this.explicacion,
  });

  @override
  State<ResultadoTest9Screen> createState() => _ResultadoTest9ScreenState();
}

class _ResultadoTest9ScreenState extends State<ResultadoTest9Screen>
    with TickerProviderStateMixin {

  // Animación hero
  late final AnimationController _bounceCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _bounceAnim =
      CurvedAnimation(parent: _bounceCtl, curve: Curves.easeOutBack);

  // ---------- Helpers (misma lógica) ----------
  String _tituloNormalizado(String raw) {
    const prefijo = 'Técnico sugerido por ALI:';
    final s = raw.trim();
    if (s.toLowerCase().startsWith(prefijo.toLowerCase())) return s;
    return '$prefijo $s';
  }

  IconData _iconForResultado(String raw) {
    final s = raw.toLowerCase();
    const prefijo = 'técnico sugerido por ali:';
    final nombre = s.startsWith(prefijo) ? s.substring(prefijo.length).trim() : s;
    String n = nombre
        .replaceAll('á','a').replaceAll('é','e').replaceAll('í','i')
        .replaceAll('ó','o').replaceAll('ú','u');
    if (n.contains('industrial')) return FontAwesomeIcons.gears;
    if (n.contains('comercio')) return FontAwesomeIcons.cartShopping;
    if (n.contains('promocion social')) return FontAwesomeIcons.handHoldingHeart;
    if (n.contains('agropecuaria')) return FontAwesomeIcons.wheatAwn;
    return widget.icono;
  }

  /// -------- extractor robusto del `content` de Groq --------
  String _groqContentFrom(dynamic raw) {
    if (raw == null) return '';
    try {
      // Si ya es String simple (markdown), devuélvelo
      if (raw is String) {
        final s = raw.trim();
        final looksJson = (s.startsWith('{') && s.endsWith('}')) ||
                          (s.startsWith('[') && s.endsWith(']'));
        if (!looksJson) return s;

        // Es JSON en String -> decode y sigue como Map
        final obj = jsonDecode(s);
        if (obj is Map) {
          final choices = obj['choices'];
          if (choices is List && choices.isNotEmpty) {
            final first = choices.first;
            if (first is Map) {
              final message = first['message'];
              if (message is Map) {
                final content = message['content'];
                if (content is String) return content.trim();
              }
            }
          }
        }
        // si no encontramos el content, devuelve el string original
        return s;
      }

      // Si ya es Map (quizá lo parseaste antes)
      if (raw is Map) {
        final choices = raw['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map) {
            final message = first['message'];
            if (message is Map) {
              final content = message['content'];
              if (content is String) return content.trim();
            }
          }
        }
      }
    } catch (_) {
      // si algo falla, devolvemos texto plano
    }
    return raw.toString().trim();
  }

  @override
  void dispose() {
    _bounceCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final String titulo       = _tituloNormalizado(widget.resultado);
    final IconData iconoTec   = _iconForResultado(widget.resultado);
    final Color accentColor   = widget.color;

    // ------------ EXPLICACIÓN (ahora con doble fuente) ------------
    // 1) intenta con widget.explicacion (si la pasas por Navigator)
    // 2) si no, intenta extraer desde widget.resultado (por si guardaste el JSON ahí)
    final String desc = (() {
      final fromExplicacion = _groqContentFrom(widget.explicacion);
      if (fromExplicacion.isNotEmpty) return fromExplicacion;

      final fromResultado = _groqContentFrom(widget.resultado);
      if (fromResultado.isNotEmpty) return fromResultado;

      return '';
    })();

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(child: _Header(onHome: _volverInicio)),

            // HERO
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
                color: _card,
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _bounceAnim,
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(iconoTec, color: accentColor, size: 34),
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
                            titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall!
                                .copyWith(color: _ink, fontWeight: FontWeight.w800, height: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SOBRE LA RECOMENDACIÓN (Markdown + expandible)
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
                      _ExpandableMarkdown(
                        markdown: desc.isEmpty
                            ? '**Pronto** verás una explicación personalizada generada por ALI según tus intereses.'
                            : desc,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ACCIONES RECOMENDADAS
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
                              desc: 'Reserva una charla rápida para resolver dudas del técnico.',
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
                              desc: 'Descubre técnicos o áreas similares según tus intereses.',
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

            // ESTADÍSTICAS
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
                        'Me gusta'      : (widget.porcentajes['Me gusta'] ?? 0),
                        'Me interesa'   : (widget.porcentajes['Me interesa'] ?? 0),
                        'No me gusta'   : (widget.porcentajes['No me gusta'] ?? 0),
                        'No me interesa': (widget.porcentajes['No me interesa'] ?? 0),
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }

  // -------- Acciones --------
  Future<void> _volverInicio() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null) {
      await prefs.remove('test_grado9_respuestas_$id');
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
            Container(
              width: 46, height: 5,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 14),
            Text('Contáctanos',
                style: Theme.of(context).textTheme.titleMedium!
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
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
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
      'Me gusta'      : const Color(0xFF10B981),
      'Me interesa'   : const Color(0xFF0ea5e9),
      'No me gusta'   : Colors.redAccent,
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
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _footer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
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
      children: const [
        Icon(Icons.auto_graph, color: Colors.white),
        SizedBox(width: 8),
        Text('ALI Orientadora',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        Spacer(),
        Text('Acompañamos tus decisiones con datos y orientación.',
            style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

/* ========================= MARKDOWN EXPANDIBLE ========================= */

class _ExpandableMarkdown extends StatefulWidget {
  final String markdown;
  final int initialMaxLines;
  const _ExpandableMarkdown({
    required this.markdown,
    this.initialMaxLines = 7,
  });

  @override
  State<_ExpandableMarkdown> createState() => _ExpandableMarkdownState();
}

class _ExpandableMarkdownState extends State<_ExpandableMarkdown> {
  bool expanded = false;

  MarkdownStyleSheet _sheet(BuildContext context) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      p: Theme.of(context).textTheme.bodyMedium!.copyWith(color: _ink, height: 1.45),
      strong: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
      h1: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900, color: _ink),
      h2: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, color: _ink),
      h3: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800, color: _ink),
      listBullet: const TextStyle(color: _ink),
      blockquote: const TextStyle(color: _ink),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: _brand.withOpacity(.6), width: 3)),
      ),
      a: const TextStyle(color: _brand, decoration: TextDecoration.underline),
      code: const TextStyle(
        fontFamily: 'monospace',
        color: Color(0xFF0F172A),
        backgroundColor: Color(0xFFEEF2F7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.markdown.trim();
    if (content.isEmpty) {
      return Text(
        'Pronto verás una explicación personalizada generada por ALI según tus intereses.',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.45, color: _ink),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: _ClampedMarkdown(
            markdown: content,
            maxLines: widget.initialMaxLines,
            styleSheet: _sheet(context),
          ),
          secondChild: MarkdownBody(
            data: content,
            styleSheet: _sheet(context),
            softLineBreak: true,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Text(
            expanded ? 'Ver menos' : 'Ver más',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: _brand, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Muestra Markdown con máscara de degradado para simular N líneas
class _ClampedMarkdown extends StatelessWidget {
  final String markdown;
  final int maxLines;
  final MarkdownStyleSheet styleSheet;

  const _ClampedMarkdown({
    required this.markdown,
    required this.maxLines,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MarkdownBody(
          data: markdown,
          styleSheet: styleSheet,
          softLineBreak: true,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, (maxLines / 12).clamp(0.0, 0.92), 1.0],
                  colors: const [Colors.transparent, Colors.transparent, Color(0xFFF8F9FB)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

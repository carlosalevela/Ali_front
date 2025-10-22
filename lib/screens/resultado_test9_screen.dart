import 'dart:convert'; // <- necesario para decodificar JSON si viene crudo
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // <-- para cargar fuentes TTF
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/widgets.dart' as pw;         // PDF
import 'package:pdf/pdf.dart' as pdf;            // PDF colors
import 'package:printing/printing.dart';         // PDF share/print
import 'estudiante_home.dart';

/// ===================== PALETA / CONSTANTES =====================
const _bgPage     = Color(0xFFF8F9FB);
const _ink        = Color(0xFF0F172A);
const _muted      = Color(0xFF6B7280);
const _brand      = Color(0xFF1465BB);
const _card       = Colors.white;
const _sectionAlt = Color(0xFFF1F5F9);
const _footer     = Color(0xFF0B2447);

/// Azul claro adicional para cohesionar (sin tocar _brand)
const _lightBlue  = Color(0xFFE9F2FF); // banda suave para secciones

const _logoAsset = 'assets/logo_ali.png';

class ResultadoTest9Screen extends StatefulWidget {
  final String resultado;                   // "Industrial", etc. (o JSON crudo si así lo guardaste)
  final Map<String, double> porcentajes;    // {'Me gusta':..., 'Me interesa':..., 'No me gusta':...}
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

  // Micro-animaciones de entrada
  late final AnimationController _inCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  late final Animation<double> _fadeIn = CurvedAnimation(parent: _inCtl, curve: Curves.easeOutCubic);

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
      if (raw is String) {
        final s = raw.trim();
        final looksJson = (s.startsWith('{') && s.endsWith('}')) ||
                          (s.startsWith('[') && s.endsWith(']'));
        if (!looksJson) return s;
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
        return s;
      }
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
    } catch (_) {}
    return raw.toString().trim();
  }

  // ---------- Extra: util para PDF ----------
  String _plainFromMarkdown(String md) {
    return md
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll('—', '-') // evita glifo faltante si alguna fuente no lo trae
        .trim();
  }

  List<MapEntry<String, String>> _extractTop3FromText(String texto) {
    final re = RegExp(r'Top-3:\s*(.+)', caseSensitive: false);
    final m = re.firstMatch(texto);
    if (m == null) return [];
    final listRaw = m.group(1)!;
    final parts = listRaw.split(',');
    final out = <MapEntry<String, String>>[];
    for (final p in parts.take(3)) {
      final t = p.trim();
      final name = t.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      final score = RegExp(r'\(([^)]*)\)').firstMatch(t)?.group(1) ?? '';
      if (name.isNotEmpty) out.add(MapEntry(name, score));
    }
    return out;
  }

  @override
  void dispose() {
    _bounceCtl.dispose();
    _inCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;

    final String titulo       = _tituloNormalizado(widget.resultado);
    final IconData iconoTec   = _iconForResultado(widget.resultado);
    final Color accentColor   = widget.color;

    // ------------ EXPLICACIÓN (doble fuente) ------------
    final String desc = (() {
      final fromExplicacion = _groqContentFrom(widget.explicacion);
      if (fromExplicacion.isNotEmpty) return fromExplicacion;

      final fromResultado = _groqContentFrom(widget.resultado);
      if (fromResultado.isNotEmpty) return fromResultado;

      return '';
    })();

    final top3 = _extractTop3FromText(desc);

    // no hay sección inferior duplicada
    const bool _showBottomTop3Section = false;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(child: _Header(onHome: _volverInicio)),

            // HERO
            SliverToBoxAdapter(
              child: _PageWrap(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 14, vertical: 22),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12.withOpacity(.05)),
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _bounceAnim,
                          child: Container(
                            width: 58, height: 58,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(iconoTec, color: accentColor, size: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Resultado de tu test',
                                  style: Theme.of(context).textTheme.titleSmall!
                                      .copyWith(color: _muted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge!
                                    .copyWith(color: _ink, fontWeight: FontWeight.w800, height: 1.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // SOBRE LA RECOMENDACIÓN
            SliverToBoxAdapter(
              child: _PageWrap(
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: _SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Sobre la recomendación',
                          subtitle: 'Detalles personalizados según tus intereses',
                        ),
                        const SizedBox(height: 10),
                        MarkdownBody(
                          data: desc.isEmpty
                              ? '**Pronto** verás una explicación personalizada generada por ALI según tus intereses.'
                              : desc,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
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
                          ),
                          softLineBreak: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ============ BLOQUE AZUL: CARDS PEQUEÑAS ============
            SliverToBoxAdapter(
              child: Container(
                color: _lightBlue,
                child: _PageWrap(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: LayoutBuilder(
                      builder: (ctx, cts) {
                        final cols = cts.maxWidth >= 980 ? 3 : (cts.maxWidth >= 640 ? 2 : 1);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title: 'Acciones recomendadas',
                              subtitle: 'Sigue explorando y comparte tu resultado',
                              onLightBlue: true,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: cols,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              // tamaño compacto homogéneo
                              childAspectRatio: 1.6,
                              children: [
                                // 1) Agendar
                                _ServiceCard(
                                  icon: FontAwesomeIcons.calendarCheck,
                                  title: 'Agendar asesoría',
                                  desc: 'Reserva una charla rápida para resolver dudas del técnico.',
                                  cta: 'Agendar →',
                                  onTap: _openContact,
                                ),

                                // 2) Estadísticas (card)
                                _SurfaceCard(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(minHeight: 140),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.insights, color: _brand, size: 20),
                                            SizedBox(width: 8),
                                            Text('Estadísticas del test',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink,
                                                )),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text('Resumen de tus preferencias',
                                            style: TextStyle(color: _muted)),
                                        const SizedBox(height: 8),
                                        Transform.scale(
                                          scale: 0.86,
                                          alignment: Alignment.topLeft,
                                          child: _StatsGrid(pct: {
                                            'Me gusta'   : (widget.porcentajes['Me gusta'] ?? 0),
                                            'Me interesa': (widget.porcentajes['Me interesa'] ?? 0),
                                            'No me gusta': (widget.porcentajes['No me gusta'] ?? 0),
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 3) Áreas recomendadas (Top 3)
                                _ServiceCard(
                                  icon: FontAwesomeIcons.magnifyingGlass,
                                  title: 'Áreas que también te pueden gustar',
                                  desc: 'Este es el top 3 de especialidades donde también mostraste interés.',
                                  cta: 'Ver top 3 →',
                                  onTap: () => _showTop3(context, top3),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // No hay sección inferior duplicada:
            if (false && _showBottomTop3Section) const SliverToBoxAdapter(child: SizedBox.shrink()),

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

  void _showTop3(BuildContext context, List<MapEntry<String, String>> items) {
    if (items.isEmpty) {
      _notImplemented();
      return;
    }

    // Diálogo centrado (más arriba y centrado visualmente)
    showGeneralDialog(
      context: context,
      barrierLabel: 'Top 3',
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) {
        final media = MediaQuery.of(ctx).size;
        final maxW = media.width.clamp(320, 720);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxW.toDouble(),
                maxHeight: media.height * 0.5,
              ),
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 240),
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 26, offset: Offset(0, 12)),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium, color: _brand),
                            const SizedBox(width: 8),
                            Text('Áreas que también te pueden gustar',
                                style: Theme.of(ctx).textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.w700, color: _ink)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close, color: _muted),
                              tooltip: 'Cerrar',
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Este es el top 3 de las especialidades donde también mostraste interés.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final e = items[i];
                              return ListTile(
                                leading: const Icon(Icons.star, color: _brand),
                                title: Text(e.key,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                                trailing: e.value.isEmpty
                                    ? null
                                    : Text(e.value, style: const TextStyle(color: _muted)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }

  // ================= PDF: exporta recomendación + estadísticas =================
  Future<void> _exportToPdf(String titulo, String markdown, Map<String, double> pct) async {
    try {
      // Cargar fuentes TTF desde assets (Unicode)
      final baseData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final base = pw.Font.ttf(baseData);
      final bold = pw.Font.ttf(boldData);

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: base, bold: bold),
      );

      final plain = _plainFromMarkdown(
        markdown.isEmpty
            ? 'Pronto veras una explicacion personalizada generada por ALI segun tus intereses.'
            : markdown,
      );

      pw.Widget _statRow(String k, double v) {
        final vv = v.clamp(0, 100);
        final val = vv.toStringAsFixed(0) + '%';
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(child: pw.Text(k, style: const pw.TextStyle(fontSize: 12))),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 200, height: 8,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(20),
                color: pdf.PdfColor.fromInt(0xFFE9F2FF),
              ),
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(
                  width: (vv / 100) * 200,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(20),
                    color: pdf.PdfColor.fromInt(0xFF1465BB),
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(val, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        );
      }

      // MultiPage pagina automáticamente (evita overflow)
      doc.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
          build: (ctx) => [
            pw.Text('ALI ORIENTADOR',
                style: pw.TextStyle(fontSize: 12, color: pdf.PdfColor.fromInt(0xFF6B7280))),
            pw.SizedBox(height: 6),
            pw.Text('Resultado de tu test',
                style: pw.TextStyle(fontSize: 16, color: pdf.PdfColor.fromInt(0xFF6B7280))),
            pw.SizedBox(height: 2),
            pw.Text(titulo, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdf.PdfColor.fromInt(0xFFFFFFFF),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: pdf.PdfColor.fromInt(0x11000000)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Sobre la recomendación',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(plain, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdf.PdfColor.fromInt(0xFFE9F2FF),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estadísticas del test',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  _statRow('Me gusta', (pct['Me gusta'] ?? 0)),
                  pw.SizedBox(height: 8),
                  _statRow('Me interesa', (pct['Me interesa'] ?? 0)),
                  pw.SizedBox(height: 8),
                  _statRow('No me gusta', (pct['No me gusta'] ?? 0)),
                ],
              ),
            ),

            pw.SizedBox(height: 22),
            pw.Text('© 2025 ALI Orientadora',
                style: pw.TextStyle(fontSize: 10, color: pdf.PdfColor.fromInt(0xFF9CA3AF))),
          ],
        ),
      );

      final bytes = await doc.save();

      // Descarga/compartir (todas las plataformas)
      await Printing.sharePdf(bytes: bytes, filename: 'ALI_resultado.pdf');

      // Fallback (algunos navegadores)
      await Printing.layoutPdf(onLayout: (format) async => bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado. Revisa la descarga o el diálogo del navegador.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar el PDF. ($e)')),
      );
    }
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

class _PageWrap extends StatelessWidget {
  final Widget child;
  const _PageWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(child.hashCode),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12.withOpacity(.05)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool onLightBlue;
  const _SectionHeader({required this.title, this.subtitle, this.onLightBlue = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w800, color: _ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(color: onLightBlue ? _ink.withOpacity(.7) : _muted)),
        ]
      ],
    );
  }
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 140),
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
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withOpacity(.12),
      side: BorderSide(color: color.withOpacity(.35)),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, double> pct;
  const _StatsGrid({required this.pct});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> col = {
      'Me gusta'   : const Color(0xFF10B981),
      'Me interesa': const Color(0xFF0ea5e9),
      'No me gusta': Colors.redAccent,
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
              : k == 'Me interesa'
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.thumbsDown,
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

class _Top3Strip extends StatelessWidget {
  final List<MapEntry<String, String>> items;
  const _Top3Strip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: items.map((e) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _lightBlue.withOpacity(.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brand.withOpacity(.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, color: _brand, size: 18),
              const SizedBox(width: 8),
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
              if (e.value.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('(${e.value})', style: const TextStyle(color: _muted)),
              ],
            ],
          ),
        );
      }).toList(),
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

/* ========================= MARKDOWN EXPANDIBLE (no se usa aquí) ========================= */

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

    return MarkdownBody(
      data: content,
      styleSheet: _sheet(context),
      softLineBreak: true,
    );
  }
}

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
        const Positioned.fill(child: IgnorePointer(child: SizedBox())),
      ],
    );
  }
}

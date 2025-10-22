import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'detalle_resultado_test9_screen.dart';

class HistorialTestGrado9Screen extends StatefulWidget {
  const HistorialTestGrado9Screen({super.key});

  @override
  State<HistorialTestGrado9Screen> createState() => _HistorialTestGrado9ScreenState();
}

class _HistorialTestGrado9ScreenState extends State<HistorialTestGrado9Screen> {
  final ApiService api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  String _filtro = 'Todos';
  String _query = '';

  // Solo para el % mostrado en el pill
  static const int kTotalPreguntasGrado9 = 40;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.listarMisTestsGrado9();
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extraerTecnico(String? resultado) {
    if (resultado == null) return '—';
    // Formato backend: "Técnico sugerido por ALI: X\n\nExplicación: ..."
    final idx = resultado.indexOf(':');
    if (idx != -1) {
      final linea = resultado.split('\n').first;
      final partes = linea.split(':');
      if (partes.length >= 2) return partes[1].trim();
    }
    return '—';
  }

  DateTime? _parseFecha(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  List<String> get _tecnicosDisponibles {
    final set = <String>{};
    for (final it in _items) {
      set.add(_extraerTecnico(it['resultado'] as String?));
    }
    final list = set.where((e) => e != '—').toList()..sort();
    return ['Todos', ...list];
  }

  // ─────────────── UI helpers ───────────────
  Color _badgeColor(String m) {
    final s = m.toLowerCase();
    if (s.contains('agro')) return const Color(0xFF22C55E);
    if (s.contains('indus')) return const Color(0xFF6366F1);
    if (s.contains('comerc')) return const Color(0xFF06B6D4);
    if (s.contains('promoc')) return const Color(0xFFF97316);
    return const Color(0xFF94A3B8);
  }

  IconData _badgeIcon(String m) {
    final s = m.toLowerCase();
    if (s.contains('agro')) return Icons.agriculture;
    if (s.contains('indus')) return Icons.factory;
    if (s.contains('comerc')) return Icons.storefront;
    if (s.contains('promoc')) return Icons.diversity_3;
    return Icons.school;
  }

  bool _tieneFaltantes(String? resultado) {
    if (resultado == null) return false;
    final s = resultado.toLowerCase();
    return s.contains('faltan respuestas') ||
        s.contains('incomplet') ||
        s.contains('respuestas faltantes') ||
        s.contains('pendiente completar');
  }

  // Progreso (0..1) para el % del pill
  double _progresoDe(Map<String, dynamic> it) {
    final p = it['progreso'];
    if (p is num) {
      final v = p > 1 ? (p / 100.0) : p.toDouble();
      return v.clamp(0.0, 1.0);
    }
    final respuestas = it['respuestas'];
    int contestadas = 0;
    if (respuestas is Map) contestadas = respuestas.length;
    if (respuestas is List) contestadas = respuestas.length;
    if (contestadas > 0 && kTotalPreguntasGrado9 > 0) {
      return (contestadas / kTotalPreguntasGrado9).clamp(0.0, 1.0);
    }
    final resultado = it['resultado'] as String?;
    if (resultado != null && resultado.trim().isNotEmpty) return 1.0;
    return 0.0;
  }

  String _estadoDe(double progreso, String? resultado) {
    if (progreso >= 0.999 || (resultado != null && resultado.trim().isNotEmpty)) {
      return 'Completado';
    }
    if (progreso > 0.0) return 'En curso';
    return 'Sin iniciar';
  }

  // Bottom sheet con buscador + filtro de técnico
  void _abrirBuscador() {
    final controller = TextEditingController(text: _query);
    String selFiltro = _filtro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por técnico, intento o fecha…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onSubmitted: (_) {
                  setState(() => _query = controller.text.trim());
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selFiltro,
                items: _tecnicosDisponibles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => selFiltro = v ?? 'Todos',
                decoration: InputDecoration(
                  labelText: 'Filtrar por técnico',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          _query = '';
                          _filtro = 'Todos';
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _query = controller.text.trim();
                          _filtro = selFiltro;
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial (Grado 9)'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Buscar / Filtrar',
            onPressed: _abrirBuscador,
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: const [
                      SizedBox(height: 32),
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Ocurrió un error al cargar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  )
                : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    // 1) Filtro por técnico
    var filtrados = _filtro == 'Todos'
        ? _items
        : _items.where((e) => _extraerTecnico(e['resultado'] as String?) == _filtro).toList();

    // 2) Búsqueda texto
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtrados = filtrados.where((it) {
        final resultado = (it['resultado'] as String?) ?? '';
        final tecnico = _extraerTecnico(resultado).toLowerCase();
        final id = (it['id']?.toString() ?? '').toLowerCase();
        final fecha = (it['fecha_realizacion'] as String? ?? '').toLowerCase();
        return tecnico.contains(q) || id.contains(q) || fecha.contains(q);
      }).toList();
    }

    if (filtrados.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Sin resultados con los filtros/búsqueda actuales.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        int cols = 1;
        if (w >= 1200) cols = 4;
        else if (w >= 900) cols = 3;
        else if (w >= 600) cols = 2;

        // ¿Alguna card de esta página es “alta”? (título largo o chip adicional)
        final needsTall = filtrados.any((it) {
          final titulo = _extraerTecnico(it['resultado'] as String?);
          final hayChipExtra = _tieneFaltantes(it['resultado'] as String?);
          return titulo.length > 18 || titulo.toLowerCase().contains('faltan') || hayChipExtra;
        });

        // Ratios adaptativos por columnas y altura estimada (más conservadores)
        double ratio;
        if (cols >= 4) {
          ratio = needsTall ? 1.70 : 1.95;
        } else if (cols == 3) {
          ratio = needsTall ? 1.55 : 1.75;
        } else if (cols == 2) {
          ratio = needsTall ? 1.40 : 1.55;
        } else {
          ratio = needsTall ? 1.28 : 1.42;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: ratio, // altura adaptable (sin overflow)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtrados.length,
          itemBuilder: (ctx, i) {
            final it = filtrados[i];
            final id = it['id'] as int?;
            final resultado = it['resultado'] as String?;
            final tecnico = _extraerTecnico(resultado);
            final fechaIso = it['fecha_realizacion'] as String?;
            final fecha = _parseFecha(fechaIso);
            final hace = fecha != null ? timeago.format(fecha, locale: 'es') : (fechaIso ?? '—');

            final progreso = _progresoDe(it);
            final estado = _estadoDe(progreso, resultado);

            return _ResultCard(
              indexVisual: i + 1,
              tecnico: tecnico,
              intentoId: id,
              hace: hace,
              color: _badgeColor(tecnico),
              icon: _badgeIcon(tecnico),
              faltanRespuestas: _tieneFaltantes(resultado),
              progreso: progreso,
              estado: estado,
              onOpen: id == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleResultadoTest9Screen(testId: id),
                        ),
                      );
                    },
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: resultado ?? ''));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resultado copiado')),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ———————————————— UI Card (sin barra de progreso) ————————————————
class _ResultCard extends StatelessWidget {
  final int indexVisual;
  final String tecnico;
  final int? intentoId;
  final String hace;
  final Color color;
  final IconData icon;
  final bool faltanRespuestas;
  final double progreso; // 0..1 (solo para mostrar % en el pill)
  final String estado;   // 'Completado' | 'En curso' | 'Sin iniciar'
  final VoidCallback? onOpen;
  final VoidCallback onCopy;

  const _ResultCard({
    required this.indexVisual,
    required this.tecnico,
    required this.intentoId,
    required this.hace,
    required this.color,
    required this.icon,
    required this.faltanRespuestas,
    required this.progreso,
    required this.estado,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final title = 'Técnico: $tecnico';

    Color estadoColor;
    switch (estado) {
      case 'Completado':
        estadoColor = const Color(0xFF16A34A);
        break;
      case 'En curso':
        estadoColor = const Color(0xFF2563EB);
        break;
      default:
        estadoColor = const Color(0xFF94A3B8);
    }

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Badge circular
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
            // Menú
            Positioned(
              right: 4,
              top: 0,
              child: PopupMenuButton<String>(
                onSelected: (op) {
                  if (op == 'ver' && onOpen != null) onOpen!();
                  if (op == 'copiar') onCopy();
                },
                itemBuilder: (c) => const [
                  PopupMenuItem(value: 'ver', child: Text('Ver detalle')),
                  PopupMenuItem(value: 'copiar', child: Text('Copiar resultado')),
                ],
              ),
            ),
            // Contenido
            Padding(
              // menos padding inferior y sin Spacer para no empujar al fondo
              padding: const EdgeInsets.only(left: 16, right: 16, top: 52, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título (máx 2 líneas)
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Intento #$intentoId • $hace',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pill de estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$estado • ${(progreso * 100).round()}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: estadoColor,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Acciones
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ← más compacto
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.visibility, size: 16, color: Color(0xFF667085)),
                            SizedBox(width: 6),
                            Text(
                              'Ver detalle',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (faltanRespuestas)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFA000).withOpacity(.18),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 16, color: Color(0xFFAA6B00)),
                              SizedBox(width: 6),
                              Text(
                                'Faltan respuestas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFAA6B00),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Índice abajo-derecha
            Positioned(
              right: 16,
              bottom: 8,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(.15),
                child: Text(
                  '$indexVisual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

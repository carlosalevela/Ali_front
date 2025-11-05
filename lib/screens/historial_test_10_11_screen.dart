import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'detalle_resultado_test_10_11_screen.dart';

class HistorialTestGrado1011Screen extends StatefulWidget {
  const HistorialTestGrado1011Screen({super.key});

  @override
  State<HistorialTestGrado1011Screen> createState() =>
      _HistorialTestGrado1011ScreenState();
}

class _HistorialTestGrado1011ScreenState
    extends State<HistorialTestGrado1011Screen> {
  final ApiService api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  // Búsqueda y filtro
  String _filtro = 'Todos';
  String _query = '';

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
      final data = await api.listarMisTestsGrado10y11();
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ────────────────── PARSER carrera (acepta texto largo del backend) ──────────────────
  String _carrera(String? resultado) {
    if (resultado == null) return '—';
    final r = resultado.trim();
    if (r.isEmpty) return '—';

    // Si viene como "Carrera sugerida por ALI: X\nTop-3...\nExplicación..."
    final firstLine = r.split('\n').first;
    final hasPrefix = firstLine.toLowerCase().contains('carrera sugerida');
    if (hasPrefix) {
      final idx = firstLine.indexOf(':');
      if (idx != -1 && idx + 1 < firstLine.length) {
        return firstLine.substring(idx + 1).trim();
      }
    }

    // Si ya es solo el nombre, devuélvelo tal cual
    return r;
  }

  DateTime? _parseFecha(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  // ────────────────── Catálogo fijo de carreras + 'Todos' ──────────────────
  static const List<String> _catalogoCarreras = [
    'Medicina',
    'Ingeniería',
    'Administración',
    'Psicología',
    'Derecho',
    'Educación',
    'Sistemas/Software',
    'Contaduría',
    'Diseño Gráfico',
    'Ciencias Naturales',
  ];

  List<String> get _carrerasDisponibles => ['Todos', ..._catalogoCarreras];

  // Helpers visuales
  Color _badgeColor(String m) {
    final s = m.toLowerCase();
    if (s.contains('ciencias naturales')) return const Color(0xFF22C55E);
    if (s.contains('ingenier')) return const Color(0xFF6366F1);
    if (s.contains('admin')) return const Color(0xFF06B6D4);
    if (s.contains('psicol')) return const Color(0xFFFB7185);
    if (s.contains('derech')) return const Color(0xFF8B5CF6);
    if (s.contains('educa')) return const Color(0xFF10B981);
    if (s.contains('sistemas') || s.contains('software')) {
      return const Color(0xFF0EA5E9);
    }
    if (s.contains('contad')) return const Color(0xFFF59E0B);
    if (s.contains('diseño') || s.contains('graf')) return const Color(0xFFE11D48);
    return const Color(0xFF94A3B8);
  }

  IconData _badgeIcon(String m) {
    final s = m.toLowerCase();
    if (s.contains('ciencias naturales')) return Icons.eco;
    if (s.contains('ingenier')) return Icons.settings_suggest;
    if (s.contains('admin')) return Icons.leaderboard;
    if (s.contains('psicol')) return Icons.psychology;
    if (s.contains('derech')) return Icons.gavel;
    if (s.contains('educa')) return Icons.school;
    if (s.contains('sistemas') || s.contains('software')) return Icons.memory;
    if (s.contains('contad')) return Icons.calculate;
    if (s.contains('diseño') || s.contains('graf')) return Icons.brush;
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

  // Progreso 0..1
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

    final total = (it['total_preguntas'] is num)
        ? (it['total_preguntas'] as num).toInt()
        : null;

    if (contestadas > 0 && total != null && total > 0) {
      return (contestadas / total).clamp(0.0, 1.0);
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

  // Bottom sheet de búsqueda y filtro (centrado, sin overflow)
  void _abrirBuscador() {
    final controller = TextEditingController(text: _query);
    String selFiltro = _filtro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final size = mq.size;

        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.92,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                margin: EdgeInsets.only(
                  top: size.height * 0.18,
                  bottom: mq.viewInsets.bottom + 16,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar por carrera, intento o fecha…',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onSubmitted: (_) {
                          setState(() => _query = controller.text.trim());
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selFiltro,
                        isExpanded: true, // evita overflow
                        items: _carrerasDisponibles
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => selFiltro = v ?? 'Todos',
                        decoration: InputDecoration(
                          labelText: 'Filtrar por carrera',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial (Grados 10 y 11)'),
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
                    children: [
                      const SizedBox(height: 32),
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      )
                    ],
                  )
                : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    // 1) Filtro por carrera
    var filtrados = _filtro == 'Todos'
        ? _items
        : _items
            .where(
              (e) =>
                  _catalogoMatch(_carrera(e['resultado'] as String?)) == _filtro,
            )
            .toList();

    // 2) Búsqueda (carrera, id, fecha)
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtrados = filtrados.where((it) {
        final carrera = _carrera(it['resultado'] as String?).toLowerCase();
        final id = (it['id']?.toString() ?? '').toLowerCase();
        final fecha = (it['fecha_realizacion'] as String? ?? '').toLowerCase();
        return carrera.contains(q) || id.contains(q) || fecha.contains(q);
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
        if (w >= 1200) {
          cols = 4;
        } else if (w >= 900) {
          cols = 3;
        } else if (w >= 600) {
          cols = 2;
        }

        final needsTall = filtrados.any((it) {
          final titulo = _carrera(it['resultado'] as String?);
          final hayChipExtra = _tieneFaltantes(it['resultado'] as String?);
          return titulo.length > 18 ||
              titulo.toLowerCase().contains('faltan') ||
              hayChipExtra;
        });

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
            childAspectRatio: ratio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filtrados.length,
          itemBuilder: (ctx, i) {
            final it = filtrados[i];
            final id = it['id'] as int?;
            final resultado = it['resultado'] as String?;
            final carrera = _carrera(resultado);
            final fechaIso = it['fecha_realizacion'] as String?;
            final fecha = _parseFecha(fechaIso);
            final hace =
                fecha != null ? timeago.format(fecha, locale: 'es') : (fechaIso ?? '—');
            final progreso = _progresoDe(it);
            final estado = _estadoDe(progreso, resultado);

            return _ResultCard_1011(
              indexVisual: i + 1,
              carrera: carrera,
              intentoId: id,
              hace: hace,
              color: _badgeColor(carrera),
              icon: _badgeIcon(carrera),
              faltanRespuestas: _tieneFaltantes(resultado),
              progreso: progreso,
              estado: estado,
              onOpen: id == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetalleResultadoTest1011Screen(testId: id),
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

  // Normaliza un texto de carrera a un item del catálogo (para que el filtro funcione aunque venga variante)
  String _catalogoMatch(String? raw) {
    final x = (raw ?? '').toLowerCase();
    for (final c in _catalogoCarreras) {
      if (x.contains(c.toLowerCase())) return c;
    }
    // fallback: devuelve tal cual para que no rompa
    return raw ?? '—';
  }
}

// ———————————————— UI Card ————————————————
class _ResultCard_1011 extends StatelessWidget {
  final int indexVisual;
  final String carrera;
  final int? intentoId;
  final String hace;
  final Color color;
  final IconData icon;
  final bool faltanRespuestas;
  final double progreso; // 0..1
  final String estado; // 'Completado' | 'En curso' | 'Sin iniciar'
  final VoidCallback? onOpen;
  final VoidCallback onCopy;

  const _ResultCard_1011({
    required this.indexVisual,
    required this.carrera,
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
    final title = 'Carrera: $carrera';

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
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 52,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
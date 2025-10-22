import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'detalle_resultado_test_10_11_screen.dart';

class HistorialTestGrado1011Screen extends StatefulWidget {
  const HistorialTestGrado1011Screen({super.key});

  @override
  State<HistorialTestGrado1011Screen> createState() => _HistorialTestGrado1011ScreenState();
}

class _HistorialTestGrado1011ScreenState extends State<HistorialTestGrado1011Screen> {
  final ApiService api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _filtro = 'Todos';

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

  String _carrera(String? resultado) {
    // Para 10/11 el backend guarda solo la carrera como texto
    return (resultado == null || resultado.trim().isEmpty) ? '—' : resultado.trim();
  }

  DateTime? _parseFecha(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  List<String> get _carrerasDisponibles {
    final set = <String>{};
    for (final it in _items) {
      set.add(_carrera(it['resultado'] as String?));
    }
    final list = set.where((e) => e != '—').toList()..sort();
    return ['Todos', ...list];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests Realizados'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
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
    final filtrados = _filtro == 'Todos'
        ? _items
        : _items.where((e) => _carrera(e['resultado'] as String?) == _filtro).toList();

    return Column(
      children: [
        // Filtro por carrera (chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: _carrerasDisponibles.map((c) {
              final selected = _filtro == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _filtro = c),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Aún no hay intentos guardados.'),
                  ),
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (ctx, i) {
                    final it = filtrados[i];
                    final id = it['id'] as int?;
                    final resultado = it['resultado'] as String?;
                    final carrera = _carrera(resultado);
                    final fechaIso = it['fecha_realizacion'] as String?;
                    final fecha = _parseFecha(fechaIso);
                    final hace = fecha != null
                        ? timeago.format(fecha, locale: 'es')
                        : (fechaIso ?? '—');

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text((i + 1).toString()),
                      ),
                      title: Text(
                        'Carrera: $carrera',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Intento #$id • $hace'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (op) async {
                          if (op == 'ver' && id != null) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleResultadoTest1011Screen(testId: id),
                              ),
                            );
                          } else if (op == 'copiar') {
                            await Clipboard.setData(ClipboardData(text: resultado ?? ''));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Resultado copiado')),
                            );
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'ver', child: Text('Ver detalle')),
                          PopupMenuItem(value: 'copiar', child: Text('Copiar resultado')),
                        ],
                      ),
                      onTap: id == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleResultadoTest1011Screen(testId: id),
                                ),
                              ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

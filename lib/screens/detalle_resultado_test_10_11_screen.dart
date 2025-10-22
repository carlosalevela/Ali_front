import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DetalleResultadoTest1011Screen extends StatefulWidget {
  final int testId;
  const DetalleResultadoTest1011Screen({super.key, required this.testId});

  @override
  State<DetalleResultadoTest1011Screen> createState() => _DetalleResultadoTest1011ScreenState();
}

class _DetalleResultadoTest1011ScreenState extends State<DetalleResultadoTest1011Screen> {
  final ApiService api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await api.obtenerResultadoTest1011PorId(widget.testId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _data = res['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['error']?.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Test #${widget.testId} (10/11)'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        )
                      ],
                    ),
                  ),
                )
              : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final id = _data?['id'];
    final fecha = _data?['fecha_realizacion'] ?? '—';
    final resultado = _data?['resultado'] ?? '—';
    final respuestas = _data?['respuestas']; // si tu serializer las incluye

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text('Test #$id'),
            subtitle: Text('Fecha: $fecha'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText(
              resultado.toString(),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        if (respuestas != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: const Text('Respuestas (opcional)'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(respuestas.toString()),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

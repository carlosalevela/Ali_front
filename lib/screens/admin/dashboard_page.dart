// lib/screens/admin/dashboard_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  
  Map<String, dynamic> _stats = {
    'totalEstudiantes': 0,
    'totalProfesores': 0,
    'testsCompletados': 0,
    'testsPendientes': 0,
    'grado9': 0,
    'grado10': 0,
    'grado11': 0,
  };

  List<Map<String, dynamic>> _tecnicosTop = [];
  List<Map<String, dynamic>> _carrerasTop = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final usuarios = await _api.fetchUsuarios();
      
      final estudiantes = usuarios.where((u) => u['rol'] == 'estudiante').toList();
      final profesores = usuarios.where((u) => u['rol'] == 'admin').toList();
      
      final grado9 = estudiantes.where((e) => e['grado'] == 9).length;
      final grado10 = estudiantes.where((e) => e['grado'] == 10).length;
      final grado11 = estudiantes.where((e) => e['grado'] == 11).length;

      // Obtener tests finalizados
      final tests9 = await _api.fetchTestsGrado9(estado: 'FINALIZADO', orden: null, limit: 100, offset: 0);
      final tests1011 = await _api.fetchTestsGrado10y11(estado: 'FINALIZADO', orden: null, limit: 100, offset: 0);

      // Top técnicos
      final Map<String, int> tecCounts = {};
      for (final t in tests9) {
        final tec = _parseTecnico(t['resultado']?.toString());
        tecCounts[tec] = (tecCounts[tec] ?? 0) + 1;
      }
      final tecList = tecCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Top carreras
      final Map<String, int> carCounts = {};
      for (final t in tests1011) {
        final car = (t['resultado']?.toString().trim().isEmpty ?? true)
            ? 'Desconocido'
            : t['resultado'].toString().trim();
        carCounts[car] = (carCounts[car] ?? 0) + 1;
      }
      final carList = carCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _stats = {
          'totalEstudiantes': estudiantes.length,
          'totalProfesores': profesores.length,
          'testsCompletados': tests9.length + tests1011.length,
          'testsPendientes': estudiantes.length - (tests9.length + tests1011.length),
          'grado9': grado9,
          'grado10': grado10,
          'grado11': grado11,
        };
        _tecnicosTop = tecList.take(4).toList();
        _carrerasTop = carList.take(4).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
      setState(() => _loading = false);
    }
  }

  String _parseTecnico(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Desconocido';
    const tag = 'Técnico sugerido por ALI:';
    final i = raw.indexOf(tag);
    if (i >= 0) {
      final rest = raw.substring(i + tag.length).trim();
      final first = rest.split(RegExp(r'[\n\r]')).first.trim();
      if (first.isNotEmpty) return first;
    }
    for (final op in ['Industrial', 'Comercio', 'Promoción Social', 'Agropecuaria']) {
      if (raw.contains(op)) return op;
    }
    return 'Desconocido';
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 32, color: color),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+5%',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(String title, List<Map<String, dynamic>> items, Color color) {
    if (items.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      );
    }

    final maxCount = items.first['count'] as int;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...items.map((item) {
              final name = item['name'] as String;
              final count = item['count'] as int;
              final progress = maxCount > 0 ? count / maxCount : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Métricas principales
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        'Estudiantes',
                        '${_stats['totalEstudiantes']}',
                        Icons.school,
                        Colors.blue,
                      ),
                      _buildMetricCard(
                        'Profesores',
                        '${_stats['totalProfesores']}',
                        Icons.person,
                        Colors.green,
                      ),
                      _buildMetricCard(
                        'Tests Completados',
                        '${_stats['testsCompletados']}',
                        Icons.check_circle,
                        Colors.purple,
                      ),
                      _buildMetricCard(
                        'Tests Pendientes',
                        '${_stats['testsPendientes']}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Distribución por grado
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Distribución por Grado',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildGradePill('9°', _stats['grado9'], Colors.blue),
                              _buildGradePill('10°', _stats['grado10'], Colors.green),
                              _buildGradePill('11°', _stats['grado11'], Colors.purple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top técnicos y carreras
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTopList('Top Técnicos', _tecnicosTop, Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTopList('Top Carreras', _carrerasTop, Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGradePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            'estudiantes',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

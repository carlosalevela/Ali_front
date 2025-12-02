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

      final tests9 = await _api.fetchTestsGrado9(estado: 'FINALIZADO', limit: 100, offset: 0);
      final tests1011 = await _api.fetchTestsGrado10y11(estado: 'FINALIZADO', limit: 100, offset: 0);

      final Map<String, int> tecCounts = {};
      for (final t in tests9) {
        final tec = _parseTecnico(t['resultado']?.toString());
        tecCounts[tec] = (tecCounts[tec] ?? 0) + 1;
      }
      final tecList = tecCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      final Map<String, int> carCounts = {};
      for (final t in tests1011) {
        final car = _parseCarrera(t['resultado']?.toString());
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

  String _parseCarrera(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Desconocido';
    
    const tag = 'Carrera sugerida por ALI:';
    final i = raw.indexOf(tag);
    if (i >= 0) {
      final rest = raw.substring(i + tag.length).trim();
      final lines = rest.split(RegExp(r'[\n\r]|Top-3:'));
      final carrera = lines.first.trim();
      if (carrera.isNotEmpty) return carrera;
    }
    
    final firstLine = raw.split(RegExp(r'[\n\r]')).first.trim();
    if (firstLine.isNotEmpty && !firstLine.contains('¡Hola!')) return firstLine;
    
    return 'Desconocido';
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {bool isDesktop = true}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: isDesktop ? 28 : 24, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '+5%',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: isDesktop ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(String title, List<Map<String, dynamic>> items, Color color, IconData icon, {bool isDesktop = true}) {
    if (items.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Sin datos', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxCount = items.first['count'] as int;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 10,
                      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final isMobile = screenWidth < 768;
    
    final metricsColumns = isDesktop ? 4 : (isTablet ? 2 : 1);
    final metricsAspectRatio = isDesktop ? 1.5 : (isTablet ? 1.6 : 2.0);
    
    final padding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ Header mejorado con botón visible
                if (isDesktop) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Bienvenido de nuevo!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // ⭐ Botón mejorado con colores visibles
                      ElevatedButton.icon(
                        onPressed: _cargarDatos,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Actualizar',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1465BB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Métricas principales
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: metricsColumns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: metricsAspectRatio,
                  children: [
                    _buildMetricCard(
                      'Estudiantes',
                      '${_stats['totalEstudiantes']}',
                      Icons.school_rounded,
                      const Color(0xFF3B82F6),
                      isDesktop: isDesktop,
                    ),
                    _buildMetricCard(
                      'Profesores',
                      '${_stats['totalProfesores']}',
                      Icons.person_rounded,
                      const Color(0xFF10B981),
                      isDesktop: isDesktop,
                    ),
                    _buildMetricCard(
                      'Tests Completados',
                      '${_stats['testsCompletados']}',
                      Icons.check_circle_rounded,
                      const Color(0xFF8B5CF6),
                      isDesktop: isDesktop,
                    ),
                    _buildMetricCard(
                      'Tests Pendientes',
                      '${_stats['testsPendientes']}',
                      Icons.pending_rounded,
                      const Color(0xFFF59E0B),
                      isDesktop: isDesktop,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Distribución por grado
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Distribución por Grado',
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        isMobile
                            ? Column(
                                children: [
                                  _buildGradePill('9°', _stats['grado9'], const Color(0xFF3B82F6)),
                                  const SizedBox(height: 12),
                                  _buildGradePill('10°', _stats['grado10'], const Color(0xFF10B981)),
                                  const SizedBox(height: 12),
                                  _buildGradePill('11°', _stats['grado11'], const Color(0xFF8B5CF6)),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: _buildGradePill('9°', _stats['grado9'], const Color(0xFF3B82F6)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGradePill('10°', _stats['grado10'], const Color(0xFF10B981)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGradePill('11°', _stats['grado11'], const Color(0xFF8B5CF6)),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Top técnicos y carreras
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTopList(
                          'Top Técnicos',
                          _tecnicosTop,
                          const Color(0xFF3B82F6),
                          Icons.engineering_rounded,
                          isDesktop: true,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTopList(
                          'Top Carreras',
                          _carrerasTop,
                          const Color(0xFF10B981),
                          Icons.school_rounded,
                          isDesktop: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildTopList(
                    'Top Técnicos',
                    _tecnicosTop,
                    const Color(0xFF3B82F6),
                    Icons.engineering_rounded,
                    isDesktop: false,
                  ),
                  const SizedBox(height: 24),
                  _buildTopList(
                    'Top Carreras',
                    _carrerasTop,
                    const Color(0xFF10B981),
                    Icons.school_rounded,
                    isDesktop: false,
                  ),
                ],
              ],
            ),
          );
  }

  Widget _buildGradePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'estudiantes',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

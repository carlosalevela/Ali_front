// lib/screens/admin/analiticas_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../services/api_service.dart';

class AnaliticasPage extends StatefulWidget {
  const AnaliticasPage({super.key});

  @override
  State<AnaliticasPage> createState() => _AnaliticasPageState();
}

class _AnaliticasPageState extends State<AnaliticasPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  bool _loading = true;
  DateTimeRange? _dateRange;
  
  Map<String, dynamic> _data = {
    'totalTests9': 0,
    'totalTests1011': 0,
    'finalizados9': 0,
    'finalizados1011': 0,
    'porTecnico': <Map<String, dynamic>>[],
    'porCarrera': <Map<String, dynamic>>[],
    'porDia': <Map<String, dynamic>>[],
    'estudiantes': {'9': 0, '10': 0, '11': 0},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      // Cargar estudiantes
      final usuarios = await _api.fetchUsuarios();
      final estudiantes = usuarios.where((u) => u['rol'] == 'estudiante').toList();
      
      final est9 = estudiantes.where((e) => e['grado'] == 9).length;
      final est10 = estudiantes.where((e) => e['grado'] == 10).length;
      final est11 = estudiantes.where((e) => e['grado'] == 11).length;

      // Cargar tests
      final tests9 = await _api.fetchTestsGrado9(estado: null, orden: null, limit: 2000, offset: 0);
      final tests1011 = await _api.fetchTestsGrado10y11(estado: null, orden: null, limit: 2000, offset: 0);

      // Filtrar por rango
      final tests9Filtrados = tests9.where((t) => _enRango(t)).toList();
      final tests1011Filtrados = tests1011.where((t) => _enRango(t)).toList();

      // Finalizados
      final fin9 = tests9Filtrados.where((t) => _esFinalizado(t)).toList();
      final fin1011 = tests1011Filtrados.where((t) => _esFinalizado(t)).toList();

      // Por técnico (grado 9)
      final Map<String, int> tecCounts = {};
      for (final t in fin9) {
        final tec = _parseTecnico(t['resultado']?.toString());
        tecCounts[tec] = (tecCounts[tec] ?? 0) + 1;
      }
      final tecList = tecCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Por carrera (10/11)
      final Map<String, int> carCounts = {};
      for (final t in fin1011) {
        final car = (t['resultado']?.toString().trim().isEmpty ?? true)
            ? 'Desconocido'
            : t['resultado'].toString().trim();
        carCounts[car] = (carCounts[car] ?? 0) + 1;
      }
      final carList = carCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Por día
      final Map<String, int> porDia = {};
      for (final t in [...fin9, ...fin1011]) {
        final fecha = _fechaTest(t);
        if (fecha != null) {
          final key = DateFormat('yyyy-MM-dd').format(fecha);
          porDia[key] = (porDia[key] ?? 0) + 1;
        }
      }
      final porDiaList = porDia.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      setState(() {
        _data = {
          'totalTests9': tests9Filtrados.length,
          'totalTests1011': tests1011Filtrados.length,
          'finalizados9': fin9.length,
          'finalizados1011': fin1011.length,
          'porTecnico': tecList,
          'porCarrera': carList,
          'porDia': porDiaList,
          'estudiantes': {'9': est9, '10': est10, '11': est11},
        };
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando analíticas: $e');
      setState(() => _loading = false);
    }
  }

  bool _enRango(Map<String, dynamic> test) {
    final fecha = _fechaTest(test);
    if (fecha == null || _dateRange == null) return false;
    return !fecha.isBefore(_dateRange!.start) && !fecha.isAfter(_dateRange!.end);
  }

  bool _esFinalizado(Map<String, dynamic> test) {
    final estado = (test['estado'] ?? '').toString().toUpperCase();
    return estado == 'FINALIZADO' || estado == 'COMPLETADO';
  }

  DateTime? _fechaTest(Map<String, dynamic> test) {
    final str = test['fecha_realizacion']?.toString() ?? test['fecha_inicio']?.toString();
    if (str == null) return null;
    return DateTime.tryParse(str);
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

  Future<void> _seleccionarRango() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _cargarDatos();
    }
  }

  Future<void> _exportarExcel() async {
    final ex.Excel wb = ex.Excel.createExcel();
    
    // Hoja de resumen
    final sh1 = wb['Resumen'];
    sh1.appendRow(['Métrica', 'Valor']);
    sh1.appendRow(['Tests 9° (rango)', _data['totalTests9']]);
    sh1.appendRow(['Tests 10/11 (rango)', _data['totalTests1011']]);
    sh1.appendRow(['Finalizados 9°', _data['finalizados9']]);
    sh1.appendRow(['Finalizados 10/11', _data['finalizados1011']]);

    // Hoja técnicos
    final sh2 = wb['Técnicos'];
    sh2.appendRow(['Técnico', 'Conteo']);
    for (final t in _data['porTecnico'] as List) {
      sh2.appendRow([t['name'], t['count']]);
    }

    // Hoja carreras
    final sh3 = wb['Carreras'];
    sh3.appendRow(['Carrera', 'Conteo']);
    for (final c in _data['porCarrera'] as List) {
      sh3.appendRow([c['name'], c['count']]);
    }

    // Hoja por día
    final sh4 = wb['Por Día'];
    sh4.appendRow(['Fecha', 'Finalizados']);
    for (final d in _data['porDia'] as List) {
      sh4.appendRow([d['date'], d['count']]);
    }

    final bytes = Uint8List.fromList(wb.encode()!);
    await FileSaver.instance.saveFile(
      'analiticas_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      bytes,
      'xlsx',
      mimeType: MimeType.MICROSOFTEXCEL,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel exportado exitosamente')),
      );
    }
  }

  Widget _buildResumenTab() {
    final estudiantes = _data['estudiantes'] as Map;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2,
          children: [
            _buildStatCard('Tests 9° (rango)', '${_data['totalTests9']}', Icons.quiz, Colors.blue),
            _buildStatCard('Tests 10/11 (rango)', '${_data['totalTests1011']}', Icons.quiz, Colors.green),
            _buildStatCard('Finalizados 9°', '${_data['finalizados9']}', Icons.check_circle, Colors.purple),
            _buildStatCard('Finalizados 10/11', '${_data['finalizados1011']}', Icons.check_circle, Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distribución de Estudiantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildBarChart([
                  {'label': 'Grado 9°', 'value': estudiantes['9'], 'color': Colors.blue},
                  {'label': 'Grado 10°', 'value': estudiantes['10'], 'color': Colors.green},
                  {'label': 'Grado 11°', 'value': estudiantes['11'], 'color': Colors.purple},
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTecnicosCarrerasTab() {
    final tecnicos = _data['porTecnico'] as List<Map<String, dynamic>>;
    final carreras = _data['porCarrera'] as List<Map<String, dynamic>>;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Técnicos (Grado 9°)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...tecnicos.take(5).map((t) => _buildProgressBar(
                  t['name'] as String,
                  t['count'] as int,
                  tecnicos.isNotEmpty ? tecnicos.first['count'] as int : 1,
                  Colors.blue,
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Carreras (10°/11°)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...carreras.take(5).map((c) => _buildProgressBar(
                  c['name'] as String,
                  c['count'] as int,
                  carreras.isNotEmpty ? carreras.first['count'] as int : 1,
                  Colors.green,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTendenciasTab() {
    final porDia = _data['porDia'] as List<Map<String, dynamic>>;
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tests Finalizados por Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: porDia.isEmpty
                      ? const Center(child: Text('Sin datos en el rango seleccionado', style: TextStyle(color: Colors.grey)))
                      : CustomPaint(
                          painter: LineChartPainter(porDia),
                          child: Container(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int max, Color color) {
    final progress = max > 0 ? value / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final maxValue = data.map((e) => e['value'] as int).reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: data.map((item) {
        final label = item['label'] as String;
        final value = item['value'] as int;
        final color = item['color'] as Color;
        final progress = maxValue > 0 ? value / maxValue : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _dateRange != null
        ? '${DateFormat('d MMM', 'es').format(_dateRange!.start)} - ${DateFormat('d MMM yyyy', 'es').format(_dateRange!.end)}'
        : 'Seleccionar rango';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analíticas'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(rangeText),
            onPressed: _seleccionarRango,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportarExcel,
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Técnicos/Carreras'),
            Tab(text: 'Tendencias'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResumenTab(),
                _buildTecnicosCarrerasTab(),
                _buildTendenciasTab(),
              ],
            ),
    );
  }
}

// Simple line chart painter
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final maxValue = data.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth / (data.length - 1)) * i;
      final y = size.height - padding - (chartHeight * (data[i]['count'] as int) / maxValue);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    canvas.drawLine(Offset(padding, size.height - padding), Offset(size.width - padding, size.height - padding), axisPaint);
    canvas.drawLine(Offset(padding, padding), Offset(padding, size.height - padding), axisPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

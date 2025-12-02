import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DetalleResultadoTest9Screen extends StatefulWidget {
  final int testId;
  const DetalleResultadoTest9Screen({super.key, required this.testId});

  @override
  State<DetalleResultadoTest9Screen> createState() => _DetalleResultadoTest9ScreenState();
}

class _DetalleResultadoTest9ScreenState extends State<DetalleResultadoTest9Screen> {
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
    final res = await api.obtenerResultadoTest9PorId(widget.testId);
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

  // Función para analizar las respuestas y contar categorías
  Map<String, int> _analizarRespuestas() {
    final respuestas = _data?['respuestas'];
    int meGusta = 0;
    int meInteresa = 0;
    int noMeGusta = 0;

    if (respuestas is Map) {
      respuestas.forEach((key, value) {
        final valorStr = value.toString().toUpperCase();
        if (valorStr.contains('A')) {
          meGusta++;
        } else if (valorStr.contains('B')) {
          meInteresa++;
        } else if (valorStr.contains('C')) {
          noMeGusta++;
        }
      });
    }

    return {
      'Me gusta': meGusta,
      'Me interesa': meInteresa,
      'No me gusta': noMeGusta,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8), // Fondo celeste claro como tu inicio
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF64B5F6), // Azul claro
        title: Text(
          'Detalle Test #${widget.testId}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando resultados...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ups, algo salió mal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64B5F6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final id = _data?['id'];
    final fecha = _data?['fecha_realizacion'] ?? '—';
    final resultado = _data?['resultado'] ?? '—';
    final conteoRespuestas = _analizarRespuestas();

    // Responsive: detectar ancho de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    // Ajustar padding según tamaño
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: Column(
              children: [
                // Header Card con fondo celeste - Responsive
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isTablet ? 28 : 20),
                  child: isTablet
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildHeaderInfo(id, fecha)),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildHeaderInfo(id, fecha),
                          ],
                        ),
                ),

                const SizedBox(height: 20),

                // Card de Resultado - Responsive
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64B5F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Resultado del Test',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        child: SelectableText(
                          resultado.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card con Gráfico Circular - Responsive
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isTablet ? 28 : 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pie_chart_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Análisis de Respuestas',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                      SizedBox(
                        height: isDesktop ? 280 : (isTablet ? 240 : 200),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: isDesktop ? 70 : (isTablet ? 65 : 55),
                            sections: _buildPieChartSections(conteoRespuestas, isTablet),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                      _buildLegend(conteoRespuestas),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Footer decorativo
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFF64B5F6),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resultado verificado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(int? id, String fecha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test #$id',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              fecha,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> conteo, bool isTablet) {
    final meGusta = conteo['Me gusta'] ?? 0;
    final meInteresa = conteo['Me interesa'] ?? 0;
    final noMeGusta = conteo['No me gusta'] ?? 0;
    final total = meGusta + meInteresa + noMeGusta;
    final radius = isTablet ? 55.0 : 48.0;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'Sin datos',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: const Color(0xFF4CAF50), // Verde
        value: meGusta.toDouble(),
        title: '${((meGusta / total) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFF64B5F6), // Azul celeste
        value: meInteresa.toDouble(),
        title: '${((meInteresa / total) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFFF7043), // Naranja/coral
        value: noMeGusta.toDouble(),
        title: '${((noMeGusta / total) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegend(Map<String, int> conteo) {
    final meGusta = conteo['Me gusta'] ?? 0;
    final meInteresa = conteo['Me interesa'] ?? 0;
    final noMeGusta = conteo['No me gusta'] ?? 0;

    return Column(
      children: [
        _buildLegendItem('Me gusta', meGusta, const Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        _buildLegendItem('Me interesa', meInteresa, const Color(0xFF64B5F6)),
        const SizedBox(height: 12),
        _buildLegendItem('No me gusta', noMeGusta, const Color(0xFFFF7043)),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

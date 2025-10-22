import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Para formatear fechas
import '../services/api_service.dart';

class EstadisticasUsuarioScreen extends StatefulWidget {
  final int usuarioId;
  final String nombre;
  final int grado;

  const EstadisticasUsuarioScreen({
    super.key,
    required this.usuarioId,
    required this.nombre,
    required this.grado,
  });

  @override
  State<EstadisticasUsuarioScreen> createState() => _EstadisticasUsuarioScreenState();
}

class _EstadisticasUsuarioScreenState extends State<EstadisticasUsuarioScreen> {
  bool isLoading = true;
  List<dynamic> tests = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final api = ApiService();
      List<dynamic> resultados = [];
      if (widget.grado == 9) {
        resultados = await api.fetchTestsGrado9PorUsuario(widget.usuarioId);
      } else if (widget.grado == 10 || widget.grado == 11) {
        resultados = await api.fetchTestsGrado10y11PorUsuario(widget.usuarioId);
      }
      setState(() {
        tests = resultados;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Error al cargar estadísticas: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _mostrarResultadoIndividual(int testId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Cargando...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final api = ApiService();
      Map<String, dynamic> resultado = {};

      if (widget.grado == 9) {
        resultado = await api.fetchResultadoTest9PorId(testId);
      } else if (widget.grado == 10 || widget.grado == 11) {
        resultado = await api.fetchResultadoTest10y11PorId(testId);
      }

      Navigator.pop(context); // cerrar "Cargando..."

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resultado del Test'),
          content: Text(resultado['resultado'] ?? 'Sin resultado disponible'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // cerrar "Cargando..."

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('No se pudo obtener el resultado: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  String _formatearFechaHora(String? fechaString) {
    if (fechaString == null) return '-';
    try {
      final fecha = DateTime.parse(fechaString).toLocal();
      return DateFormat('dd/MM/yyyy – hh:mm a').format(fecha); // formato bonito 12h
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String _tiempoTranscurrido(String? fechaString) {
    if (fechaString == null) return '';
    try {
      final fecha = DateTime.parse(fechaString).toLocal();
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inDays == 0) {
        return 'Hoy';
      } else if (diferencia.inDays == 1) {
        return 'Hace 1 día';
      } else if (diferencia.inDays < 7) {
        return 'Hace ${diferencia.inDays} días';
      } else if (diferencia.inDays < 30) {
        final semanas = (diferencia.inDays / 7).floor();
        return 'Hace $semanas semana${semanas > 1 ? 's' : ''}';
      } else if (diferencia.inDays < 365) {
        final meses = (diferencia.inDays / 30).floor();
        return 'Hace $meses mes${meses > 1 ? 'es' : ''}';
      } else {
        final anos = (diferencia.inDays / 365).floor();
        return 'Hace $anos año${anos > 1 ? 's' : ''}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoTest = widget.grado == 9 ? "Grado 9" : "Grado 10/11";

    return Scaffold(
      appBar: AppBar(title: Text('Estadísticas de ${widget.nombre}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      color: Colors.blue[50],
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('Resumen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('Cantidad de tests ($tipoTest): ${tests.length}',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                    Text('Detalle de tests de $tipoTest',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (tests.isEmpty)
                      const Center(child: Text('Este usuario no ha realizado ningún test.')),
                    ...tests.map((test) => Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.assignment,
                              color: widget.grado == 9 ? Colors.deepPurple : Colors.orange,
                            ),
                            title: Text('Test $tipoTest'),
                            subtitle: Text(
                              'Fecha: ${_formatearFechaHora(test['fecha_realizacion'])} (${_tiempoTranscurrido(test['fecha_realizacion'])})',
                            ),
                            trailing: const Icon(Icons.visibility, color: Colors.blue),
                            onTap: () async {
                              await _mostrarResultadoIndividual(test['id']);
                            },
                          ),
                        )),
                  ],
                ),
    );
  }
}

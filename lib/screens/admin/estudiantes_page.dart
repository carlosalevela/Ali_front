// lib/screens/admin/estudiantes_page.dart
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import '../../services/api_service.dart';
import './../estadisticas_screen.dart';

const int kTotalPreguntas9 = 57;
const int kTotalPreguntas10y11 = 40;

class EstudiantesPage extends StatefulWidget {
  const EstudiantesPage({super.key});

  @override
  State<EstudiantesPage> createState() => _EstudiantesPageState();
}

class _EstudiantesPageState extends State<EstudiantesPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _todosEstudiantes = [];
  List<Map<String, dynamic>> _estudiantesFiltrados = [];
  
  bool _loading = true;
  bool _cargandoProgreso = false;
  
  // Filtros
  String _gradoFiltro = 'Todos';
  String _estadoFiltro = 'Todos';
  String _searchQuery = '';
  
  // Paginación
  int _currentPage = 0;
  final int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
    _searchController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _loading = true);
    try {
      final usuarios = await _api.fetchUsuarios();
      final estudiantes = usuarios
          .where((u) => u['rol'] == 'estudiante')
          .map((u) => Map<String, dynamic>.from(u)..['estado'] = u['estado'] ?? 'Activo')
          .toList();

      setState(() {
        _todosEstudiantes = estudiantes;
        _aplicarFiltros();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar estudiantes: $e');
      setState(() => _loading = false);
    }
  }

  // ⭐ MÉTODO CORREGIDO
  Future<void> _cargarProgresoTodos() async {
    setState(() => _cargandoProgreso = true);
    try {
      int contador = 0;
      // Procesar todos los estudiantes (no solo filtrados)
      for (var estudiante in _todosEstudiantes) {
        final grado = estudiante['grado'];
        
        if (grado == 9) {
          try {
            final info = await _api.progresoUsuarioGrado9(
              estudiante['id'],
              total: kTotalPreguntas9,
            );
            estudiante['progreso'] = info['progreso'] ?? '—';
            estudiante['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';
          } catch (e) {
            debugPrint('Error cargando progreso estudiante ${estudiante['id']}: $e');
            estudiante['progreso'] = 'Error al cargar';
            estudiante['ultimaRecomendacion'] = '—';
          }
        } else if (grado == 10 || grado == 11) {
          try {
            final info = await _api.progresoUsuarioGrado10y11(
              estudiante['id'],
              total: kTotalPreguntas10y11,
            );
            estudiante['progreso'] = info['progreso'] ?? '—';
            estudiante['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';
          } catch (e) {
            debugPrint('Error cargando progreso estudiante ${estudiante['id']}: $e');
            estudiante['progreso'] = 'Error al cargar';
            estudiante['ultimaRecomendacion'] = '—';
          }
        }
        
        contador++;
        
        // Actualizar UI cada 10 estudiantes para mostrar progreso visual
        if (contador % 10 == 0 && mounted) {
          setState(() {});
        }
      }
      
      if (mounted) {
        setState(() {
          _cargandoProgreso = false;
          _aplicarFiltros(); // Refrescar filtros
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progreso cargado: $contador estudiantes procesados'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error general cargando progreso: $e');
      if (mounted) {
        setState(() => _cargandoProgreso = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar progreso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _currentPage = 0;

      _estudiantesFiltrados = _todosEstudiantes.where((e) {
        // Filtro de búsqueda
        if (_searchQuery.isNotEmpty) {
          final nombre = (e['nombre'] ?? '').toString().toLowerCase();
          final email = (e['email'] ?? '').toString().toLowerCase();
          final username = (e['username'] ?? '').toString().toLowerCase();
          if (!nombre.contains(_searchQuery) &&
              !email.contains(_searchQuery) &&
              !username.contains(_searchQuery)) {
            return false;
          }
        }

        // Filtro de grado
        if (_gradoFiltro != 'Todos') {
          if (_gradoFiltro == '10/11') {
            if (e['grado'] != 10 && e['grado'] != 11) return false;
          } else {
            if (e['grado'].toString() != _gradoFiltro) return false;
          }
        }

        // Filtro de estado
        if (_estadoFiltro != 'Todos') {
          if ((e['estado'] ?? 'Activo') != _estadoFiltro) return false;
        }

        return true;
      }).toList();
    });
  }

  List<Map<String, dynamic>> _getPaginatedData() {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _estudiantesFiltrados.length);
    if (start >= _estudiantesFiltrados.length) return [];
    return _estudiantesFiltrados.sublist(start, end);
  }

  int get _totalPages =>
      (_estudiantesFiltrados.length / _pageSize).ceil().clamp(1, 999999);

  Future<void> _exportarExcel() async {
    final ex.Excel wb = ex.Excel.createExcel();
    final ex.Sheet sh = wb['Estudiantes'];

    sh.appendRow(['ID', 'Nombre', 'Email', 'Grado', 'Estado', 'Progreso', 'Recomendación']);
    for (final e in _estudiantesFiltrados) {
      sh.appendRow([
        e['id'] ?? '',
        e['nombre'] ?? '',
        e['email'] ?? '',
        e['grado'] ?? '',
        e['estado'] ?? '',
        e['progreso'] ?? '—',
        e['ultimaRecomendacion'] ?? '—',
      ]);
    }

    final bytes = Uint8List.fromList(wb.encode()!);
    await FileSaver.instance.saveFile(
      'estudiantes_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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

  Future<void> _toggleEstado(Map<String, dynamic> estudiante) async {
    final nuevoEstado = estudiante['estado'] == 'Activo' ? 'Inactivo' : 'Activo';
    final ok = await _api.editarUsuario(estudiante['id'], {'estado': nuevoEstado});
    if (ok && mounted) {
      setState(() {
        estudiante['estado'] = nuevoEstado;
      });
    }
  }

  Future<void> _editarEstudiante(Map<String, dynamic> estudiante) async {
    final nombreCtrl = TextEditingController(text: estudiante['nombre']);
    final emailCtrl = TextEditingController(text: estudiante['email']);
    final gradoCtrl = TextEditingController(text: estudiante['grado']?.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Estudiante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: gradoCtrl,
              decoration: const InputDecoration(labelText: 'Grado'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await _api.editarUsuario(estudiante['id'], {
                'nombre': nombreCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'grado': int.tryParse(gradoCtrl.text.trim()),
              });
              if (ok && mounted) {
                Navigator.pop(ctx);
                _cargarEstudiantes();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarEstudiante(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar estudiante?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await _api.deleteUsuario(id);
      if (ok) _cargarEstudiantes();
    }
  }

  void _verEstadisticas(Map<String, dynamic> estudiante) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstadisticasUsuarioScreen(
          usuarioId: estudiante['id'],
          nombre: estudiante['nombre'] ?? estudiante['username'],
          grado: estudiante['grado'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedData = _getPaginatedData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestión de Estudiantes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_cargandoProgreso)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: _cargarEstudiantes,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Cargar progreso',
            onPressed: _cargandoProgreso ? null : _cargarProgresoTodos,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Excel',
            onPressed: _exportarExcel,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de filtros
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, email o usuario...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _gradoFiltro,
                        items: ['Todos', '9', '10', '11', '10/11']
                            .map((g) => DropdownMenuItem(value: g, child: Text('Grado: $g')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _gradoFiltro = val!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _estadoFiltro,
                        items: ['Todos', 'Activo', 'Inactivo']
                            .map((e) => DropdownMenuItem(value: e, child: Text('Estado: $e')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _estadoFiltro = val!;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Info de resultados y paginación
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mostrando ${paginatedData.length} de ${_estudiantesFiltrados.length} estudiantes',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          Text('Página ${_currentPage + 1} de $_totalPages',
                              style: const TextStyle(fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage + 1 < _totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Tabla
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                            columns: const [
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Grado')),
                              DataColumn(label: Text('Estado')),
                              DataColumn(label: Text('Progreso')),
                              DataColumn(label: Text('Recomendación')),
                              DataColumn(label: Text('Acciones')),
                            ],
                            rows: paginatedData.map((e) {
                              final estado = e['estado'] ?? 'Activo';
                              final progreso = e['progreso'] ?? '—';
                              final rec = e['ultimaRecomendacion'] ?? '—';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        e['nombre'] ?? e['username'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        e['email'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(e['grado']?.toString() ?? '')),
                                  DataCell(
                                    GestureDetector(
                                      onTap: () => _toggleEstado(e),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: estado == 'Activo'
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            color: estado == 'Activo'
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        progreso,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        rec,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.bar_chart, size: 20),
                                          tooltip: 'Ver estadísticas',
                                          onPressed: () => _verEstadisticas(e),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          tooltip: 'Editar',
                                          onPressed: () => _editarEstudiante(e),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20,
                                              color: Colors.red),
                                          tooltip: 'Eliminar',
                                          onPressed: () =>
                                              _eliminarEstudiante(e['id'] as int),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

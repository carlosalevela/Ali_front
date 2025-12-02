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
  
  String _gradoFiltro = 'Todos';
  String _estadoFiltro = 'Todos';
  String _searchQuery = '';
  
  int _currentPage = 0;
  final int _pageSize = 25;

  final Map<int, String> _preferenciasEstudiantes = {};

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

  Future<void> _cargarProgresoTodos() async {
    setState(() => _cargandoProgreso = true);
    try {
      try {
        final listaPrefs = await _api.listarTop3Grado9Admin();
        _preferenciasEstudiantes.clear();
        for (var item in listaPrefs) {
          int? uid;
          if (item['usuario'] is int) {
            uid = item['usuario'];
          } else if (item['usuario'] is Map && item['usuario']['id'] != null) {
            uid = item['usuario']['id'];
          } else if (item['usuario_id'] != null) {
             uid = item['usuario_id'];
          }
          
          if (uid != null) {
            final selecciones = (item['selecciones'] as List?)?.join(", ") ?? "—";
            _preferenciasEstudiantes[uid] = selecciones;
          }
        }
        debugPrint("✅ Preferencias Top 3 cargadas para ${_preferenciasEstudiantes.length} estudiantes.");
      } catch (e) {
        debugPrint('⚠️ Error cargando preferencias Top 3 (no es fatal): $e');
      }

      int contador = 0;
      for (var estudiante in _todosEstudiantes) {
        final grado = estudiante['grado'];
        final userId = estudiante['id'];

        estudiante['eleccion'] = _preferenciasEstudiantes[userId] ?? '—';
        
        if (grado == 9) {
          try {
            final info = await _api.progresoUsuarioGrado9(userId, total: kTotalPreguntas9);
            estudiante['progreso'] = info['progreso'] ?? '—';
            estudiante['ultimaRecomendacion'] = _parseTecnico(info['ultimaRecomendacion']);
          } catch (e) {
            estudiante['progreso'] = 'Error';
          }
        } else if (grado == 10 || grado == 11) {
          try {
            final info = await _api.progresoUsuarioGrado10y11(userId, total: kTotalPreguntas10y11);
            estudiante['progreso'] = info['progreso'] ?? '—';
            estudiante['ultimaRecomendacion'] = _parseCarrera(info['ultimaRecomendacion']);
          } catch (e) {
            estudiante['progreso'] = 'Error';
          }
        }
        
        contador++;
        if (contador % 10 == 0 && mounted) setState(() {});
      }
      
      if (mounted) {
        setState(() => _cargandoProgreso = false);
        _aplicarFiltros();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Progreso cargado: $contador estudiantes procesados')));
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoProgreso = false);
    }
  }

  String _parseTecnico(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    const tag = 'Técnico sugerido por ALI:';
    final i = raw.indexOf(tag);
    if (i >= 0) {
        final rest = raw.substring(i + tag.length).trim();
        final first = rest.split(RegExp(r'[\n\r]')).first.trim();
        if (first.isNotEmpty) return first;
    }
    return raw.split(RegExp(r'[\n\r]')).first.trim();
  }

  String _parseCarrera(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    const tag = 'Carrera sugerida por ALI:';
    final i = raw.indexOf(tag);
    if (i >= 0) {
        final rest = raw.substring(i + tag.length).trim();
        final first = rest.split(RegExp(r'[\n\r]|Top-3:')).first.trim();
        if (first.isNotEmpty) return first;
    }
    return raw.split(RegExp(r'[\n\r]')).first.trim();
  }

  void _aplicarFiltros() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _currentPage = 0;

      _estudiantesFiltrados = _todosEstudiantes.where((e) {
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
        if (_gradoFiltro != 'Todos') {
          if (_gradoFiltro == '10/11') {
            if (e['grado'] != 10 && e['grado'] != 11) return false;
          } else {
            if (e['grado'].toString() != _gradoFiltro) return false;
          }
        }
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

    sh.appendRow(['ID', 'Nombre', 'Email', 'Grado', 'Estado', 'Elección Estudiante', 'Recomendación ALI', 'Progreso']);
    for (final e in _estudiantesFiltrados) {
      sh.appendRow([
        e['id'] ?? '',
        e['nombre'] ?? '',
        e['email'] ?? '',
        e['grado'] ?? '',
        e['estado'] ?? '',
        e['eleccion'] ?? '—',
        e['ultimaRecomendacion'] ?? '—',
        e['progreso'] ?? '—',
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
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: gradoCtrl, decoration: const InputDecoration(labelText: 'Grado'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final isMobile = screenWidth < 768;

    return Column(
      children: [
        // Header con acciones - Responsive
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_cargandoProgreso)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (!isMobile) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                  onPressed: _cargarEstudiantes,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Cargar progreso'),
                  onPressed: _cargandoProgreso ? null : _cargarProgresoTodos,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Exportar Excel'),
                  onPressed: _exportarExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1465BB),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Actualizar', style: TextStyle(fontSize: 13)),
                          onPressed: _cargarEstudiantes,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('Progreso', style: TextStyle(fontSize: 13)),
                          onPressed: _cargandoProgreso ? null : _cargarProgresoTodos,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Exportar Excel', style: TextStyle(fontSize: 13)),
                    onPressed: _exportarExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1465BB),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Filtros - Responsive
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            children: [
              // Búsqueda
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, email o usuario...',
                  hintStyle: TextStyle(fontSize: isMobile ? 14 : 15),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              // Filtros en fila o columna según el tamaño
              if (isDesktop || isTablet)
                Row(
                  children: [
                    Expanded(child: _buildGradoFilter()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEstadoFilter()),
                  ],
                )
              else ...[
                _buildGradoFilter(),
                const SizedBox(height: 12),
                _buildEstadoFilter(),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // Paginación - Responsive
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 12,
          ),
          child: isMobile
              ? Column(
                  children: [
                    Text(
                      'Mostrando ${paginatedData.length} de ${_estudiantesFiltrados.length} estudiantes',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Página ${_currentPage + 1} de $_totalPages',
                            style: const TextStyle(fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage + 1 < _totalPages ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
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

        // Contenido - Tabla o Cards según tamaño
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : isMobile
                  ? _buildMobileList(paginatedData)
                  : _buildDesktopTable(paginatedData, isDesktop),
        ),
      ],
    );
  }

  Widget _buildGradoFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gradoFiltro,
          isExpanded: true,
          items: ['Todos', '9', '10', '11', '10/11']
              .map((g) => DropdownMenuItem(value: g, child: Text('Grado: $g')))
              .toList(),
          onChanged: (val) => setState(() {
            _gradoFiltro = val!;
            _aplicarFiltros();
          }),
        ),
      ),
    );
  }

  Widget _buildEstadoFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _estadoFiltro,
          isExpanded: true,
          items: ['Todos', 'Activo', 'Inactivo']
              .map((e) => DropdownMenuItem(value: e, child: Text('Estado: $e')))
              .toList(),
          onChanged: (val) => setState(() {
            _estadoFiltro = val!;
            _aplicarFiltros();
          }),
        ),
      ),
    );
  }

  // Vista móvil: Cards
  Widget _buildMobileList(List<Map<String, dynamic>> data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final e = data[index];
        final estado = e['estado'] ?? 'Activo';
        final progreso = e['progreso'] ?? '—';
        final rec = e['ultimaRecomendacion'] ?? '—';
        final eleccion = e['eleccion'] ?? '—';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e['nombre'] ?? e['username'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleEstado(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: estado == 'Activo' ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.grade, 'Grado', e['grado']?.toString() ?? '—'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, 'Email', e['email'] ?? '—'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.check_circle, 'Elección', eleccion),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.school, 'Recomendación', rec),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.show_chart, 'Progreso', progreso),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _verEstadisticas(e),
                      icon: const Icon(Icons.bar_chart, size: 16),
                      label: const Text('Stats', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _editarEstudiante(e),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _eliminarEstudiante(e['id'] as int),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Eliminar',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Vista desktop/tablet: Tabla
  Widget _buildDesktopTable(List<Map<String, dynamic>> data, bool isDesktop) {
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              headingRowHeight: 56,
              dataRowHeight: 72,
              columns: const [
                DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Grado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Elección Est.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Recomendación ALI', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Progreso', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data.map((e) {
                final estado = e['estado'] ?? 'Activo';
                final progreso = e['progreso'] ?? '—';
                final rec = e['ultimaRecomendacion'] ?? '—';
                final eleccion = e['eleccion'] ?? '—';

                return DataRow(
                  cells: [
                    DataCell(SizedBox(
                      width: 150,
                      child: Text(
                        e['nombre'] ?? e['username'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                    DataCell(Text(e['grado']?.toString() ?? '')),
                    DataCell(GestureDetector(
                      onTap: () => _toggleEstado(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: estado == 'Activo' ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        eleccion,
                        style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                    DataCell(SizedBox(
                      width: 150,
                      child: Text(
                        rec,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
                    DataCell(SizedBox(width: 150, child: Text(progreso, overflow: TextOverflow.ellipsis))),
                    DataCell(Row(
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
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarEstudiante(e['id'] as int),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

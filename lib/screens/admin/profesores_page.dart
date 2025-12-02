// lib/screens/admin/profesores_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfesoresPage extends StatefulWidget {
  const ProfesoresPage({super.key});

  @override
  State<ProfesoresPage> createState() => _ProfesoresPageState();
}

class _ProfesoresPageState extends State<ProfesoresPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _profesores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    setState(() => _loading = true);
    try {
      final usuarios = await _api.fetchUsuarios();
      final profesores = usuarios
          .where((u) => u['rol'] == 'admin')
          .toList();

      setState(() {
        _profesores = profesores;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando profesores: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarProfesor() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Profesor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Aquí llamarías a tu endpoint de registro
              // Por ahora solo cierra el diálogo
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de registro pendiente en el backend'),
                ),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarProfesor(Map<String, dynamic> profesor) async {
    final nombreCtrl = TextEditingController(text: profesor['nombre']);
    final emailCtrl = TextEditingController(text: profesor['email']);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Profesor'),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await _api.editarUsuario(profesor['id'], {
                'nombre': nombreCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
              });
              if (ok && mounted) {
                Navigator.pop(ctx);
                _cargarProfesores();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarProfesor(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar profesor?'),
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
      if (ok) _cargarProfesores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestión de Profesores'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProfesores,
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarProfesor,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Profesor'),
        backgroundColor: const Color(0xFF1465BB),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profesores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay profesores registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _agregarProfesor,
                        child: const Text('Agregar el primero'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ${_profesores.length} profesores',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor:
                                    MaterialStateProperty.all(Colors.grey[100]),
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Nombre')),
                                  DataColumn(label: Text('Usuario')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: _profesores.map((p) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(p['id']?.toString() ?? '')),
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Text(
                                            p['nombre'] ?? 'Sin nombre',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(p['username'] ?? '')),
                                      DataCell(
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            p['email'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              tooltip: 'Editar',
                                              onPressed: () => _editarProfesor(p),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 20, color: Colors.red),
                                              tooltip: 'Eliminar',
                                              onPressed: () =>
                                                  _eliminarProfesor(p['id'] as int),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

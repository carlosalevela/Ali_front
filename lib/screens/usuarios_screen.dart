import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'estadisticas_screen.dart';

class UsuariosScreen extends StatefulWidget {
  final String titulo;
  final List<Map<String, dynamic>> usuarios;

  const UsuariosScreen({super.key, required this.titulo, required this.usuarios});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late List<Map<String, dynamic>> usuariosFiltrados;
  final TextEditingController _filtroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    usuariosFiltrados = List.from(widget.usuarios);
  }

  void _filtrarUsuarios(String query) {
    setState(() {
      usuariosFiltrados = widget.usuarios.where((usuario) {
        final nombre = usuario['nombre']?.toLowerCase() ?? '';
        final email = usuario['email']?.toLowerCase() ?? '';
        final username = usuario['username']?.toLowerCase() ?? '';
        return nombre.contains(query.toLowerCase()) ||
               email.contains(query.toLowerCase()) ||
               username.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _abrirEstadisticas(BuildContext context, Map<String, dynamic> usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstadisticasUsuarioScreen(
          usuarioId: usuario['id'],
          nombre: usuario['nombre'] ?? usuario['username'],
          grado: usuario['grado'],
        ),
      ),
    );
  }

  void _mostrarDialogoEdicion(BuildContext context, Map<String, dynamic> usuario, VoidCallback onActualizado) {
    final nombreCtrl = TextEditingController(text: usuario['nombre']);
    final emailCtrl = TextEditingController(text: usuario['email']);
    final gradoCtrl = TextEditingController(text: usuario['grado']?.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: gradoCtrl, decoration: const InputDecoration(labelText: 'Grado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final api = ApiService();
              final success = await api.editarUsuario(usuario['id'], {
                'nombre': nombreCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'grado': int.tryParse(gradoCtrl.text.trim()),
              });
              if (success) {
                Navigator.pop(context);
                onActualizado();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(BuildContext context, int id, VoidCallback onActualizado) async {
    final confirmado = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirmado == true) {
      final api = ApiService();
      final success = await api.deleteUsuario(id);
      if (success) onActualizado();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _filtroCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, email o usuario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrarUsuarios,
            ),
          ),
          Expanded(
            child: usuariosFiltrados.isEmpty
                ? const Center(child: Text('No hay usuarios disponibles.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: usuariosFiltrados.length,
                    itemBuilder: (_, index) {
                      final usuario = usuariosFiltrados[index];
                      return Card(
                        child: ListTile(
                          title: Text(usuario['nombre'] ?? usuario['username']),
                          subtitle: Text('Email: ${usuario['email']}  |  Grado: ${usuario['grado']}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bar_chart, color: Colors.blue),
                                tooltip: 'Ver estadísticas',
                                onPressed: () => _abrirEstadisticas(context, usuario),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                tooltip: 'Editar usuario',
                                onPressed: () => _mostrarDialogoEdicion(context, usuario, () => setState(() {})),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Eliminar usuario',
                                onPressed: () => _eliminarUsuario(context, usuario['id'], () {
                                  setState(() {
                                    usuariosFiltrados.removeAt(index);
                                    widget.usuarios.removeWhere((u) => u['id'] == usuario['id']);
                                  });
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

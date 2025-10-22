// admin_dashboard.dart
//
// ✅ ACTUALIZADO 24-Jul-2025 — Analíticas PRO (barras + exportación PNG/Excel)
//  • Analíticas: gráficas profesionales y selector de rango.
//  • Exportación selectiva a PNG (totales, faltantes por grado, finalizaciones por día).
//  • Fix: esperar frame + render temporal en overlay para PNG.
//  • BottomSheet scrollable sin overflow y con margen superior.
//  • Se mantiene la lógica existente fuera de Analíticas.
//
// ignore_for_file: depend_on_referenced_packages
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async'; // <<< LIVE PROGRESS (polling)
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Excel y FileSaver ───────────────────────────────────────────
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';

import '../services/api_service.dart';
import 'usuarios_screen.dart';
import 'estadisticas_screen.dart';

// ────────────────────────────────────────────────────────────────
// Totales por test (evita números mágicos en progreso)
const int kTotalPreguntas9 = 57;
const int kTotalPreguntas10y11 = 40;
// ────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ───────────────────────── data
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> administradores = [];
  final Map<String, List<Map<String, dynamic>>> estudiantesPorGrado = {
    '9': [],
    '10': [],
    '11': [],
  };

  // ───────────────────────── ui-state
  bool _isLoading = true;
  String _activeSection = 'dashboard';
  bool _studentsDropdownOpen = false;
  String _selectedDashboardGrade = '9';
  String _selectedStudentsGrade = '9';
  String _searchTerm = '';

  // ── Dashboard (ya existente) ──────────────────────────────────
  List<Map<String, dynamic>> _tec = []; // Técnicos (Grado 9)
  List<Map<String, dynamic>> _car = []; // Carreras (10/11)
  bool _loadingStats = false;

  // ── Analíticas (nuevo) ────────────────────────────────────────
  bool _analyticsLoading = false;
  bool _analyticsLoadedOnce = false;
  DateTimeRange? _analyticsRange;
  final Map<String, dynamic> _analytics = {
    'summary': {
      'tests9': 0,
      'tests1011': 0,
      'finish9': 0,
      'finish1011': 0,
      'avgSecs9': 0.0,
      'avgSecs1011': 0.0,
    },
    'byTecnico': <Map<String, dynamic>>[],
    'byCarrera': <Map<String, dynamic>>[],
    'finishesByDay': <Map<String, dynamic>>[],
  };

  // Keys para exportar PNG visibles
  final GlobalKey _keyTotales = GlobalKey();
  final GlobalKey _keyEstado = GlobalKey();
  final GlobalKey _keyByDay = GlobalKey();

  // ── LIVE PROGRESS (polling) ───────────────────────────────────
  Timer? _liveTimer;
  final Duration _liveEvery = const Duration(seconds: 10);
  bool _liveBusy = false;

  String _fmtProgreso(Map<String, dynamic> t, {required int total}) {
    final estado = t['estado']?.toString() ?? '';
    final resp   = (t['respondidas'] as num?)?.toInt() ?? 0;
    final ult    = (t['ultima_pregunta'] as num?)?.toInt() ?? 0;
    final pct    = (t['progreso_pct'] as num?)?.toDouble() ?? (total > 0 ? (resp / total) * 100 : 0);

    if (estado == 'FINALIZADO') return 'Finalizado';
    if (estado == 'EN_PROGRESO') return 'En progreso: $resp/$total (P$ult) ${pct.toStringAsFixed(0)}%';
    return '—';
  }

  void _startLiveWatch() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(_liveEvery, (_) => _tickLive());
  }

  void _stopLiveWatch() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  Future<void> _tickLive() async {
    if (!mounted || _liveBusy) return;
    _liveBusy = true;
    try {
      // 1) 9° — feed EN_PROGRESO
      final feed9 = await apiService.fetchTestsGrado9(
        estado: 'EN_PROGRESO',
        orden: 'actividad',
        limit: 200,
        offset: 0,
      );
      final Map<int, Map<String, dynamic>> m9 = {
        for (final t in feed9) (t['usuario'] as num).toInt(): t as Map<String, dynamic>
      };

      for (final al in estudiantesPorGrado['9']!) {
        final uid = (al['id'] as num).toInt();
        final testEnProg = m9[uid];
        if (testEnProg != null) {
          final nuevo = _fmtProgreso(testEnProg, total: kTotalPreguntas9); // ← 57 para 9°
          if (al['progreso'] != nuevo) {
            setState(() => al['progreso'] = nuevo);
          }
        } else {
          final old = (al['progreso'] ?? '').toString();
          if (old.startsWith('En progreso')) {
            final testsUsr = await apiService.fetchTestsGrado9PorUsuario(uid);
            if (testsUsr.isNotEmpty) {
              final last = Map<String, dynamic>.from(testsUsr.first);
              final est = (last['estado'] ?? '').toString().toUpperCase();
              if (est == 'FINALIZADO') {
                final det = await apiService.fetchResultadoTest9PorId((last['id'] as num).toInt());
                setState(() {
                  al['progreso'] = 'Finalizado';
                  al['ultimaRecomendacion'] = det['resultado'] ?? al['ultimaRecomendacion'] ?? '—';
                });
              } else {
                setState(() => al['progreso'] = '—');
              }
            }
          }
        }
      }

      // 2) 10/11 — feed EN_PROGRESO
      final feed1011 = await apiService.fetchTestsGrado10y11(
        estado: 'EN_PROGRESO',
        orden: 'actividad',
        limit: 200,
        offset: 0,
      );
      final Map<int, Map<String, dynamic>> m1011 = {
        for (final t in feed1011) (t['usuario'] as num).toInt(): t as Map<String, dynamic>
      };

      final list1011 = [...estudiantesPorGrado['10']!, ...estudiantesPorGrado['11']!];
      for (final al in list1011) {
        final uid = (al['id'] as num).toInt();
        final testEnProg = m1011[uid];
        if (testEnProg != null) {
          final nuevo = _fmtProgreso(testEnProg, total: kTotalPreguntas10y11); // ← 40 para 10/11
          if (al['progreso'] != nuevo) {
            setState(() => al['progreso'] = nuevo);
          }
        } else {
          final old = (al['progreso'] ?? '').toString();
          if (old.startsWith('En progreso')) {
            final testsUsr = await apiService.fetchTestsGrado10y11PorUsuario(uid);
            if (testsUsr.isNotEmpty) {
              final last = Map<String, dynamic>.from(testsUsr.first);
              final est = (last['estado'] ?? '').toString().toUpperCase();
              if (est == 'FINALIZADO') {
                final det = await apiService.fetchResultadoTest10y11PorId((last['id'] as num).toInt());
                setState(() {
                  al['progreso'] = 'Finalizado';
                  al['ultimaRecomendacion'] = det['resultado'] ?? al['ultimaRecomendacion'] ?? '—';
                });
              } else {
                setState(() => al['progreso'] = '—');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('tick live error: $e');
    } finally {
      _liveBusy = false;
    }
  }

  // ───────────────────────── init
  @override
  void initState() {
    super.initState();
    _verificarPermiso();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _stopLiveWatch(); // <<< LIVE PROGRESS (polling)
    super.dispose();
  }

  // ═════════════════════════════════ permisos
  Future<void> _verificarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('rol') != 'admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    await _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await apiService.fetchUsuarios();

      Future<Map<String, dynamic>> _enriquecer(Map<String, dynamic> u) async {
        final usr = Map<String, dynamic>.from(u);
        usr['estado'] = usr['estado'] ?? 'Activo';

        String _fmt(Map<String, dynamic> t, {required int total}) {
          final estado = t['estado']?.toString() ?? '';
          final resp = (t['respondidas'] as num?)?.toInt() ?? 0;
          final ult = (t['ultima_pregunta'] as num?)?.toInt() ?? 0;
          final pct = (t['progreso_pct'] as num?)?.toDouble() ?? (total > 0 ? (resp / total) * 100 : 0);
          if (estado == 'FINALIZADO') return 'Finalizado';
          if (estado == 'EN_PROGRESO') return 'En progreso: $resp/$total (P$ult) ${pct.toStringAsFixed(0)}%';
          return '—';
        }

        if (usr['grado'] == 9) {
          final info = await apiService.progresoUsuarioGrado9(usr['id'], total: kTotalPreguntas9); // ← 57
          usr['progreso'] = info['progreso'] ?? '—';
          usr['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';

          if (usr['ultimaRecomendacion'] == '—') {
            final tests = await apiService.fetchTestsGrado9PorUsuario(usr['id']);
            if (tests.isNotEmpty) {
              final det = await apiService.fetchResultadoTest9PorId(tests.first['id']);
              usr['ultimaRecomendacion'] = det['resultado'] ?? '—';
              usr['progreso'] = usr['progreso'] == '—' ? _fmt(tests.first, total: kTotalPreguntas9) : usr['progreso'];
            }
          }
          return usr;
        }

        if (usr['grado'] == 10 || usr['grado'] == 11) {
          final info = await apiService.progresoUsuarioGrado10y11(usr['id'], total: kTotalPreguntas10y11); // ← 40
          usr['progreso'] = info['progreso'] ?? '—';
          usr['ultimaRecomendacion'] = info['ultimaRecomendacion'] ?? '—';

          if (usr['ultimaRecomendacion'] == '—') {
            final tests = await apiService.fetchTestsGrado10y11PorUsuario(usr['id']);
            if (tests.isNotEmpty) {
              final det = await apiService.fetchResultadoTest10y11PorId(tests.first['id']);
              usr['ultimaRecomendacion'] = det['resultado'] ?? '—';
              usr['progreso'] = usr['progreso'] == '—' ? _fmt(tests.first, total: kTotalPreguntas10y11) : usr['progreso'];
            }
          }
          return usr;
        }

        usr['progreso'] = '—';
        usr['ultimaRecomendacion'] = '—';
        return usr;
      }

      administradores = usuarios.where((u) => u['rol'] == 'admin').toList();

      final est9 = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 9).toList();
      final est10 = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 10).toList();
      final est11 = usuarios.where((u) => u['rol'] == 'estudiante' && u['grado'] == 11).toList();

      estudiantesPorGrado['9'] = await Future.wait(est9.map(_enriquecer));
      estudiantesPorGrado['10'] = await Future.wait(est10.map(_enriquecer));
      estudiantesPorGrado['11'] = await Future.wait(est11.map(_enriquecer));
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _cargarEstadisticas(); // dashboard 9/10/11 técnicos/carreras
      _startLiveWatch(); // <<< LIVE PROGRESS (polling) — arranca después de cargar
    }
  }

  // ═════════════════════════════════ helpers
  List<Map<String, dynamic>> _estudiantesGrado(String k) {
    switch (k) {
      case '9':
        return estudiantesPorGrado['9']!;
      case '10':
        return estudiantesPorGrado['10']!;
      case '11':
        return estudiantesPorGrado['11']!;
      case '10/11':
        return estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
      default:
        return [];
    }
  }

  void _abrirEstadisticas(Map<String, dynamic> al) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstadisticasUsuarioScreen(
          usuarioId: al['id'],
          nombre: al['nombre'] ?? al['username'],
          grado: al['grado'],
        ),
      ),
    );
  }

  Future<void> _editarUsuario(Map<String, dynamic> u) async {
    final n = TextEditingController(text: u['nombre']);
    final e = TextEditingController(text: u['email']);
    final g = TextEditingController(text: u['grado']?.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: e, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: g, decoration: const InputDecoration(labelText: 'Grado')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await apiService.editarUsuario(u['id'], {
                'nombre': n.text.trim(),
                'email': e.text.trim(),
                'grado': int.tryParse(g.text.trim()),
              });
              if (ok && mounted) {
                Navigator.pop(context);
                await _cargarUsuarios();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(int id) async {
    final conf = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (conf == true) {
      final ok = await apiService.deleteUsuario(id);
      if (ok) await _cargarUsuarios();
    }
  }

  // ═════════════════════════════════ exportar Excel (Estudiantes)
  Future<void> _exportarExcel(List<Map<String, dynamic>> alumnos) async {
    final ex.Excel wb = ex.Excel.createExcel();
    final ex.Sheet sh = wb['Estudiantes'];

    sh.appendRow(['ID', 'Nombre', 'Email', 'Grado', 'Estado', 'Progreso', 'Recomendación']);
    for (final a in alumnos) {
      sh.appendRow([
        a['id'] ?? '',
        a['nombre'] ?? '',
        a['email'] ?? '',
        a['grado'] ?? '',
        a['estado'] ?? '',
        a['progreso'] ?? '',
        a['ultimaRecomendacion'] ?? '',
      ]);
    }

    final Uint8List bytes = Uint8List.fromList(wb.encode()!);
    await FileSaver.instance.saveFile(
      'estudiantes_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      bytes,
      'xlsx',
      mimeType: MimeType.MICROSOFTEXCEL,
    );
  }

  Future<void> _toggleEstado(Map<String, dynamic> al) async {
    final nuevo = al['estado'] == 'Activo' ? 'Inactivo' : 'Activo';
    final ok = await apiService.editarUsuario(al['id'], {'estado': nuevo});
    if (ok && mounted) setState(() => al['estado'] = nuevo);
  }

  // ═════════════════════════════════ sidebar/header
  void _onSidebarTap(String key, {bool drop = false}) {
    setState(() {
      if (key == 'students' && drop) {
        _studentsDropdownOpen = !_studentsDropdownOpen;
        _activeSection = 'students';
      } else {
        _activeSection = key;
        _studentsDropdownOpen = false;
      }
    });
  }

  Widget _buildSidebar() {
    const sidebarBg = Color(0xFF1465BB);
    const activeBg = Color(0xFF0D4A8A);
    final inactive = Colors.grey[300];

    Widget item(IconData ic, String label, String key, {bool drop = false}) {
      final act = _activeSection == key;
      return Column(
        children: [
          ListTile(
            leading: Icon(ic, size: 20, color: act ? Colors.white : inactive),
            title: Text(label, style: TextStyle(color: act ? Colors.white : inactive)),
            tileColor: act ? activeBg : sidebarBg,
            onTap: () => _onSidebarTap(key, drop: drop),
            trailing: drop
                ? Icon(_studentsDropdownOpen ? Icons.expand_less : Icons.expand_more, color: inactive)
                : null,
          ),
          if (key == 'students' && _studentsDropdownOpen)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chevron_right, color: Colors.white),
                    title: const Text('Grado 9°', style: TextStyle(color: Colors.white)),
                    onTap: () => setState(() {
                      _selectedStudentsGrade = '9';
                      _activeSection = 'students';
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chevron_right, color: Colors.white),
                    title: const Text('Grado 10/11', style: TextStyle(color: Colors.white)),
                    onTap: () => setState(() {
                      _selectedStudentsGrade = '10';
                      _activeSection = 'students';
                    }),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Container(
      width: 250,
      color: sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('ALI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                item(Icons.bar_chart, 'Panel Principal', 'dashboard'),
                item(Icons.person, 'Profesores', 'teachers'),
                item(Icons.school, 'Estudiantes', 'students', drop: true),
                item(Icons.analytics, 'Analíticas', 'analytics'),
              ],
            ),
          ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = {
      'dashboard': 'Panel Principal',
      'students': 'Estudiantes',
      'teachers': 'Profesores',
      'analytics': 'Analíticas',
    }[_activeSection]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          if (_activeSection != 'dashboard')
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: 'Buscar...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          const SizedBox(width: 24),
          const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }

  // ═════════════════════════════════ métricas para dashboard (igual)
  List<Map<String, String>> _metricas(String gradeKey) {
    final est = _estudiantesGrado(gradeKey);
    final tot = est.length;
    final fin = est.where((e) => e['progreso'] == 'Finalizado').length;
    final pen = tot - fin;
    final pct = tot > 0 ? ((fin / tot) * 100).round() : 0;
    return [
      {'title': 'Total Estudiantes', 'value': '$tot', 'subtitle': 'en este grado', 'trend': '+5%'},
      {'title': 'Tests Completados', 'value': '$fin', 'subtitle': 'estudiantes', 'trend': '$pct%'},
      {'title': 'Tests Pendientes', 'value': '$pen', 'subtitle': 'estudiantes', 'trend': '-2%'},
      {'title': 'Tasa de Finalización', 'value': '$pct%', 'subtitle': 'del total', 'trend': '+8%'},
    ];
  }

  // ─────────────── Dashboard: conteos reales por técnico/carrera
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

  Future<void> _cargarEstadisticas() async {
    setState(() => _loadingStats = true);
    try {
      final tests9 = await apiService.fetchTestsGrado9(
        estado: 'FINALIZADO',
        orden: null,
        limit: 500,
        offset: 0,
      );
      final Map<String, int> cntTec = {
        'Industrial': 0,
        'Comercio': 0,
        'Promoción Social': 0,
        'Agropecuaria': 0,
      };
      for (final t in tests9) {
        final tec = _parseTecnico(t['resultado']?.toString());
        if (cntTec.containsKey(tec)) cntTec[tec] = (cntTec[tec] ?? 0) + 1;
      }
      final tecList = cntTec.entries.map((e) => {'name': e.key, 'count': e.value}).toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      final tests1011 = await apiService.fetchTestsGrado10y11(
        estado: 'FINALIZADO',
        orden: null,
        limit: 1000,
        offset: 0,
      );
      final Map<String, int> cntCar = {};
      for (final t in tests1011) {
        final car = (t['resultado']?.toString().trim().isEmpty ?? true) ? 'Desconocido' : t['resultado'].toString().trim();
        cntCar[car] = (cntCar[car] ?? 0) + 1;
      }
      final carList = cntCar.entries.map((e) => {'name': e.key, 'count': e.value}).toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      if (mounted) setState(() {
        _tec = tecList;
        _car = carList;
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ─────────────── Analíticas: fechas desde serializers
  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (_) {}
    return null;
  }

  DateTime? _fin(Map<String, dynamic> t) => _parseDate(t['fecha_realizacion']);
  DateTime? _ini(Map<String, dynamic> t) =>
      _parseDate(t['fecha_inicio']) ?? _parseDate(t['fecha_ultima_actividad']);

  Future<void> _loadAnalytics({DateTimeRange? range}) async {
    setState(() {
      _analyticsLoading = true;
      if (range != null) _analyticsRange = range;
      _analyticsRange ??= DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 90)),
        end: DateTime.now(),
      );
    });

    try {
      final tests9All = await apiService.fetchTestsGrado9(
        estado: null,
        orden: null,
        limit: 2000,
        offset: 0,
      );
      final tests1011All = await apiService.fetchTestsGrado10y11(
        estado: null,
        orden: null,
        limit: 2000,
        offset: 0,
      );

      bool inRange(Map<String, dynamic> t) {
        final pivot = _fin(t) ?? _ini(t);
        if (pivot == null) return false;
        return !pivot.isBefore(_analyticsRange!.start) && !pivot.isAfter(_analyticsRange!.end);
      }

      final tests9 = tests9All.where(inRange).toList();
      final tests1011 = tests1011All.where(inRange).toList();

      bool isFinished(Map<String, dynamic> t) {
        final s = (t['estado'] ?? '').toString().toUpperCase();
        return s == 'FINALIZADO' || s == 'FINALIZADOS' || s == 'COMPLETADO';
      }

      final fin9 = tests9.where(isFinished).toList();
      final fin1011 = tests1011.where(isFinished).toList();

      // 9° por técnico
      final tecCounts = <String, int>{};
      for (final t in fin9) {
        final tec = _parseTecnico((t['resultado'] ?? '').toString());
        tecCounts[tec] = (tecCounts[tec] ?? 0) + 1;
      }
      final byTecnicoList = tecCounts.entries.map((e) => {'name': e.key, 'count': e.value}).toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // 10/11 por carrera
      final carCounts = <String, int>{};
      for (final t in fin1011) {
        final raw = (t['resultado'] ?? '').toString().trim();
        final car = raw.isEmpty ? 'Desconocido' : raw;
        carCounts[car] = (carCounts[car] ?? 0) + 1;
      }
      final byCarreraList = carCounts.entries.map((e) => {'name': e.key, 'count': e.value}).toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Finalizaciones por día
      String pickDay(Map<String, dynamic> t) {
        final d = _fin(t) ?? _ini(t)!;
        return DateFormat('yyyy-MM-dd').format(d);
      }

      Map<String, int> _groupByDay(Iterable<Map<String, dynamic>> items) {
        final m = <String, int>{};
        for (final t in items) {
          final k = pickDay(t);
          m[k] = (m[k] ?? 0) + 1;
        }
        return m;
      }

      final byDay9Map = _groupByDay(fin9);
      final byDay1011Map = _groupByDay(fin1011);
      final mergedDaysMap = <String, int>{}..addAll(byDay9Map);
      byDay1011Map.forEach((k, v) {
        mergedDaysMap[k] = (mergedDaysMap[k] ?? 0) + v;
      });

      final finishesByDayList = mergedDaysMap.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      // Duración promedio
      double avgSecs(Iterable<Map<String, dynamic>> tests) {
        int acc = 0, n = 0;
        for (final t in tests) {
          final ini = _ini(t);
          final fin = _fin(t);
          if (ini != null && fin != null) {
            acc += fin.difference(ini).inSeconds;
            n++;
          }
        }
        return n == 0 ? 0 : acc / n;
      }

      final summary = {
        'tests9': tests9.length,
        'tests1011': tests1011.length,
        'finish9': fin9.length,
        'finish1011': fin1011.length,
        'avgSecs9': avgSecs(fin9),
        'avgSecs1011': avgSecs(fin1011),
      };

      if (mounted) {
        setState(() {
          _analytics['summary'] = summary;
          _analytics['byTecnico'] = byTecnicoList;
          _analytics['byCarrera'] = byCarreraList;
          _analytics['finishesByDay'] = finishesByDayList;
          _analyticsLoading = false;
          _analyticsLoadedOnce = true;
        });
      }
    } catch (e) {
      debugPrint('Error _loadAnalytics: $e');
      if (mounted) setState(() => _analyticsLoading = false);
    }
  }

  // ═════════════════════════════════ exportar Excel (Analíticas)
  Future<void> _exportarExcelAnaliticas() async {
    final ex.Excel wb = ex.Excel.createExcel();

    final ex.Sheet h1 = wb['Resumen'];
    final Map s = _analytics['summary'] as Map;
    h1.appendRow(['Métrica', 'Valor']);
    h1.appendRow(['Tests (9°) en rango', s['tests9']]);
    h1.appendRow(['Tests (10/11) en rango', s['tests1011']]);
    h1.appendRow(['Finalizados (9°)', s['finish9']]);
    h1.appendRow(['Finalizados (10/11)', s['finish1011']]);
    final avg9 = ((s['avgSecs9'] as num?) ?? 0).toDouble();
    final avg1011 = ((s['avgSecs1011'] as num?) ?? 0).toDouble();
    h1.appendRow(['Duración promedio 9° (min)', (avg9 / 60).toStringAsFixed(1)]);
    h1.appendRow(['Duración promedio 10/11 (min)', (avg1011 / 60).toStringAsFixed(1)]);

    final ex.Sheet h2 = wb['Grado 9 - Técnicos'];
    h2.appendRow(['Técnico', 'Conteo']);
    for (final r in (_analytics['byTecnico'] as List)) {
      h2.appendRow([r['name'], r['count']]);
    }

    final ex.Sheet h3 = wb['Bachillerato - Carreras'];
    h3.appendRow(['Carrera', 'Conteo']);
    for (final r in (_analytics['byCarrera'] as List)) {
      h3.appendRow([r['name'], r['count']]);
    }

    final ex.Sheet h4 = wb['Finalizaciones por día'];
    h4.appendRow(['Fecha', 'Total finalizados']);
    for (final r in (_analytics['finishesByDay'] as List)) {
      h4.appendRow([r['date'], r['count']]);
    }

    final bytes = Uint8List.fromList(wb.encode()!);
    await FileSaver.instance.saveFile(
      'analiticas_ali_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      bytes,
      'xlsx',
      mimeType: MimeType.MICROSOFTEXCEL,
    );
  }

  // ═════════════════════════════════ exportar PNG (fix: espera frame)
  Future<void> _saveChartPng(GlobalKey key, String filename) async {
    final ctx = key.currentContext;
    if (ctx == null) return;

    await Future.delayed(const Duration(milliseconds: 16));
    await WidgetsBinding.instance.endOfFrame;

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    await FileSaver.instance.saveFile(filename, bytes, 'png', mimeType: MimeType.PNG);
  }

  // Render temporal en overlay para PNG individuales
  Future<void> _renderAndSaveTemporaryChart({
    required Widget chart,
    required String filename,
    Size size = const Size(1200, 520),
  }) async {
    final key = GlobalKey();
    final overlay = OverlayEntry(
      builder: (ctx) => IgnorePointer(
        ignoring: true,
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: Opacity(
              opacity: 0.01,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(width: size.width, height: size.height, child: chart),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(overlay);
    try {
      await Future.delayed(const Duration(milliseconds: 20));
      await WidgetsBinding.instance.endOfFrame;

      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await FileSaver.instance.saveFile(filename, bytes, 'png', mimeType: MimeType.PNG);
    } finally {
      overlay.remove();
    }
  }

  Widget _chartTotalSolo(String label, int total) {
    return ChartCard(
      title: 'Total $label',
      child: BarChart(
        bars: [BarGroup(label, [BarSerie('Total', [total])])],
        stacked: false,
        showLegend: false,
      ),
    );
  }

  Widget _chartFaltantesSolo(String label, int faltantes) {
    return ChartCard(
      title: 'Solo FALTANTES $label',
      child: BarChart(
        bars: [BarGroup(label, [BarSerie('Faltantes', [faltantes])])],
        stacked: false,
        showLegend: false,
      ),
    );
  }

  Future<void> _pickerExportarPng({
    required int tot9,
    required int tot10,
    required int tot11,
    required int fin9,
    required int fin10,
    required int fin11,
    required int pen9,
    required int pen10,
    required int pen11,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset, top: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text('Descargar gráficas (PNG)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Totales (9° + 10° + 11°)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _saveChartPng(_keyTotales, 'totales_9_10_11.png');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Totales — solo 9°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartTotalSolo('9°', tot9),
                          filename: 'totales_9.png',
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Totales — solo 10°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartTotalSolo('10°', tot10),
                          filename: 'totales_10.png',
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: const Text('Totales — solo 11°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartTotalSolo('11°', tot11),
                          filename: 'totales_11.png',
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.stacked_bar_chart),
                      title: const Text('Estado (terminados/pendientes) — 9° + 10° + 11°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _saveChartPng(_keyEstado, 'estado_9_10_11.png');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Solo FALTANTES — 9°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartFaltantesSolo('9°', pen9),
                          filename: 'faltantes_9.png',
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Solo FALTANTES — 10°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartFaltantesSolo('10°', pen10),
                          filename: 'faltantes_10.png',
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Solo FALTANTES — 11°'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renderAndSaveTemporaryChart(
                          chart: _chartFaltantesSolo('11°', pen11),
                          filename: 'faltantes_11.png',
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Finalizaciones por día (rango actual)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _saveChartPng(_keyByDay, 'finalizaciones_por_dia.png');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════ dashboard (igual)
  Widget _renderDashboard() {
    final grade = _selectedDashboardGrade;
    final metrics = _metricas(grade);
    final choices = grade == '9' ? _tec : _car;
    final maxC = choices.isNotEmpty ? choices.map<int>((e) => e['count'] as int).reduce((a, b) => a > b ? a : b) : 1;

    final now = DateTime.now();
    final ini = DateTime(now.year, now.month, 1);
    final fin = DateTime(now.year, now.month + 1, 0);
    final rango = '${DateFormat('d MMM', 'es').format(ini)} - ${DateFormat('d MMM yyyy', 'es').format(fin)}';
    final mesAn = DateFormat('MMMM yyyy', 'es').format(now);

    final progRaw = metrics[1]['trend'] ?? '0%';
    final progVal = (double.tryParse(progRaw.replaceAll(RegExp(r'\D'), '')) ?? 0) / 100;

    final listaEst = _estudiantesGrado(grade);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: ['9', '10/11'].map((g) {
                  final sel = _selectedDashboardGrade == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sel ? const Color(0xFF0D4A8A) : Colors.transparent,
                        foregroundColor: sel ? Colors.white : Colors.grey[700],
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        elevation: 0,
                      ),
                      onPressed: () => setState(() => _selectedDashboardGrade = g),
                      child: Text(g == '9' ? 'Grado 9°' : 'Bachillerato'),
                    ),
                  );
                }).toList(),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(rango, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // métricas
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3 / 2,
            physics: const NeverScrollableScrollPhysics(),
            children: metrics.map((m) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(m['value']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(m['subtitle']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      Text(m['trend']!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // gráfico + lateral
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(grade == '9' ? 'Técnicos Elegidos' : 'Carreras Elegidas',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _cargarEstadisticas),
                          ],
                        ),
                        if (_loadingStats) const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                        for (final ch in choices)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 140, child: Text(ch['name'], style: const TextStyle(fontSize: 14))),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (maxC == 0 ? 0 : (ch['count'] as int) / maxC),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('${ch['count']}'),
                              ],
                            ),
                          ),
                        if (choices.isEmpty && !_loadingStats)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Sin datos aún', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(mesAn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (idx) {
                                const off = [-2, -1, 0, 1, 2];
                                final now = DateTime.now();
                                final d = off[idx] + now.day;
                                final end = DateTime(now.year, now.month + 1, 0).day;
                                final day = d < 1 ? 1 : (d > end ? end : d);
                                final isToday = day == now.day;
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isToday ? const Color(0xFF0D4A8A) : const Color(0xFFF9FAFB),
                                    foregroundColor: isToday ? Colors.white : Colors.grey[700],
                                    elevation: 0,
                                    minimumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {},
                                  child: Text('$day'),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Progreso de Tests', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                Text('+8.5% del mes pasado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: progVal, minHeight: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // tabla estudiantes (igual)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estudiantes - ${grade == '9' ? 'Grado 9°' : '10/11'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _cargarUsuarios()),
                          IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: 'Excel',
                            onPressed: () => _exportarExcel(listaEst),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UsuariosScreen(titulo: 'Estudiantes', usuarios: listaEst),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Recomendación')),
                        DataColumn(label: Text('Progreso')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: listaEst.map((e) {
                        final prog = e['progreso'] ?? 'N/A';
                        final estado = e['estado'] ?? 'Activo';
                        final rec = e['ultimaRecomendacion'] ?? '—';
                        final chipEstado = GestureDetector(
                          onSecondaryTap: () => _toggleEstado(e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(estado,
                                style: TextStyle(color: estado == 'Activo' ? Colors.green : Colors.red)),
                          ),
                        );
                        return DataRow(
                          onSelectChanged: (_) => _abrirEstadisticas(e),
                          cells: [
                            DataCell(Text(e['nombre'] ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis)),
                            DataCell(chipEstado),
                            DataCell(Text(rec)),
                            DataCell(Text(prog)),
                            DataCell(Row(
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editarUsuario(e)),
                                IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => _eliminarUsuario(e['id'])),
                              ],
                            )),
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

  // ═════════════════════════════════ estudiantes (igual)
  Widget _renderStudents() {
    final kGr = _selectedStudentsGrade == '9' ? '9' : '10';
    final al = kGr == '9'
        ? estudiantesPorGrado['9']!
        : estudiantesPorGrado['10']! + estudiantesPorGrado['11']!;
    final filt = al
        .where((e) => ((e['nombre'] ?? '').toString().toLowerCase())
            .contains(_searchTerm.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estudiantes Inscritos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Excel'),
                    onPressed: () => _exportarExcel(filt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1465BB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (final g in ['9', '10/11'])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedStudentsGrade ==
                                  (g == '9' ? '9' : '10')
                              ? const Color(0xFF0D4A8A)
                              : Colors.transparent,
                          foregroundColor: _selectedStudentsGrade ==
                                  (g == '9' ? '9' : '10')
                              ? Colors.white
                              : Colors.grey[700],
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        onPressed: () =>
                            setState(() => _selectedStudentsGrade = g == '9' ? '9' : '10'),
                        child: Text(g == '9' ? 'Grado 9°' : 'Grado 10/11'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Recomendación')),
                  DataColumn(label: Text('Progreso')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filt.map((al) {
                  final prog = al['progreso'] ?? 'N/A';
                  final estado = al['estado'] ?? 'Activo';
                  final rec = al['ultimaRecomendacion'] ?? '—';
                  final chipEstado = GestureDetector(
                    onSecondaryTap: () => _toggleEstado(al),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: estado == 'Activo' ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(estado,
                          style: TextStyle(
                              color: estado == 'Activo' ? Colors.green : Colors.red)),
                    ),
                  );
                  return DataRow(
                    onSelectChanged: (_) => _abrirEstadisticas(al),
                    cells: [
                      DataCell(Text(al['nombre'] ?? '—')),
                      DataCell(Text(al['email'] ?? '—')),
                      DataCell(chipEstado),
                      DataCell(Text(rec)),
                      DataCell(Text(prog)),
                      DataCell(Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editarUsuario(al)),
                          IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => _eliminarUsuario(al['id'])),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ profesores (igual)
  Widget _renderTeachers() {
    final filt = administradores
        .where((t) => ((t['nombre'] ?? '').toString().toLowerCase())
            .contains(_searchTerm.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profesores Registrados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Agregar Profesor'),
                  onPressed: () {}),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filt.map((p) {
                  return DataRow(cells: [
                    DataCell(Text(p['nombre']?.toString().isNotEmpty == true
                        ? p['nombre']
                        : p['username'] ?? '—')),
                    DataCell(Text(p['email'] ?? '—')),
                    DataCell(Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _editarUsuario(p)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _eliminarUsuario(p['id'])),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ ANALÍTICAS — SOLO GRÁFICAS
  Widget _renderAnalytics() {
    if (!_analyticsLoadedOnce && !_analyticsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalytics());
    }

    final byDay = (_analytics['finishesByDay'] as List).cast<Map<String, dynamic>>();
    final tot9 = estudiantesPorGrado['9']!.length;
    final tot10 = estudiantesPorGrado['10']!.length;
    final tot11 = estudiantesPorGrado['11']!.length;

    int _fin(List<Map<String, dynamic>> xs) => xs.where((e) => e['progreso'] == 'Finalizado').length;

    final fin9 = _fin(estudiantesPorGrado['9']!);
    final fin10 = _fin(estudiantesPorGrado['10']!);
    final fin11 = _fin(estudiantesPorGrado['11']!);

    final pen9 = tot9 - fin9;
    final pen10 = tot10 - fin10;
    final pen11 = tot11 - fin11;

    String rangoLabel() {
      final r = _analyticsRange;
      if (r == null) return 'Últimos 90 días';
      final f = DateFormat('d MMM yyyy', 'es');
      return '${f.format(r.start)} – ${f.format(r.end)}';
    }

    Future<void> pickRange() async {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3),
        lastDate: DateTime(now.year + 1),
        initialDateRange:
            _analyticsRange ?? DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now),
        helpText: 'Rango para Analíticas',
        builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
      );
      if (picked != null) await _loadAnalytics(range: picked);
    }

    final seriesByDay =
        byDay.map((e) => BarPoint(e['date'] as String, (e['count'] as num).toInt())).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(rangoLabel()),
                onPressed: pickRange,
              ),
              const SizedBox(width: 8),
              IconButton(
                  tooltip: '7 días',
                  icon: const Icon(Icons.filter_7),
                  onPressed: () {
                    final now = DateTime.now();
                    _loadAnalytics(
                        range:
                            DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now));
                  }),
              IconButton(
                  tooltip: '30 días',
                  icon: const Icon(Icons.calendar_view_month),
                  onPressed: () {
                    final now = DateTime.now();
                    _loadAnalytics(
                        range:
                            DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now));
                  }),
              IconButton(tooltip: 'Refrescar', icon: const Icon(Icons.refresh), onPressed: _loadAnalytics),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Excel (datos)'),
                onPressed: _analyticsLoading ? null : _exportarExcelAnaliticas,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1465BB), foregroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Gráficas (PNG)'),
                onPressed: _analyticsLoading
                    ? null
                    : () => _pickerExportarPng(
                          tot9: tot9,
                          tot10: tot10,
                          tot11: tot11,
                          fin9: fin9,
                          fin10: fin10,
                          fin11: fin11,
                          pen9: pen9,
                          pen10: pen10,
                          pen11: pen11,
                        ),
              ),
            ],
          ),
          if (_analyticsLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 16),

          // 1) Totales por grado
          RepaintBoundary(
            key: _keyTotales,
            child: ChartCard(
              title: 'Total de estudiantes por grado',
              child: BarChart(
                bars: [
                  BarGroup('9°', [BarSerie('Total', [tot9])]),
                  BarGroup('10°', [BarSerie('Total', [tot10])]),
                  BarGroup('11°', [BarSerie('Total', [tot11])]),
                ],
                stacked: false,
                showLegend: false,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2) Estado por grado
          RepaintBoundary(
            key: _keyEstado,
            child: ChartCard(
              title: 'Terminados vs Pendientes por grado',
              child: BarChart(
                bars: [
                  BarGroup('9°', [BarSerie('Terminados', [fin9]), BarSerie('Pendientes', [pen9])]),
                  BarGroup('10°', [BarSerie('Terminados', [fin10]), BarSerie('Pendientes', [pen10])]),
                  BarGroup('11°', [BarSerie('Terminados', [fin11]), BarSerie('Pendientes', [pen11])]),
                ],
                stacked: false,
                showLegend: true,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3) Finalizaciones por día
          RepaintBoundary(
            key: _keyByDay,
            child: ChartCard(
              title: 'Finalizaciones por día (rango seleccionado)',
              child: BarChartByDay(series: seriesByDay),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════ build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(),
              onKey: (ev) {
                if (ev is RawKeyDownEvent) {
                  if (ev.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _scrollController.animateTo(_scrollController.offset + 100,
                        duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                  } else if (ev.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _scrollController.animateTo(_scrollController.offset - 100,
                        duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                  }
                }
              },
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: () {
                            switch (_activeSection) {
                              case 'students':
                                return _renderStudents();
                              case 'teachers':
                                return _renderTeachers();
                              case 'analytics':
                                return _renderAnalytics();
                              case 'dashboard':
                              default:
                                return _renderDashboard();
                            }
                          }(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// W I D G E T S   D E   G R Á F I C A S  (sin paquetes externos)
// ═══════════════════════════════════════════════════════════════

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const ChartCard({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('')]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.insights, size: 18, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 320, child: child),
          ],
        ),
      ),
    );
  }
}

class BarSerie {
  final String name;
  final List<int> values;
  BarSerie(this.name, this.values);
}

class BarGroup {
  final String groupLabel;
  final List<BarSerie> series;
  BarGroup(this.groupLabel, this.series);
}

class BarChart extends StatelessWidget {
  final List<BarGroup> bars;
  final bool stacked;
  final bool showLegend;
  const BarChart({
    super.key,
    required this.bars,
    required this.stacked,
    required this.showLegend,
  });

  @override
  Widget build(BuildContext context) {
    final palette = [
      const Color(0xFF4CAF50), // Terminados
      const Color(0xFF90CAF9), // Pendientes / Total
      const Color(0xFF9575CD),
      const Color(0xFFFFB74D),
    ];

    int maxVal = 1;
    for (final g in bars) {
      if (stacked) {
        final sum =
            g.series.fold<int>(0, (acc, s) => acc + (s.values.isNotEmpty ? s.values.first : 0));
        if (sum > maxVal) maxVal = sum;
      } else {
        for (final s in g.series) {
          final v = s.values.isNotEmpty ? s.values.first : 0;
          if (v > maxVal) maxVal = v;
        }
      }
    }

    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final chart = _BarPainterData(
          bars: bars,
          stacked: stacked,
          maxValue: maxVal,
          palette: palette,
        );
        return Column(
          children: [
            Expanded(
              child: CustomPaint(size: Size(w, h - (showLegend ? 32 : 0)), painter: _BarPainter(chart)),
            ),
            if (showLegend) const SizedBox(height: 8),
            if (showLegend)
              Wrap(
                spacing: 16,
                children: List.generate(bars.first.series.length, (i) {
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: palette[i % palette.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(bars.first.series[i].name,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]);
                }),
              ),
          ],
        );
      },
    );
  }
}

class _BarPainterData {
  final List<BarGroup> bars;
  final bool stacked;
  final int maxValue;
  final List<Color> palette;
  _BarPainterData({
    required this.bars,
    required this.stacked,
    required this.maxValue,
    required this.palette,
  });
}

class _BarPainter extends CustomPainter {
  final _BarPainterData d;
  _BarPainter(this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 32.0;
    final axisPaint = Paint()..color = const Color(0xFFBDBDBD)..strokeWidth = 1;
    final gridPaint = Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 1;

    final chartRect =
        Rect.fromLTWH(padding + 24, 8, size.width - padding * 2 - 24, size.height - padding * 1.6);
    final left = chartRect.left, bottom = chartRect.bottom, top = chartRect.top, right = chartRect.right;

    // Ejes
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    // Rejilla Y
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final step = (d.maxValue / 5).ceil();
    for (int i = 0; i <= 5; i++) {
      final yVal = i * step;
      final y = bottom - (chartRect.height * (yVal / (d.maxValue == 0 ? 1 : d.maxValue)));
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      final label = yVal.toString();
      textPainter.text =
          TextSpan(text: label, style: const TextStyle(fontSize: 10, color: Colors.grey));
      textPainter.layout();
      textPainter.paint(canvas, Offset(left - textPainter.width - 6, y - textPainter.height / 2));
    }

    // Barras
    final groupCount = d.bars.length;
    if (groupCount == 0) return;
    final groupWidth = chartRect.width / groupCount;
    const barGap = 8.0;

    for (int gi = 0; gi < groupCount; gi++) {
      final group = d.bars[gi];
      final gx = left + groupWidth * gi;

      // etiqueta X
      final tp = TextPainter(
        text: TextSpan(text: group.groupLabel, style: const TextStyle(fontSize: 11)),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(gx + groupWidth / 2 - tp.width / 2, bottom + 6));

      if (d.stacked) {
        double accH = 0;
        for (int si = 0; si < group.series.length; si++) {
          final v = group.series[si].values.first;
          final h = chartRect.height * (v / (d.maxValue == 0 ? 1 : d.maxValue));
          final barRect =
              Rect.fromLTWH(gx + groupWidth * 0.25, bottom - (h + accH), groupWidth * 0.5, h);
          final paint = Paint()..color = d.palette[si % d.palette.length];
          canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(6)), paint);

          final lab = TextPainter(
            text: TextSpan(text: '$v', style: const TextStyle(fontSize: 10, color: Colors.black87)),
            textDirection: ui.TextDirection.ltr,
          );
          lab.layout();
          lab.paint(canvas, Offset(barRect.center.dx - lab.width / 2, barRect.top - lab.height - 2));

          accH += h;
        }
      } else {
        final serieCount = group.series.length;
        final totalBarsWidth = groupWidth * 0.7;
        final singleWidth =
            (totalBarsWidth - barGap * (serieCount - 1)) / (serieCount == 0 ? 1 : serieCount);
        final startX = gx + groupWidth * 0.15;

        for (int si = 0; si < serieCount; si++) {
          final v = group.series[si].values.first;
          final h = chartRect.height * (v / (d.maxValue == 0 ? 1 : d.maxValue));
          final x = startX + si * (singleWidth + barGap);
          final barRect = Rect.fromLTWH(x, bottom - h, singleWidth, h);
          final paint = Paint()..color = d.palette[si % d.palette.length];
          canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(6)), paint);

          final lab = TextPainter(
            text: TextSpan(text: '$v', style: const TextStyle(fontSize: 10, color: Colors.black87)),
            textDirection: ui.TextDirection.ltr,
          );
          lab.layout();
          lab.paint(canvas, Offset(barRect.center.dx - lab.width / 2, barRect.top - lab.height - 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) => true;
}

// Barras por día (con eje X de fechas comprimidas)
class BarPoint {
  final String label; // yyyy-MM-dd
  final int value;
  BarPoint(this.label, this.value);
}

class BarChartByDay extends StatelessWidget {
  final List<BarPoint> series;
  const BarChartByDay({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(
          child: Text('Sin datos en el rango seleccionado', style: TextStyle(color: Colors.grey)));
    }
    final maxVal = series.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(
      builder: (_, c) {
        return CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _BarDayPainter(series, maxVal),
        );
      },
    );
  }
}

class _BarDayPainter extends CustomPainter {
  final List<BarPoint> d;
  final int maxVal;
  _BarDayPainter(this.d, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 36.0;
    final axisPaint = Paint()..color = const Color(0xFFBDBDBD)..strokeWidth = 1;
    final gridPaint = Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 1;
    final chart =
        Rect.fromLTWH(padding + 24, 8, size.width - padding * 2 - 24, size.height - padding * 1.6);
    final left = chart.left, bottom = chart.bottom, top = chart.top, right = chart.right;

    // Ejes
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    // Rejilla Y
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    final step = (maxVal / 5).ceil();
    for (int i = 0; i <= 5; i++) {
      final yVal = i * step;
      final y = bottom - (chart.height * (yVal / (maxVal == 0 ? 1 : maxVal)));
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      tp.text = TextSpan(text: yVal.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
      tp.textDirection = ui.TextDirection.ltr;
      tp.layout();
      tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
    }

    // Barras
    final count = d.length;
    final barW = chart.width / (count == 0 ? 1 : count);
    for (int i = 0; i < count; i++) {
      final v = d[i].value;
      final h = chart.height * (v / (maxVal == 0 ? 1 : maxVal));
      final x = left + i * barW;
      final rect = Rect.fromLTWH(x + barW * 0.15, bottom - h, barW * 0.7, h);
      final paint = Paint()..color = const Color(0xFF90CAF9);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

      // etiquetas X (cada ~7 días)
      if (i % (count ~/ 7 + 1) == 0 || i == count - 1) {
        final lbl = d[i].label.substring(5); // mm-dd
        tp.text = TextSpan(text: lbl, style: const TextStyle(fontSize: 10));
        tp.textDirection = ui.TextDirection.ltr;
        tp.layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, bottom + 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarDayPainter oldDelegate) => true;
}

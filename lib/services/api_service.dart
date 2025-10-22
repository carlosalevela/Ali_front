import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class ApiService {
  // Base de API: ahora viene de Env (Vercel/CI o build local)
  // Mantengo tus prefijos exactos del backend:
  static const String _usersBase   = '/Alipsicoorientadora/usuarios';
  static const String _tests9Base  = '/Alipsicoorientadora/tests-grado9';
  static const String _tests10Base = '/Alipsicoorientadora/tests-grado10-11';

  String get _base => _trimRightSlash(Env.apiBaseUrl);
  static String _trimRightSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  Uri _u(String path, {Map<String, dynamic>? query}) {
    final p = path.startsWith('/') ? path : '/$path';
    final qp = query?.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return Uri.parse('$_base$p').replace(queryParameters: qp);
  }

  // ==================== AUTH / USUARIOS ====================

  // Función de inicio de sesión
  Future<Map<String, dynamic>> login(String username, String password, String email) async {
    final url = _u('$_usersBase/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final decoded = _decodeJWT(data['access']);
      final rol = decoded['rol'];
      final nombre = decoded['nombre'];
      final grado = decoded['grado']?.toString() ?? '';
      final edad = decoded['edad']?.toString() ?? '';
      final userId = (decoded['user_id'] as num?)?.toInt() ?? 0;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      await prefs.setString('rol', rol ?? '');
      await prefs.setString('nombre', nombre ?? '');
      await prefs.setString('grado', grado);
      await prefs.setString('edad', edad);
      await prefs.setInt('user_id', userId);

      return {'success': true, 'role': rol};
    } else {
      return {'success': false, 'message': 'Credenciales incorrectas'};
    }
  }

  // Función de registro
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final url = _u('$_usersBase/registro/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'message': jsonDecode(response.body)};
    }
  }

  // Obtener todos los usuarios (solo para admin)
  Future<List<Map<String, dynamic>>> fetchUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = _u('$_usersBase/usuarios/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  // 🔍 Buscar usuarios (nombre, email o username)
  Future<List<Map<String, dynamic>>> buscarUsuarios({
    String nombre = '',
    String email = '',
    String username = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = _u('$_usersBase/usuarios/', query: {
      if (nombre.isNotEmpty) 'nombre': nombre,
      if (email.isNotEmpty) 'email': email,
      if (username.isNotEmpty) 'username': username,
    });

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al buscar usuarios: ${response.statusCode}');
    }
  }

  // Eliminar un usuario
  Future<bool> deleteUsuario(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = _u('$_usersBase/usuarios/$id/');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  // Editar un usuario
  Future<bool> editarUsuario(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = _u('$_usersBase/usuarios/$id/');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  // Decodificar token JWT
  Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded);
  }

  // ========================= TESTS GRADO 9 =========================

  // Enviar test grado 9
  Future<Map<String, dynamic>> enviarTestGrado9(Map<String, dynamic> respuestas) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');

    final url = _u('$_tests9Base/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': respuestas,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'resultado': data};
    } else {
      return {
        'success': false,
        'message': 'Error en el test: ${response.body}'
      };
    }
  }

  // Obtener resultado test grado 9 por ID
  Future<Map<String, dynamic>> fetchResultadoTest9PorId(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = _u('$_tests9Base/resultado/$testId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener resultado test: ${response.statusCode}');
    }
  }

  // Obtener tests grado 9 por usuario
  Future<List<dynamic>> fetchTestsGrado9PorUsuario(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = _u('$_tests9Base/usuario/$userId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener tests de usuario: ${response.statusCode}');
    }
  }

  // Listar mis tests 9
  Future<List<Map<String, dynamic>>> listarMisTestsGrado9() async {
    final url = _u('$_tests9Base/'); // GET list
    final resp = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('No se pudo cargar el historial (${resp.statusCode})');
    }
  }

  Future<Map<String, dynamic>> obtenerResultadoTest9PorId(int testId) async {
    final url = _u('$_tests9Base/resultado/$testId/');
    final resp = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'error': 'No se pudo obtener el resultado ($testId): ${resp.statusCode}'
      };
    }
  }

  // Feed admin 9 con filtros
  Future<List<Map<String, dynamic>>> fetchTestsGrado9({
    String? estado,
    String? orden,
    int? limit,
    int? offset,
  }) async {
    final url = _u('$_tests9Base/', query: {
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (orden  != null && orden.isNotEmpty)  'orden': orden,
      if (limit  != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    });
    final resp = await http.get(url, headers: await _authHeaders());

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al listar tests 9° (${resp.statusCode})');
    }
  }

  // ===================== TESTS GRADO 10/11 =====================

  // Enviar test grado 10/11
  Future<Map<String, dynamic>> enviarTestGrado10y11(Map<String, String> respuestas) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt('user_id');

    final url = _u('$_tests10Base/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario': userId,
        'respuestas': respuestas,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'resultado': data};
    } else {
      return {
        'success': false,
        'message': 'Error en el test: ${response.statusCode} ${response.body}',
      };
    }
  }

  // Obtener tests 10/11 por usuario
  Future<List<dynamic>> fetchTestsGrado10y11PorUsuario(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = _u('$_tests10Base/usuario/$userId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener tests de usuario 10/11: ${response.statusCode}');
    }
  }

  // Obtener resultado test 10/11 por ID
  Future<Map<String, dynamic>> fetchResultadoTest10y11PorId(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url = _u('$_tests10Base/resultado/$testId/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener resultado test 10/11: ${response.statusCode}');
    }
  }

  // Listar mis tests 10/11
  Future<List<Map<String, dynamic>>> listarMisTestsGrado10y11() async {
    final url = _u('$_tests10Base/');
    final resp = await http.get(
      url,
      headers: await _authHeaders(),
    );

    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('No se pudo cargar el historial 10/11 (${resp.statusCode})');
    }
  }

  // Feed admin 10/11 con filtros
  Future<List<Map<String, dynamic>>> fetchTestsGrado10y11({
    String? estado,
    String? orden,
    int? limit,
    int? offset,
  }) async {
    final url = _u('$_tests10Base/', query: {
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (orden  != null && orden.isNotEmpty)  'orden': orden,
      if (limit  != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    });
    final resp = await http.get(url, headers: await _authHeaders());

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al listar tests 10/11 (${resp.statusCode})');
    }
  }

  // =================== PROGRESO / HELPERS ===================

  // Formatea una línea de progreso legible para la UI
  String _formatProgreso(Map<String, dynamic> t, {required int total}) {
    final estado = t['estado']?.toString() ?? '';
    final resp   = (t['respondidas'] as num?)?.toInt() ?? 0;
    final ult    = (t['ultima_pregunta'] as num?)?.toInt() ?? 0;
    final pct    = (t['progreso_pct'] as num?)?.toDouble() ?? (total > 0 ? (resp / total) * 100 : 0);

    if (estado == 'FINALIZADO') return 'Finalizado';
    if (estado == 'EN_PROGRESO') return 'En progreso: $resp/$total (P$ult) ${pct.toStringAsFixed(0)}%';
    return '—';
  }

  // Devuelve el mejor test para pintar progreso
  Map<String, dynamic>? _pickBestTestForUser(
    List<Map<String, dynamic>> feed,
    int userId,
  ) {
    final mine = feed.where((t) => t['usuario'] == userId).toList();
    if (mine.isEmpty) return null;

    final enProg = mine.where((t) => t['estado'] == 'EN_PROGRESO').toList();
    if (enProg.isNotEmpty) return enProg.first;

    mine.sort((a, b) => (b['fecha_realizacion'] ?? '').toString().compareTo((a['fecha_realizacion'] ?? '').toString()));
    return mine.first;
  }

  Future<Map<String, dynamic>> progresoUsuarioGrado9(int userId, {int total = 57}) async {
    try {
      final feedProg = await fetchTestsGrado9(estado: 'EN_PROGRESO', orden: 'actividad', limit: 200, offset: 0);
      Map<String, dynamic>? best = _pickBestTestForUser(feedProg, userId);

      if (best == null) {
        final testsUsr = await fetchTestsGrado9PorUsuario(userId);
        if (testsUsr.isNotEmpty) {
          best = Map<String, dynamic>.from(testsUsr.first);
        }
      }

      if (best == null) return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};

      final progreso = _formatProgreso(best, total: total);
      final String ultimaRec = (best['resultado'] as String?) ?? '—';

      return {
        'progreso': progreso,
        'ultimaRecomendacion': ultimaRec,
        'testId': best['id'],
      };
    } catch (_) {
      return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};
    }
  }

  Future<Map<String, dynamic>> progresoUsuarioGrado10y11(int userId, {int total = 40}) async {
    try {
      final feedProg = await fetchTestsGrado10y11(estado: 'EN_PROGRESO', orden: 'actividad', limit: 200, offset: 0);
      Map<String, dynamic>? best = _pickBestTestForUser(feedProg, userId);

      if (best == null) {
        final testsUsr = await fetchTestsGrado10y11PorUsuario(userId);
        if (testsUsr.isNotEmpty) {
          best = Map<String, dynamic>.from(testsUsr.first);
        }
      }

      if (best == null) return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};

      final progreso = _formatProgreso(best, total: total);
      final String ultimaRec = (best['resultado'] as String?) ?? '—';

      return {
        'progreso': progreso,
        'ultimaRecomendacion': ultimaRec,
        'testId': best['id'],
      };
    } catch (_) {
      return {'progreso': '—', 'ultimaRecomendacion': '—', 'testId': null};
    }
  }

  // ============ RECUPERAR CONTRASEÑA ============

  /// 1) Solicitar enlace de recuperación
  Future<Map<String, dynamic>> solicitarRecuperacion(String email) async {
    final url = _u('$_usersBase/recuperacion/contrasena/'); // ajusta si en backend es /contrasena/
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return {'success': true, 'detail': data['detail'] ?? 'Si el correo existe, enviaremos un enlace.'};
      } else {
        return {'success': false, 'message': 'Error ${resp.statusCode}: ${resp.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de red: $e'};
    }
  }

  /// 2) Confirmar y fijar nueva contraseña
  Future<Map<String, dynamic>> confirmarRecuperacion({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final url = _u('$_usersBase/recuperacion/contrasena-confirmada/'); // confirma tu ruta exacta en backend
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'token': token, 'new_password': newPassword}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return {'success': true, 'detail': data['detail'] ?? 'Contraseña actualizada.'};
      } else if (resp.statusCode == 400) {
        return {'success': false, 'message': jsonDecode(resp.body)};
      } else {
        return {'success': false, 'message': 'Error ${resp.statusCode}: ${resp.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de red: $e'};
    }
  }

  // =====================================================
  // =============== NUEVO: RETOMAR TEST 9° ==============
  // =====================================================

  // headers con token
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // guardar/leer/limpiar id del test actual (borrador)
  Future<void> _saveCurrentTest9Id(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grado9_current_test_id', id);
  }

  Future<int?> _getCurrentTest9Id() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('grado9_current_test_id');
  }

  Future<void> _clearCurrentTest9Id() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('grado9_current_test_id');
  }

  /// Crea o recupera el borrador EN_PROGRESO (POST /tests-grado9/iniciar/)
  Future<Map<String, dynamic>> iniciarOContinuarTestGrado9() async {
    final url = _u('$_tests9Base/iniciar/');
    final resp = await http.post(url, headers: await _authHeaders());

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final id = (data['id'] as num).toInt();
      await _saveCurrentTest9Id(id);
      return data;
    } else {
      throw Exception('No se pudo iniciar/retomar el test 9° (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Trae el test actual si existe; si no, inicia/retoma uno nuevo.
  Future<Map<String, dynamic>> cargarTestGrado9Actual() async {
    final currentId = await _getCurrentTest9Id();
    if (currentId != null) {
      final url = _u('$_tests9Base/$currentId/');
      final resp = await http.get(url, headers: await _authHeaders());
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      // si el id local ya no existe en el backend, lo limpiamos
      await _clearCurrentTest9Id();
    }
    return await iniciarOContinuarTestGrado9();
  }

  /// Guarda UNA respuesta (PATCH /{id}/progreso/)
  Future<Map<String, dynamic>> guardarRespuestaTest9({
    required int pregunta, // 1..57
    required String respuesta,
    int? ultimaPregunta,
  }) async {
    final id = await _getCurrentTest9Id();
    if (id == null) throw Exception('No hay test 9° en curso.');

    final url = _u('$_tests9Base/$id/progreso/');

    final payload = <String, dynamic>{
      'pregunta': pregunta,
      'respuesta': respuesta,
      if (ultimaPregunta != null) 'ultima_pregunta': ultimaPregunta,
    };

    final resp = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['estado'] == 'FINALIZADO') {
        // si terminó, limpiamos el id local
        await _clearCurrentTest9Id();
      }
      return data;
    } else {
      throw Exception('Error al guardar respuesta (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Guarda VARIAS respuestas de una (PATCH /{id}/progreso/)
  Future<Map<String, dynamic>> guardarRespuestasTest9Bulk(
    Map<int, String> respuestas, {
    int? ultimaPregunta,
  }) async {
    final id = await _getCurrentTest9Id();
    if (id == null) throw Exception('No hay test 9° en curso.');

    final url = _u('$_tests9Base/$id/progreso/');

    final mapa = <String, String>{};
    respuestas.forEach((i, r) => mapa['pregunta_$i'] = r);

    final payload = <String, dynamic>{
      'respuestas': mapa,
      if (ultimaPregunta != null) 'ultima_pregunta': ultimaPregunta,
    };

    final resp = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['estado'] == 'FINALIZADO') {
        await _clearCurrentTest9Id();
      }
      return data;
    } else {
      throw Exception('Error al guardar respuestas (${resp.statusCode}): ${resp.body}');
    }
  }

  /// Si el test actual ya finalizó, devuelve el objeto completo; si no, null.
  Future<Map<String, dynamic>?> resultadoTest9Actual() async {
    final id = await _getCurrentTest9Id();
    if (id == null) return null;

    final url = _u('$_tests9Base/$id/');
    final resp = await http.get(url, headers: await _authHeaders());

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['estado'] == 'FINALIZADO') ? data : null;
    } else {
      return null;
    }
  }
}

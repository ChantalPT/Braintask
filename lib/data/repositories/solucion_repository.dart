import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soluciones.dart';

class SolucionesRepository {
  final SupabaseClient _supabase;

  SolucionesRepository(this._supabase);

  Future<List<Solucion>> getSolucionesPorPublicacion(int idPublicacion) async {
    final data = await _supabase
        .from('soluciones')
        .select()
        .eq('id_publicacion', idPublicacion)
        .order('fecha_subida', ascending: false);
    return (data as List).map((e) => Solucion.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getSolucionesVistaPorPublicacion(
    int idPublicacion,
  ) async {
    try {
      final data = await _supabase.rpc(
        'get_soluciones_publicacion',
        params: {'p_id_publicacion': idPublicacion},
      );

      return (data as List)
          .map((json) => _mapSolucionVista(Map<String, dynamic>.from(json)))
          .toList();
    } on PostgrestException catch (e) {
      final rpcNoInstalada =
          e.code == 'PGRST202' ||
          e.message.contains('get_soluciones_publicacion');
      if (!rpcNoInstalada) {
        rethrow;
      }
    }

    final data = await _supabase
        .from('soluciones')
        .select('*, usuarios (nombre, apellido)')
        .eq('id_publicacion', idPublicacion)
        .order('fecha_subida', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> subirSolucionDesdeApp({
    required int idPublicacion,
    required String comentario,
    String? archivoUrl,
  }) async {
    try {
      final data = await _supabase.rpc(
        'subir_solucion',
        params: {
          'p_id_publicacion': idPublicacion,
          'p_comentario_solucion': comentario,
          'p_archivo_url': archivoUrl,
        },
      );

      final rows = data as List;
      if (rows.isEmpty) {
        throw Exception('La solucion no se guardo.');
      }
      return _mapSolucionVista(Map<String, dynamic>.from(rows.first));
    } on PostgrestException catch (e) {
      final rpcNoInstalada =
          e.code == 'PGRST202' || e.message.contains('subir_solucion');
      if (!rpcNoInstalada) {
        rethrow;
      }
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesion para enviar una solucion.');
    }

    final usuario = await _supabase
        .from('usuarios')
        .select('cedula')
        .eq('auth_user_id', user.id)
        .single();

    final data = await _supabase
        .from('soluciones')
        .insert({
          'id_publicacion': idPublicacion,
          'usuario_id': user.id,
          'cedula_usuario_solver': usuario['cedula'],
          'comentario_solucion': comentario,
          'archivo_url': archivoUrl,
          'aceptada': false,
          'fecha_subida': DateTime.now().toIso8601String(),
        })
        .select('*, usuarios (nombre, apellido)')
        .single();

    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> _mapSolucionVista(Map<String, dynamic> json) {
    final nombre = json['nombre'];
    final apellido = json['apellido'];
    final usuario = nombre == null && apellido == null
        ? null
        : {'nombre': nombre, 'apellido': apellido};

    return {
      'id_solucion': json['id_solucion'],
      'id_publicacion': json['id_publicacion'],
      'usuario_id': json['usuario_id'],
      'cedula_usuario_solver': json['cedula_usuario_solver'],
      'archivo_url': json['archivo_url'],
      'comentario_solucion': json['comentario_solucion'],
      'fecha_subida': json['fecha_subida'],
      'aceptada': json['aceptada'],
      'usuarios': usuario,
    };
  }

  Future<bool> publicacionEstaPendiente(int idPublicacion) async {
    final data = await _supabase
        .from('publicaciones')
        .select('estado')
        .eq('id_publicacion', idPublicacion)
        .single();
    return data['estado'] != 'resuelto' && data['estado'] != 'pagado';
  }

  // Método original (solo marca aceptada, sin puntos)
  Future<void> aceptarSolucion({
    required int idPublicacion,
    required int idSolucion,
  }) async {
    try {
      await _supabase.rpc(
        'aceptar_solucion',
        params: {
          'p_id_publicacion': idPublicacion,
          'p_id_solucion': idSolucion,
        },
      );
      return;
    } on PostgrestException catch (e) {
      final rpcNoInstalada =
          e.code == 'PGRST202' || e.message.contains('aceptar_solucion');
      if (!rpcNoInstalada) {
        rethrow;
      }
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Debes iniciar sesión para aceptar una solución.');
    }

    final publicacion = await _supabase
        .from('publicaciones')
        .select('autor_id, estado')
        .eq('id_publicacion', idPublicacion)
        .single();

    if (publicacion['autor_id'] != userId) {
      throw Exception('Solo el autor puede aceptar una solución.');
    }

    if (publicacion['estado'] == 'resuelto' ||
        publicacion['estado'] == 'pagado') {
      throw Exception('Esta publicacion ya fue resuelta.');
    }

    final solucion = await _supabase
        .from('soluciones')
        .select('id_solucion, usuario_id')
        .eq('id_solucion', idSolucion)
        .eq('id_publicacion', idPublicacion)
        .maybeSingle();

    if (solucion == null) {
      throw Exception(
        'La solución seleccionada no pertenece a esta publicación.',
      );
    }

    await _supabase
        .from('soluciones')
        .update({'aceptada': false})
        .eq('id_publicacion', idPublicacion);

    await _supabase
        .from('soluciones')
        .update({'aceptada': true})
        .eq('id_solucion', idSolucion)
        .eq('id_publicacion', idPublicacion);

    await _supabase
        .from('publicaciones')
        .update({'estado': 'resuelto', 'id_resolutor': solucion['usuario_id']})
        .eq('id_publicacion', idPublicacion);
  }

  Future<void> subirSolucion({
    required int idPublicacion,
    required String cedulaUsuario,
    required String? comentario,
    File? archivo,
  }) async {
    final estaPendiente = await publicacionEstaPendiente(idPublicacion);
    if (!estaPendiente) {
      throw Exception('Esta publicación ya fue resuelta.');
    }

    String? archivoUrl;
    if (archivo != null) {
      final extension = archivo.path.split('.').last;
      final fileName =
          'soluciones/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _supabase.storage.from('soluciones').upload(fileName, archivo);
      archivoUrl = _supabase.storage.from('soluciones').getPublicUrl(fileName);
    }
    await _supabase.from('soluciones').insert({
      'id_publicacion': idPublicacion,
      'cedula_usuario_solver': cedulaUsuario,
      'archivo_url': archivoUrl,
      'comentario_solucion': comentario,
      'fecha_subida': DateTime.now().toIso8601String(),
    });
  }
}

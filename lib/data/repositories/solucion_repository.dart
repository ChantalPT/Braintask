import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soluciones.dart';

class SolucionesRepository {
  final SupabaseClient _supabase;

  SolucionesRepository(this._supabase);

  /// Obtiene soluciones con datos del autor via cedula_usuario_solver → usuarios.cedula
/// Obtiene soluciones con datos del autor via cedula_usuario_solver → usuarios.cedula
  Future<List<Solucion>> getSolucionesPorPublicacion(int idPublicacion) async {
    final data = await _supabase
        .from('soluciones')
        // 🚨 Pedimos la columna virtual 'total_reportes' explícitamente desde Supabase
        .select('*, total_reportes, usuarios!cedula_usuario_solver(nombre, apellido)')
        .eq('id_publicacion', idPublicacion)
        .order('fecha_subida', ascending: false);
        
    // 💡 Al mapear con Solucion.fromJson, tu Provider volverá a compilar limpiamente al instante
    return (data as List).map((e) => Solucion.fromJson(e)).toList();
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

    if (publicacion['estado'] == 'resuelto') {
      throw Exception('Esta publicación ya fue resuelta.');
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
    required int cedulaUsuarioSolver,
    required String usuarioId,
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
      'cedula_usuario_solver': cedulaUsuarioSolver,
      'usuario_id': usuarioId,
      'archivo_url': archivoUrl,
      'comentario_solucion': comentario,
      'fecha_subida': DateTime.now().toIso8601String(),
      'aceptada': false,
    });
  }
}

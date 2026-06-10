import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soluciones.dart'; // ← Importa el archivo real

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

  Future<bool> publicacionEstaPendiente(int idPublicacion) async {
    final data = await _supabase
        .from('publicaciones')
        .select('estado')
        .eq('id_publicacion', idPublicacion)
        .single();

    return data['estado'] != 'resuelto' && data['estado'] != 'pagado';
  }

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
      throw Exception('Debes iniciar sesion para aceptar una solucion.');
    }

    final publicacion = await _supabase
        .from('publicaciones')
        .select('autor_id, estado')
        .eq('id_publicacion', idPublicacion)
        .single();

    if (publicacion['autor_id'] != userId) {
      throw Exception('Solo el autor puede aceptar una solucion.');
    }

    if (publicacion['estado'] == 'resuelto') {
      throw Exception('Esta publicacion ya fue resuelta.');
    }

    final solucion = await _supabase
        .from('soluciones')
        .select('id_solucion')
        .eq('id_solucion', idSolucion)
        .eq('id_publicacion', idPublicacion)
        .maybeSingle();

    if (solucion == null) {
      throw Exception(
        'La solucion seleccionada no pertenece a esta publicacion.',
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
        .update({'estado': 'resuelto'})
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
      throw Exception('Esta publicacion ya fue resuelta.');
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

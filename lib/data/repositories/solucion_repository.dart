import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soluciones.dart';

class SolucionesRepository {
  final SupabaseClient _supabase;

  SolucionesRepository(this._supabase);

  /// Obtiene soluciones con datos del autor via cedula_usuario_solver → usuarios.cedula
  Future<List<Solucion>> getSolucionesPorPublicacion(int idPublicacion) async {
    final data = await _supabase
        .from('soluciones')
        .select('*, usuarios!cedula_usuario_solver(nombre, apellido)')
        .eq('id_publicacion', idPublicacion)
        .order('fecha_subida', ascending: false);
    return (data as List).map((e) => Solucion.fromJson(e)).toList();
  }

  Future<void> subirSolucion({
    required int idPublicacion,
    required int cedulaUsuarioSolver,
    required String usuarioId,
    required String? comentario,
    File? archivo,
  }) async {
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

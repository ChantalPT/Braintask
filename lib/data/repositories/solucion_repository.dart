import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soluciones.dart';   // ← Importa el archivo real

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

  Future<void> subirSolucion({
    required int idPublicacion,
    required String cedulaUsuario,
    required String? comentario,
    File? archivo,
  }) async {
    String? archivoUrl;
    if (archivo != null) {
      final extension = archivo.path.split('.').last;
      final fileName = 'soluciones/${DateTime.now().millisecondsSinceEpoch}.$extension';
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
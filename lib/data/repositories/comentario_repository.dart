import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comentarios.dart';

class ComentarioRepository {
  final SupabaseClient _supabase;

  ComentarioRepository(this._supabase);

  /// Obtiene todos los comentarios de una publicación con datos del autor.
  Future<List<Comentario>> obtenerComentarios(int publicacionId) async {
    final data = await _supabase
        .from('foro_comentarios')
        .select('*, usuarios(nombre, apellido)')
        .eq('publicacion_id', publicacionId)
        .order('fecha_creacion', ascending: true);
    return (data as List).map((e) => Comentario.fromJson(e)).toList();
  }

  /// Inserta un nuevo comentario en la tabla foro_comentarios.
  Future<void> insertarComentario({
    required int publicacionId,
    required int usuarioCedula,
    required String contenido,
  }) async {
    await _supabase.from('foro_comentarios').insert({
      'publicacion_id': publicacionId,
      'usuario_cedula': usuarioCedula,
      'contenido': contenido,
      'votos': 0,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });
  }

  /// Incrementa o decrementa los votos de un comentario en [delta] (+1 o -1).
  Future<void> votarComentario({
    required int idComentario,
    required int delta,
  }) async {
    final data = await _supabase
        .from('foro_comentarios')
        .select('votos')
        .eq('id_comentario', idComentario)
        .single();

    final int votosActuales = data['votos'] ?? 0;
    final int nuevosVotos = votosActuales + delta;

    await _supabase
        .from('foro_comentarios')
        .update({'votos': nuevosVotos})
        .eq('id_comentario', idComentario);
  }
}

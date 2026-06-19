import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comentarios.dart';

class ComentarioRepository {
  final SupabaseClient _supabase;

  ComentarioRepository(this._supabase);

  /// Obtiene todos los comentarios de una publicación con datos del autor.
  Future<List<Comentario>> obtenerComentarios(int publicacionId) async {
    // 1. Obtenemos los comentarios normales
    final data = await _supabase
        .from('foro_comentarios')
        .select('*, usuarios(nombre, apellido, auth_user_id)') // Asegúrate de pedir el auth_user_id para saber a quién reportar
        .eq('publicacion_id', publicacionId)
        .order('fecha_creacion', ascending: true);

    // 2. Por cada comentario, contamos sus reportes de forma segura
    final List<Comentario> comentariosList = [];
    
    for (var c in data) {
      final mutableC = Map<String, dynamic>.from(c);
      
      try {
        final reportes = await _supabase
            .from('reportes')
            .select('id_objeto_reportado')
            .eq('tipo_reporte', 'comentario') // Buscamos solo reportes de tipo comentario
            .eq('id_objeto_reportado', mutableC['id_comentario']);
            
        mutableC['total_reportes'] = reportes.length;
      } catch (e) {
        mutableC['total_reportes'] = 0; // Si falla, asumimos 0 para no colgar la app
      }
      
      comentariosList.add(Comentario.fromJson(mutableC));
    }

    return comentariosList;
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

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/foro_pregunta.dart';
import '../models/foro_respuesta.dart';

class ForoRepository {
  final SupabaseClient _supabase;

  ForoRepository(this._supabase);

  Future<List<ForoPregunta>> getPreguntas({String? search}) async {
    var query = _supabase.from('publicaciones').select('''
      id_publicacion,
      titulo,
      descripcion,
      votos_foro,
      tiempo,
      autor:usuarios(nombre, apellido),
      foro_respuestas(id_respuesta)
    ''');
    if (search != null && search.isNotEmpty) {
      query = query.ilike('titulo', '%$search%');
    }
    final data = await query.order('tiempo', ascending: false);
    return (data as List).map((e) => ForoPregunta.fromJson(e)).toList();
  }

  // --- MODIFICADO PARA EXTRAER LAS ESTRELLAS ---
  Future<List<ForoRespuesta>> getRespuestas(int idPregunta) async {
    final data = await _supabase
        .from('foro_respuestas')
        .select('''
          id_respuesta,
          id_publicacion,
          contenido,
          tiempo,
          usuarios(nombre, apellido),
          calificacion_respuestas(estrellas, usuario_id)
        ''')
        .eq('id_publicacion', idPregunta)
        .order('tiempo', ascending: true);
        
    return (data as List).map((e) => ForoRespuesta.fromJson(e)).toList();
  }

  Future<void> votarPregunta(int id, bool isUpvote) async {
    final current = await _supabase.from('publicaciones').select('votos_foro').eq('id_publicacion', id).single();
    final currentScore = (current['votos_foro'] as int?) ?? 0;

    await _supabase.from('publicaciones').update({'votos_foro': isUpvote ? currentScore + 1 : currentScore - 1}).eq('id_publicacion', id);
  }

  // --- NUEVA LÓGICA: CALIFICAR RESPUESTA CON ESTRELLAS ---
  Future<void> calificarRespuesta(int idRespuesta, int estrellas) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final insertResult = await _supabase
        .from('calificacion_respuestas')
        .insert({
          'id_respuesta': idRespuesta,
          'usuario_id': userId,
          'estrellas': estrellas
        })
        .select();

    if (insertResult.isEmpty) {
      throw Exception('El voto no se guardó. Revisa las políticas RLS.');
    }
  }

  Future<void> agregarRespuesta(int idPregunta, String contenido) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase.from('foro_respuestas').insert({
      'id_publicacion': idPregunta,
      'usuario_id': userId,
      'contenido': contenido,
    });
  }
}
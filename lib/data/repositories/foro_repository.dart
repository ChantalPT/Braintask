import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/foro_pregunta.dart';
import '../models/foro_respuesta.dart';

class ForoRepository {
  final SupabaseClient _supabase;

  ForoRepository(this._supabase);

  Future<List<ForoPregunta>> getPreguntas({String? search}) async {
    // Usamos la tabla "publicaciones" como la tabla de Preguntas para el foro
    // Hacemos join con "usuarios" a través de autor_id para obtener el nombre.
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

  Future<List<ForoRespuesta>> getRespuestas(int idPregunta) async {
    // Usamos una nueva tabla "foro_respuestas"
    final data = await _supabase
        .from('foro_respuestas')
        .select('''
          id_respuesta,
          id_publicacion,
          contenido,
          votos,
          tiempo,
          usuarios(nombre, apellido)
        ''')
        .eq('id_publicacion', idPregunta)
        .order('votos', ascending: false);
    return (data as List).map((e) => ForoRespuesta.fromJson(e)).toList();
  }

  Future<void> votarPregunta(int id, bool isUpvote) async {
    // Votamos en la tabla de publicaciones usando la nueva columna votos_foro
    final current = await _supabase
        .from('publicaciones')
        .select('votos_foro')
        .eq('id_publicacion', id)
        .single();
    final currentScore = (current['votos_foro'] as int?) ?? 0;

    final updateResult = await _supabase
        .from('publicaciones')
        .update({'votos_foro': isUpvote ? currentScore + 1 : currentScore - 1})
        .eq('id_publicacion', id)
        .select();

    if (updateResult.isEmpty) {
      throw Exception(
        'El voto no se guardó. Posible problema de permisos RLS en Supabase en la tabla "publicaciones".',
      );
    }
  }

  Future<void> votarRespuesta(int id, bool isUpvote) async {
    // Votamos en la tabla de respuestas
    final current = await _supabase
        .from('foro_respuestas')
        .select('votos')
        .eq('id_respuesta', id)
        .single();
    final currentScore = (current['votos'] as int?) ?? 0;

    final updateResult = await _supabase
        .from('foro_respuestas')
        .update({'votos': isUpvote ? currentScore + 1 : currentScore - 1})
        .eq('id_respuesta', id)
        .select();

    if (updateResult.isEmpty) {
      throw Exception(
        'El voto no se guardó. Posible problema de permisos RLS en Supabase en la tabla "foro_respuestas".',
      );
    }
  }

  Future<void> agregarRespuesta(int idPregunta, String contenido) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase.from('foro_respuestas').insert({
      'id_publicacion': idPregunta,
      'usuario_id': userId,
      'contenido': contenido,
      // votos y tiempo tomarán sus valores por defecto
    });
  }
}

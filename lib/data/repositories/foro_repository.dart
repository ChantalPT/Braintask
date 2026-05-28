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
      puntuacion,
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
        .order('tiempo', ascending: true);

    return (data as List).map((e) => ForoRespuesta.fromJson(e)).toList();
  }

  Future<void> votarPregunta(int id, bool isUpvote) async {
    await ajustarVotoPregunta(id, isUpvote ? 1 : -1);
  }

  Future<void> ajustarVotoPregunta(int id, int difference) async {
    if (difference == 0) return;

    final current = await _supabase
        .from('publicaciones')
        .select('votos_foro')
        .eq('id_publicacion', id)
        .single();
    final currentScore = (current['votos_foro'] as int?) ?? 0;
    final newScore = currentScore + difference;

    await _supabase
        .from('publicaciones')
        .update({'votos_foro': newScore})
        .eq('id_publicacion', id);
  }

  Future<void> calificarRespuesta(int idRespuesta, int estrellas) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    if (estrellas < 1 || estrellas > 5) {
      throw Exception('La calificacion debe estar entre 1 y 5 estrellas');
    }

    final updateResult = await _supabase
        .from('foro_respuestas')
        .update({'votos': estrellas})
        .eq('id_respuesta', idRespuesta)
        .select();

    if (updateResult.isEmpty) {
      throw Exception(
        'La calificacion no se guardo. Revisa las politicas RLS.',
      );
    }
  }

  Future<void> agregarRespuesta(int idPregunta, String contenido) async {
    final contenidoLimpio = contenido.trim();
    if (contenidoLimpio.isEmpty) {
      throw Exception('La respuesta no puede estar vacia.');
    }

    final userId = await _asegurarUsuarioActual();

    final insertResult = await _supabase.from('foro_respuestas').insert({
      'id_publicacion': idPregunta,
      'usuario_id': userId,
      'contenido': contenidoLimpio,
      'votos': 0,
    }).select();

    if (insertResult.isEmpty) {
      throw Exception('La solucion no se guardo. Revisa las politicas RLS.');
    }
  }

  Future<String> _asegurarUsuarioActual() async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final usuarioPorId = await _supabase
        .from('usuarios')
        .select('auth_user_id')
        .eq('auth_user_id', userId)
        .maybeSingle();

    if (usuarioPorId != null) return userId;

    final email = user?.email;
    if (email == null || email.trim().isEmpty) {
      throw Exception('Tu cuenta no tiene correo asociado.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final usuarioPorCorreo = await _supabase
        .from('usuarios')
        .select('correo')
        .ilike('correo', normalizedEmail)
        .maybeSingle();

    if (usuarioPorCorreo != null) {
      final updateResult = await _supabase
          .from('usuarios')
          .update({'auth_user_id': userId})
          .ilike('correo', normalizedEmail)
          .select('auth_user_id');

      if (updateResult.isEmpty) {
        throw Exception(
          'No se pudo vincular tu perfil de usuario. Revisa las politicas RLS.',
        );
      }

      return userId;
    }

    await _crearPerfilMinimo(userId, normalizedEmail);
    return userId;
  }

  Future<void> _crearPerfilMinimo(String userId, String email) async {
    final fallbackId = _idNumericoDesdeUuid(userId);
    final nombre = email.split('@').first;

    final insertResult = await _supabase
        .from('usuarios')
        .insert({
          'auth_user_id': userId,
          'nombre': nombre.isEmpty ? 'Usuario' : nombre,
          'apellido': '',
          'cedula': fallbackId,
          'carnet': fallbackId.toString(),
          'correo': email,
          'puntuacion': 0,
          'reputacion': 0,
          'total_calificaciones': 0,
          'reputacion_promedio': 0.0,
        })
        .select('auth_user_id');

    if (insertResult.isEmpty) {
      throw Exception(
        'No se pudo crear tu perfil de usuario. Revisa las politicas RLS.',
      );
    }
  }

  int _idNumericoDesdeUuid(String userId) {
    final hex = userId.replaceAll('-', '').padRight(12, '0').substring(0, 12);
    return int.parse(hex, radix: 16);
  }
}

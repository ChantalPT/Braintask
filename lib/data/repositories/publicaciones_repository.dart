import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/publicacion.dart';

class PublicacionesRepository {
  final SupabaseClient _supabase;

  PublicacionesRepository(this._supabase);

  Future<List<Publicacion>> getPublicaciones({
    String? estado,
    String? idMateria,
    String? idFacultad,
    String? tipo,
    String? search,
  }) async {
    var query = _supabase.from('publicaciones').select('''
          *,
          materias!inner (
            nombre_materias,
            id_facultad,
            facultades!left (nombre_facultad)
          )
        ''');

    if (estado != null && estado != 'todos') {
      query = query.eq('estado', estado);
    }

    if (idMateria != null) {
      query = query.eq('id_materia', idMateria);
    } else if (idFacultad != null) {
      query = query.eq('materias.id_facultad', idFacultad);
    }

    if (tipo != null) {
      query = query.eq('tipo', tipo);
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('titulo', '%$search%');
    }

    final data = await query.order('tiempo', ascending: false);
    return (data as List).map((json) => Publicacion.fromJson(json)).toList();
  }

  Future<double?> getAverageDifficulty(int publicacionId) async {
    final data = await _supabase
        .from('calificaciones_dificultad')
        .select('dificultad')
        .eq('id_publicacion', publicacionId);

    if (data.isEmpty) return null;

    int sum = 0;
    for (var item in data) {
      sum += (item['dificultad'] as num).toInt();
    }
    return sum / data.length;
  }

  Future<int> getComentariosCount(int publicacionId) async {
    try {
      final response = await _supabase
          .from('foro_comentarios')
          .select('id_comentario')
          .eq('publicacion_id', publicacionId);
      final count = (response as List).length;
      return count;
    } catch (e) {
      return 0;
    }
  }
}

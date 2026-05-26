class ForoPregunta {
  final int id;
  final String titulo;
  final String descripcion;
  final String autorNombre;
  final int votos;
  final int respuestasCount;
  final DateTime tiempo;
  final int userVote; // 1 = upvote, -1 = downvote, 0 = sin voto

  ForoPregunta({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.autorNombre,
    required this.votos,
    required this.respuestasCount,
    required this.tiempo,
    this.userVote = 0,
  });

  factory ForoPregunta.fromJson(Map<String, dynamic> json) {
    // Attempt to extract author name if joint
    String nombre = 'Anónimo';
    if (json['autor'] != null && json['autor'] is Map) {
      nombre = json['autor']['nombre'] ?? 'Anónimo';
      if (json['autor']['apellido'] != null) {
        nombre += ' ${json['autor']['apellido']}';
      }
    }

    // Contamos las respuestas devueltas
    int respCount = 0;
    if (json['foro_respuestas'] is List) {
      respCount = (json['foro_respuestas'] as List).length;
    }

    return ForoPregunta(
      id: json['id_publicacion'] ?? 0,
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'] ?? '',
      autorNombre: nombre,
      votos:
          json['votos_foro'] ??
          0, // Usar la nueva columna en lugar de 'puntuacion'
      respuestasCount: respCount, // Obtener recuento real de base de datos
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
    );
  }

  ForoPregunta copyWith({int? votos, int? respuestasCount, int? userVote}) {
    return ForoPregunta(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: votos ?? this.votos,
      respuestasCount: respuestasCount ?? this.respuestasCount,
      tiempo: tiempo,
      userVote: userVote ?? this.userVote,
    );
  }
}

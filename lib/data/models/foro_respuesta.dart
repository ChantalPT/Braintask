class ForoRespuesta {
  final int id;
  final int idPregunta;
  final String contenido;
  final String autorNombre;
  final int votos;
  final DateTime tiempo;
  final int userVote; // 1 = upvote, -1 = downvote, 0 = sin voto

  ForoRespuesta({
    required this.id,
    required this.idPregunta,
    required this.contenido,
    required this.autorNombre,
    required this.votos,
    required this.tiempo,
    this.userVote = 0,
  });

  factory ForoRespuesta.fromJson(Map<String, dynamic> json) {
    // Attempt to extract author name if joint
    String nombre = 'Anónimo';
    if (json['usuarios'] != null && json['usuarios'] is Map) {
      nombre = json['usuarios']['nombre'] ?? 'Anónimo';
      if (json['usuarios']['apellido'] != null) {
        nombre += ' ${json['usuarios']['apellido']}';
      }
    }

    return ForoRespuesta(
      id: json['id_respuesta'] ?? 0,
      idPregunta: json['id_publicacion'] ?? 0,
      contenido: json['contenido'] ?? '',
      autorNombre: nombre,
      votos: json['votos'] ?? 0,
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
    );
  }

  ForoRespuesta copyWith({int? votos, int? userVote}) {
    return ForoRespuesta(
      id: id,
      idPregunta: idPregunta,
      contenido: contenido,
      autorNombre: autorNombre,
      votos: votos ?? this.votos,
      tiempo: tiempo,
      userVote: userVote ?? this.userVote,
    );
  }
}

class ForoRespuesta {
  final int id;
  final int idPregunta;
  final String contenido;
  final String autorNombre;
  final double promedioEstrellas;
  final int totalVotos;
  final DateTime tiempo;
  final int userVote;

  ForoRespuesta({
    required this.id,
    required this.idPregunta,
    required this.contenido,
    required this.autorNombre,
    required this.promedioEstrellas,
    required this.totalVotos,
    required this.tiempo,
    this.userVote = 0,
  });

  factory ForoRespuesta.fromJson(Map<String, dynamic> json) {
    String nombre = 'Anonimo';
    if (json['usuarios'] != null && json['usuarios'] is Map) {
      nombre = json['usuarios']['nombre'] ?? 'Anonimo';
      if (json['usuarios']['apellido'] != null) {
        nombre += ' ${json['usuarios']['apellido']}';
      }
    }

    final estrellas = (json['votos'] as num?)?.toInt() ?? 0;
    final estrellasValidas = estrellas.clamp(0, 5);

    return ForoRespuesta(
      id: json['id_respuesta'] ?? 0,
      idPregunta: json['id_publicacion'] ?? 0,
      contenido: json['contenido'] ?? '',
      autorNombre: nombre,
      promedioEstrellas: estrellasValidas.toDouble(),
      totalVotos: estrellasValidas > 0 ? 1 : 0,
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
    );
  }

  ForoRespuesta copyWith({
    double? promedioEstrellas,
    int? totalVotos,
    int? userVote,
  }) {
    return ForoRespuesta(
      id: id,
      idPregunta: idPregunta,
      contenido: contenido,
      autorNombre: autorNombre,
      promedioEstrellas: promedioEstrellas ?? this.promedioEstrellas,
      totalVotos: totalVotos ?? this.totalVotos,
      tiempo: tiempo,
      userVote: userVote ?? this.userVote,
    );
  }
}

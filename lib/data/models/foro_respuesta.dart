class ForoRespuesta {
  final int id;
  final int idPregunta;
  final String contenido;
  final String autorNombre;
  final double promedioEstrellas; // Promedio de 1.0 a 5.0
  final int totalVotos; // Cuántas personas han votado
  final DateTime tiempo;
  final int userVote; // Del 1 al 5 (estrellas dadas por este usuario), 0 = sin voto

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
    // Extraer el nombre del autor
    String nombre = 'Anónimo';
    if (json['usuarios'] != null && json['usuarios'] is Map) {
      nombre = json['usuarios']['nombre'] ?? 'Anónimo';
      if (json['usuarios']['apellido'] != null) {
        nombre += ' ${json['usuarios']['apellido']}';
      }
    }

    // --- NUEVA LÓGICA DE ESTRELLAS ---
    // Calculamos el promedio desde la base de datos
    double promedio = 0.0;
    int total = 0;

    if (json['calificacion_respuestas'] != null && json['calificacion_respuestas'] is List) {
      final calificaciones = json['calificacion_respuestas'] as List;
      total = calificaciones.length;
      if (total > 0) {
        final suma = calificaciones.fold<int>(0, (sum, item) => sum + (item['estrellas'] as int));
        promedio = suma / total;
      }
    }

    return ForoRespuesta(
      id: json['id_respuesta'] ?? 0,
      idPregunta: json['id_publicacion'] ?? 0,
      contenido: json['contenido'] ?? '',
      autorNombre: nombre,
      promedioEstrellas: promedio,
      totalVotos: total,
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
class ForoPregunta {
  final int id;
  final String titulo;
  final String descripcion;
  final String autorNombre;
  final int votos;
  final int respuestasCount;
  final DateTime tiempo;

  ForoPregunta({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.autorNombre,
    required this.votos,
    required this.respuestasCount,
    required this.tiempo,
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

    return ForoPregunta(
      id: json['id_publicacion'] ?? 0,
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'] ?? '',
      autorNombre: nombre,
      votos: json['puntuacion'] ?? 0,
      respuestasCount:
          json['respuestas_count'] ??
          0, // This might need a view to get actual count, defaults to 0
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
    );
  }

  ForoPregunta copyWith({int? votos, int? respuestasCount}) {
    return ForoPregunta(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: votos ?? this.votos,
      respuestasCount: respuestasCount ?? this.respuestasCount,
      tiempo: tiempo,
    );
  }
}

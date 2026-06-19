class ForoPregunta {
  final int id;
  final String titulo;
  final String descripcion;
  final String autorNombre;
  final int votos;
  final int puntosBase;
  final int respuestasCount;
  final DateTime tiempo;
  final int userVote; // 1 = upvote, -1 = downvote, 0 = sin voto
  final String estado; // 🚨 1. NUEVA VARIABLE PARA LA HU-15

  ForoPregunta({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.autorNombre,
    required this.votos,
    required this.puntosBase,
    required this.respuestasCount,
    required this.tiempo,
    this.userVote = 0,
    required this.estado, // 🚨 2. REQUERIDO EN EL CONSTRUCTOR
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
      votos: (json['votos_foro'] as int?) ?? 0,
      puntosBase: ((json['puntuacion'] as int?) ?? 0).clamp(0, 999999),
      respuestasCount: respCount, // Obtener recuento real de base de datos
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
      // 🚨 3. MAPEAMOS EL ESTADO REAL QUE VIENE DE LA TABLA 'publicaciones' EN SUPABASE
      estado: json['estado'] ?? 'activo', 
    );
  }

  ForoPregunta copyWith({
    int? votos,
    int? puntosBase,
    int? respuestasCount,
    int? userVote,
    String? estado, // 🚨 4. PERMITIR MODIFICAR EL ESTADO EN COPIAS
  }) {
    return ForoPregunta(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: votos ?? this.votos,
      puntosBase: puntosBase ?? this.puntosBase,
      respuestasCount: respuestasCount ?? this.respuestasCount,
      tiempo: tiempo,
      userVote: userVote ?? this.userVote,
      estado: estado ?? this.estado, // 🚨 ASIGNACIÓN AQUÍ
    );
  }
}
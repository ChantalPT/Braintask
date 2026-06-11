class Publicacion {
  final int id;
  final String titulo;
  final String? descripcion;
  final String estado;
  final String tipo;
  final DateTime tiempo;
  final String? nombreMateria;
  final String? nombreFacultad;
  final double? promedioDificultad;
  final int puntuacion;
  final String? autorId;

  bool get estaResuelta => estado == 'resuelto' || estado == 'pagado';

  Publicacion({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.estado,
    required this.tipo,
    required this.tiempo,
    this.nombreMateria,
    this.nombreFacultad,
    this.promedioDificultad,
    this.puntuacion = 0,
    this.autorId,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    final materias = json['materias'];
    final facultades = materias != null ? materias['facultades'] : null;

    return Publicacion(
      id: json['id_publicacion'],
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'pendiente',
      tipo: json['tipo'] ?? 'otro',
      tiempo: json['tiempo'] != null
          ? DateTime.parse(json['tiempo'])
          : DateTime.now(),
      nombreMateria: materias != null ? materias['nombre_materias'] : null,
      nombreFacultad: facultades != null ? facultades['nombre_facultad'] : null,
      puntuacion: json['puntuacion'] ?? 0,
      autorId: json['autor_id'],
    );
  }

  Publicacion copyWith({double? promedioDificultad}) {
    return Publicacion(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      estado: estado,
      tipo: tipo,
      tiempo: tiempo,
      nombreMateria: nombreMateria,
      nombreFacultad: nombreFacultad,
      promedioDificultad: promedioDificultad ?? this.promedioDificultad,
      puntuacion: puntuacion,
      autorId: autorId,
    );
  }
}

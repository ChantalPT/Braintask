class Comentario {
  final int idComentario;
  final int publicacionId;
  final int usuarioCedula;
  final String contenido;
  final int votos;
  final DateTime fechaCreacion;

  // Datos relacionales del usuario (cargados con join)
  final String? nombreUsuario;
  final String? apellidoUsuario;

  Comentario({
    required this.idComentario,
    required this.publicacionId,
    required this.usuarioCedula,
    required this.contenido,
    this.votos = 0,
    required this.fechaCreacion,
    this.nombreUsuario,
    this.apellidoUsuario,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    final usuarios = json['usuarios'] as Map<String, dynamic>?;
    return Comentario(
      idComentario: json['id_comentario'],
      publicacionId: json['publicacion_id'],
      usuarioCedula: json['usuario_cedula'],
      contenido: json['contenido'] ?? '',
      votos: json['votos'] ?? 0,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      nombreUsuario: usuarios?['nombre'],
      apellidoUsuario: usuarios?['apellido'],
    );
  }

  Map<String, dynamic> toJson() => {
    'publicacion_id': publicacionId,
    'usuario_cedula': usuarioCedula,
    'contenido': contenido,
    'votos': votos,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };

  String get nombreCompleto {
    final nombre = nombreUsuario ?? '';
    final apellido = apellidoUsuario ?? '';
    final completo = '$nombre $apellido'.trim();
    return completo.isEmpty ? 'Usuario desconocido' : completo;
  }
}

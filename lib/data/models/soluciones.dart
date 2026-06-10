class Solucion {
  final int idSolucion;
  final int idPublicacion;
  final String usuarioId;
  final String? archivoUrl;
  final String? comentarioSolucion;
  final DateTime fechaSubida;
  final bool aceptada;

  // Datos relacionales del usuario (cargados con join)
  final String? nombreUsuario;
  final String? apellidoUsuario;

  Solucion({
    required this.idSolucion,
    required this.idPublicacion,
    required this.usuarioId,
    this.archivoUrl,
    this.comentarioSolucion,
    required this.fechaSubida,
    this.aceptada = false,
    this.nombreUsuario,
    this.apellidoUsuario,
  });

  factory Solucion.fromJson(Map<String, dynamic> json) {
    final usuarios = json['usuarios'] as Map<String, dynamic>?;
    return Solucion(
      idSolucion: json['id_solucion'],
      idPublicacion: json['id_publicacion'],
      usuarioId: json['usuario_id'] ?? '',
      archivoUrl: json['archivo_url'],
      comentarioSolucion: json['comentario_solucion'],
      fechaSubida: DateTime.parse(json['fecha_subida']),
      aceptada: json['aceptada'] ?? false,
      nombreUsuario: usuarios?['nombre'],
      apellidoUsuario: usuarios?['apellido'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id_publicacion': idPublicacion,
    'usuario_id': usuarioId,
    'archivo_url': archivoUrl,
    'comentario_solucion': comentarioSolucion,
    'fecha_subida': fechaSubida.toIso8601String(),
    'aceptada': aceptada,
  };

  String get nombreCompleto {
    final nombre = nombreUsuario ?? '';
    final apellido = apellidoUsuario ?? '';
    final completo = '$nombre $apellido'.trim();
    return completo.isEmpty ? 'Usuario desconocido' : completo;
  }
}

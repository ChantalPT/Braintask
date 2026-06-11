class Solucion {
  final int idSolucion;
  final int idPublicacion;
  final int? cedulaUsuarioSolver;
  final String? usuarioId; // uuid, solo para auth checks
  final String? archivoUrl;
  final String? comentarioSolucion;
  final DateTime fechaSubida;
  final bool aceptada;

  // Datos relacionales del usuario (cargados con join via cedula_usuario_solver)
  final String? nombreUsuario;
  final String? apellidoUsuario;

  Solucion({
    required this.idSolucion,
    required this.idPublicacion,
    this.cedulaUsuarioSolver,
    this.usuarioId,
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
      cedulaUsuarioSolver: json['cedula_usuario_solver'] is int
          ? json['cedula_usuario_solver'] as int
          : int.tryParse(json['cedula_usuario_solver']?.toString() ?? ''),
      usuarioId: json['usuario_id']?.toString(),
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
    'cedula_usuario_solver': cedulaUsuarioSolver,
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

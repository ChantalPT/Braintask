class Solucion {
  final int idSolucion;
  final int idPublicacion;
  final String cedulaUsuarioSolver;
  final String? archivoUrl;
  final String? comentarioSolucion;
  final DateTime fechaSubida;

  Solucion({
    required this.idSolucion,
    required this.idPublicacion,
    required this.cedulaUsuarioSolver,
    this.archivoUrl,
    this.comentarioSolucion,
    required this.fechaSubida,
  });

  factory Solucion.fromJson(Map<String, dynamic> json) => Solucion(
        idSolucion: json['id_solucion'],
        idPublicacion: json['id_publicacion'],
        cedulaUsuarioSolver: json['usuario_id'] ?? '',
        archivoUrl: json['archivo_url'],
        comentarioSolucion: json['comentario_solucion'],
        fechaSubida: DateTime.parse(json['fecha_subida']),
      );

  Map<String, dynamic> toJson() => {
        'id_publicacion': idPublicacion,
        'usuario_id': cedulaUsuarioSolver,
        'archivo_url': archivoUrl,
        'comentario_solucion': comentarioSolucion,
        'fecha_subida': fechaSubida.toIso8601String(),
      };
}
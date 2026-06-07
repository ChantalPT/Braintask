class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String carnet;
  final int? carreraId;
  final int puntuacion;
  final double reputacionPromedio;
  final int totalCalificaciones;
  final String? authUserId;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
    this.carreraId,
    this.puntuacion = 0,
    this.reputacionPromedio = 0.0,
    this.totalCalificaciones = 0,
    this.authUserId,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
      carnet: json['carnet']?.toString() ?? '',
      carreraId: json['carrera_id'] is int
          ? json['carrera_id'] as int
          : int.tryParse(json['carrera_id']?.toString() ?? ''),
      puntuacion: json['puntuacion'] ?? 0,
      reputacionPromedio:
          (json['reputacion_promedio'] as num?)?.toDouble() ?? 0.0,
      totalCalificaciones: json['total_calificaciones'] as int? ?? 0,
      authUserId: json['auth_user_id']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'carnet': carnet,
      'carrera_id': carreraId,
      'puntuacion': puntuacion,
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? apellido,
    String? cedula,
    String? carnet,
    int? carreraId,
    int? puntuacion,
    double? reputacionPromedio,
    int? totalCalificaciones,
    String? authUserId,
  }) {
    return UsuarioModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      carnet: carnet ?? this.carnet,
      carreraId: carreraId ?? this.carreraId,
      puntuacion: puntuacion ?? this.puntuacion,
      reputacionPromedio: reputacionPromedio ?? this.reputacionPromedio,
      totalCalificaciones: totalCalificaciones ?? this.totalCalificaciones,
      authUserId: authUserId ?? this.authUserId,
    );
  }
}

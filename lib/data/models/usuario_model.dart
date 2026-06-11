class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String carnet;
  final int? carreraId;
  final int puntuacion;
  final int reputacion;  // ← NUEVO: reputación del usuario

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
    this.carreraId,
    this.puntuacion = 0,
    this.reputacion = 0,
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
      reputacion: json['reputacion'] ?? 0,
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
      'reputacion': reputacion,
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? apellido,
    String? cedula,
    String? carnet,
    int? carreraId,
    int? puntuacion,
    int? reputacion,
  }) {
    return UsuarioModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      carnet: carnet ?? this.carnet,
      carreraId: carreraId ?? this.carreraId,
      puntuacion: puntuacion ?? this.puntuacion,
      reputacion: reputacion ?? this.reputacion,
    );
  }
}
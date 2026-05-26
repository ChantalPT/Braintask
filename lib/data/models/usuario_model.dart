class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String carnet;
  final int? carreraId;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.carnet,
    this.carreraId,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
      carnet: json['carnet']?.toString() ?? '',
      carreraId: json['carrera_id'] is int ? json['carrera_id'] as int : int.tryParse(json['carrera_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'carnet': carnet,
      'carrera_id': carreraId,
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? apellido,
    String? cedula,
    String? carnet,
    int? carreraId,
  }) {
    return UsuarioModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      carnet: carnet ?? this.carnet,
      carreraId: carreraId ?? this.carreraId,
    );
  }
}

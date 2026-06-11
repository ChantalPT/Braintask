class PagoModel {
  final int idPago;
  final int idPublicacion;
  final int idSolucion;
  final String usuarioPagadorId;
  final String usuarioReceptorId;
  final int monto;
  final DateTime fechaPago;
  final DateTime createdAt;

  PagoModel({
    required this.idPago,
    required this.idPublicacion,
    required this.idSolucion,
    required this.usuarioPagadorId,
    required this.usuarioReceptorId,
    required this.monto,
    required this.fechaPago,
    required this.createdAt,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      idPago: json['id_pago'],
      idPublicacion: json['id_publicacion'],
      idSolucion: json['id_solucion'],
      usuarioPagadorId: json['usuario_pagador_id'],
      usuarioReceptorId: json['usuario_receptor_id'],
      monto: json['monto'],
      fechaPago: DateTime.parse(json['fecha_pago']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 
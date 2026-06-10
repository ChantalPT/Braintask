class PagoModel {
  final int idPago;
  final int idPublicacion;
  final String idPagador;
  final String idReceptor;
  final int monto;
  final DateTime fecha;
  final String estado;

  PagoModel({
    required this.idPago,
    required this.idPublicacion,
    required this.idPagador,
    required this.idReceptor,
    required this.monto,
    required this.fecha,
    required this.estado,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) => PagoModel(
    idPago: json['id_pago'],
    idPublicacion: json['id_publicacion'],
    idPagador: json['id_pagador'],
    idReceptor: json['id_receptor'],
    monto: json['monto'],
    fecha: DateTime.parse(json['fecha']),
    estado: json['estado'] ?? 'completado',
  );

  Map<String, dynamic> toJson() => {
    'id_publicacion': idPublicacion,
    'id_pagador': idPagador,
    'id_receptor': idReceptor,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'estado': estado,
  };
}

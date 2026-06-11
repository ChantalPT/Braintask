class PagoModel {
  final int idPago;
  final int idPublicacion;
  final String usuarioPagadorId; // antes idPagador
  final String usuarioReceptorId; // antes idReceptor
  final int monto;
  final DateTime fechaPago; // antes fecha
  final String estado;

  PagoModel({
    required this.idPago,
    required this.idPublicacion,
    required this.usuarioPagadorId,
    required this.usuarioReceptorId,
    required this.monto,
    required this.fechaPago,
    required this.estado,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    // Manejar posibles nulos (aunque estas columnas deberían ser NOT NULL)
    return PagoModel(
      idPago: json['id_pago'] as int,
      idPublicacion: json['id_publicacion'] as int,
      usuarioPagadorId: json['usuario_pagador_id'] as String? ?? '',
      usuarioReceptorId: json['usuario_receptor_id'] as String? ?? '',
      monto: json['monto'] as int,
      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'])
          : DateTime.now(),
      estado: json['estado'] as String? ?? 'completado',
    );
  }

  Map<String, dynamic> toJson() => {
    'id_publicacion': idPublicacion,
    'usuario_pagador_id': usuarioPagadorId,
    'usuario_receptor_id': usuarioReceptorId,
    'monto': monto,
    'fecha_pago': fechaPago.toIso8601String(),
    'estado': estado,
  };
}

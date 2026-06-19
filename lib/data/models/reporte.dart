class Reporte {
  final int? idReporte;
  final String? idDenunciante;       
  final String idUsuarioReportado;   
  final String tipoReporte;          
  final int idObjetoReportado;       
  final String motivo;               
  final String? detalles;
  final DateTime? fechaReporte;

  Reporte({
    this.idReporte,
    this.idDenunciante,
    required this.idUsuarioReportado,
    required this.tipoReporte,
    required this.idObjetoReportado,
    required this.motivo,
    this.detalles,
    this.fechaReporte,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      idReporte: json['id_reporte'],
      idDenunciante: json['id_denunciante'],
      idUsuarioReportado: json['id_usuario_reportado'] ?? '',
      tipoReporte: json['tipo_reporte'] ?? '',
      idObjetoReportado: json['id_objeto_reportado'] ?? 0,
      motivo: json['motivo'] ?? '',
      detalles: json['detalles'],
      fechaReporte: json['fecha_reporte'] != null
          ? DateTime.parse(json['fecha_reporte'])
          : null,
    );
  }

  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id_usuario_reportado': idUsuarioReportado,
      'tipo_reporte': tipoReporte,
      'id_objeto_reportado': idObjetoReportado,
      'motivo': motivo,
      'detalles': detalles,
    };
    

    if (idDenunciante != null) {
      data['id_denunciante'] = idDenunciante;
    }
    
    return data;
  }
} 
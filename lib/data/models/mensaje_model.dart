class MensajeModel {
  final String id;
  final int remitenteCedula;
  final int destinatarioCedula;
  final String contenido;
  final bool leido;
  final DateTime? createdAt;

  MensajeModel({
    required this.id,
    required this.remitenteCedula,
    required this.destinatarioCedula,
    required this.contenido,
    required this.leido,
    this.createdAt,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id']?.toString() ?? '',
      remitenteCedula: (json['remitente_cedula'] as num?)?.toInt() ?? 0,
      destinatarioCedula:
          (json['destinatario_cedula'] as num?)?.toInt() ?? 0,
      contenido: json['contenido']?.toString() ?? '',
      leido: json['leido'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

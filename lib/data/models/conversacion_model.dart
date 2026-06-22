class ConversacionModel {
  final String otroUserId;
  final int otroCedula;
  final String otroNombre;
  final String otroApellido;
  final String? ultimoMensaje;
  final DateTime? ultimaFecha;
  final int mensajesNoLeidos;
  final bool ultimoEsMio;

  ConversacionModel({
    required this.otroUserId,
    required this.otroCedula,
    required this.otroNombre,
    required this.otroApellido,
    this.ultimoMensaje,
    this.ultimaFecha,
    this.mensajesNoLeidos = 0,
    this.ultimoEsMio = false,
  });
}

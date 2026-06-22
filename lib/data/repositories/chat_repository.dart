import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensaje_model.dart';
import '../models/conversacion_model.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  // Resuelve auth_user_id (UUID) → cedula (int)
  Future<int?> getCedula(String authUserId) async {
    final data = await _supabase
        .from('usuarios')
        .select('cedula')
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    return (data?['cedula'] as num?)?.toInt();
  }

  Future<List<MensajeModel>> fetchMensajes(
      int miCedula, int otraCedula) async {
    final data = await _supabase
        .from('mensajes')
        .select()
        .or(
          'and(remitente_cedula.eq.$miCedula,destinatario_cedula.eq.$otraCedula),'
          'and(remitente_cedula.eq.$otraCedula,destinatario_cedula.eq.$miCedula)',
        )
        .order('created_at', ascending: true);
    return (data as List)
        .map((e) => MensajeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> enviarMensaje({
    required int remitenteCedula,
    required int destinatarioCedula,
    required String contenido,
    required String emisorNombre,
  }) async {
    await _supabase.from('mensajes').insert({
      'remitente_cedula': remitenteCedula,
      'destinatario_cedula': destinatarioCedula,
      'contenido': contenido,
      'leido': false,
    });

    // Notificar al receptor vía tabla notificaciones (usando su auth_user_id)
    final receptorData = await _supabase
        .from('usuarios')
        .select('auth_user_id')
        .eq('cedula', destinatarioCedula)
        .maybeSingle();
    final receptorAuthId = receptorData?['auth_user_id']?.toString();
    if (receptorAuthId != null) {
      await _supabase.from('notificaciones').insert({
        'usuario_id': receptorAuthId,
        'mensaje': 'Nuevo mensaje de $emisorNombre',
        'tipo': 'nuevo_mensaje',
        'leida': false,
      });
    }
  }

  Future<void> marcarLeidos(int remitenteCedula, int destinatarioCedula) async {
    await _supabase
        .from('mensajes')
        .update({'leido': true})
        .eq('remitente_cedula', remitenteCedula)
        .eq('destinatario_cedula', destinatarioCedula)
        .eq('leido', false);
  }

  Future<List<ConversacionModel>> fetchConversaciones(int miCedula) async {
    final data = await _supabase
        .from('mensajes')
        .select()
        .or(
          'remitente_cedula.eq.$miCedula,destinatario_cedula.eq.$miCedula',
        )
        .order('created_at', ascending: false);

    final Map<int, Map<String, dynamic>> ultimoPor = {};
    final Map<int, int> noLeidos = {};

    for (final row in data as List) {
      final m = row as Map<String, dynamic>;
      final remCed = (m['remitente_cedula'] as num).toInt();
      final desCed = (m['destinatario_cedula'] as num).toInt();
      final otraCedula = remCed == miCedula ? desCed : remCed;

      if (!ultimoPor.containsKey(otraCedula)) {
        ultimoPor[otraCedula] = m;
      }
      if (remCed != miCedula && m['leido'] == false) {
        noLeidos[otraCedula] = (noLeidos[otraCedula] ?? 0) + 1;
      }
    }

    final List<ConversacionModel> result = [];
    for (final entry in ultimoPor.entries) {
      final otraCedula = entry.key;
      final userData = await _supabase
          .from('usuarios')
          .select('nombre, apellido, auth_user_id')
          .eq('cedula', otraCedula)
          .maybeSingle();

      final remCed =
          (entry.value['remitente_cedula'] as num).toInt();

      result.add(ConversacionModel(
        otroUserId: userData?['auth_user_id']?.toString() ?? '',
        otroCedula: otraCedula,
        otroNombre: userData?['nombre']?.toString() ?? 'Usuario',
        otroApellido: userData?['apellido']?.toString() ?? '',
        ultimoMensaje: entry.value['contenido']?.toString(),
        ultimaFecha: entry.value['created_at'] != null
            ? DateTime.tryParse(entry.value['created_at'].toString())
            : null,
        mensajesNoLeidos: noLeidos[otraCedula] ?? 0,
        ultimoEsMio: remCed == miCedula,
      ));
    }
    return result;
  }
}

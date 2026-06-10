import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pago_model.dart';

class PagoRepository {
  final SupabaseClient _supabase;

  PagoRepository(this._supabase);

  /// Procesa el pago de la recompensa al confirmar una solución aceptada.
  /// Debita al pagador, acredita al receptor y registra la transacción.
  Future<PagoModel> procesarPago({
    required int idPublicacion,
    required String idReceptor,
    required int monto,
  }) async {
    final idPagador = _supabase.auth.currentUser?.id;
    if (idPagador == null) {
      throw Exception('Debes iniciar sesión para procesar el pago.');
    }

    // 1. Registrar la transacción en la tabla pagos
    final pagoData = await _supabase
        .from('pagos')
        .insert({
          'id_publicacion': idPublicacion,
          'id_pagador': idPagador,
          'id_receptor': idReceptor,
          'monto': monto,
          'fecha': DateTime.now().toIso8601String(),
          'estado': 'completado',
        })
        .select()
        .single();

    // 2. Debitar puntuacion del pagador (estudiante)
    final pagadorData = await _supabase
        .from('usuarios')
        .select('puntuacion')
        .eq('auth_user_id', idPagador)
        .single();
    final nuevoPuntuacionPagador =
        ((pagadorData['puntuacion'] as int? ?? 0) - monto).clamp(0, 999999);
    await _supabase
        .from('usuarios')
        .update({'puntuacion': nuevoPuntuacionPagador})
        .eq('auth_user_id', idPagador);

    // 3. Acreditar puntuacion al receptor (quien resolvió)
    final receptorData = await _supabase
        .from('usuarios')
        .select('puntuacion')
        .eq('auth_user_id', idReceptor)
        .single();
    final nuevoPuntuacionReceptor =
        (receptorData['puntuacion'] as int? ?? 0) + monto;
    await _supabase
        .from('usuarios')
        .update({'puntuacion': nuevoPuntuacionReceptor})
        .eq('auth_user_id', idReceptor);

    // 4. Marcar publicación como 'pagado'
    await _supabase
        .from('publicaciones')
        .update({'estado': 'pagado'})
        .eq('id_publicacion', idPublicacion);

    return PagoModel.fromJson(pagoData);
  }

  Future<PagoModel?> getPagoPorPublicacion(int idPublicacion) async {
    final data = await _supabase
        .from('pagos')
        .select()
        .eq('id_publicacion', idPublicacion)
        .maybeSingle();
    return data != null ? PagoModel.fromJson(data) : null;
  }
}

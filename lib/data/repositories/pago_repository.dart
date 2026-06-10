import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pago_model.dart';

class PagoRepository {
  final SupabaseClient _supabase;

  PagoRepository(this._supabase);

  /// Otorga puntos al solver (sin debitar al autor)
  /// Registra la transacción y actualiza la puntuación del usuario.
  Future<PagoModel> otorgarPuntos({
    required int idPublicacion,
    required String idReceptor,
    required int monto,
  }) async {
    final idPagador = _supabase.auth.currentUser?.id;
    if (idPagador == null) {
      throw Exception('Debes iniciar sesión para otorgar puntos.');
    }

    // 1. Registrar la transacción en la tabla pagos (sin debitar, solo acreditación)
    final pagoData = await _supabase
        .from('pagos')
        .insert({
          'id_publicacion': idPublicacion,
          'id_pagador': idPagador, // quien otorga (el autor)
          'id_receptor': idReceptor,
          'monto': monto,
          'fecha': DateTime.now().toIso8601String(),
          'estado': 'completado',
        })
        .select()
        .single();

    // 2. Acreditar puntuacion al receptor (quien resolvió)
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

    // NOTA: No debitar al pagador (autor)

    return PagoModel.fromJson(pagoData);
  }

  // Método original (ya no se usa, pero lo dejamos por compatibilidad)
  Future<PagoModel> procesarPago({
    required int idPublicacion,
    required String idReceptor,
    required int monto,
  }) async {
    // Redirigimos al nuevo método
    return otorgarPuntos(
      idPublicacion: idPublicacion,
      idReceptor: idReceptor,
      monto: monto,
    );
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
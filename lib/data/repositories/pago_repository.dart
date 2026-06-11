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
    required int idSolucion,
  }) async {
    final idPagador = _supabase.auth.currentUser?.id;
    if (idPagador == null) {
      throw Exception('Debes iniciar sesión para otorgar puntos.');
    }
    if (idReceptor.isEmpty) {
      throw Exception('El id del receptor no puede estar vacío');
    }

    // 1. Registrar la transacción en la tabla pagos (sin debitar, solo acreditación)
    final Map<String, dynamic> datosPago = {
      'id_publicacion': idPublicacion,
      'usuario_pagador_id': idPagador,
      'usuario_receptor_id': idReceptor,
      'monto': monto,
      'estado': 'completado',
    };
    if (idSolucion != null) {
      datosPago['id_solucion'] = idSolucion;
    }
    // No enviamos 'fecha_pago' ni 'created_at' para que la BD use el valor por defecto (now())

    final pagoData = await _supabase
        .from('pagos')
        .insert(datosPago)
        .select()
        .single();

    // Acreditar puntos al receptor
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

    return PagoModel.fromJson(pagoData);
  }

  // Método de compatibilidad (si se usa en algún lado)
  Future<PagoModel> procesarPago({
    required int idPublicacion,
    required String idReceptor,
    required int monto,
    required int idSolucion,
  }) async {
    return otorgarPuntos(
      idPublicacion: idPublicacion,
      idReceptor: idReceptor,
      monto: monto,
      idSolucion: idSolucion,
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

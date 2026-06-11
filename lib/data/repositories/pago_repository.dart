import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pago_model.dart';

class PagoRepository {
  final SupabaseClient _supabase;

  PagoRepository(this._supabase);

  Future<PagoModel> otorgarPuntos({
    required int idPublicacion,
    required int idSolucion,
    required String idReceptor,
    required int monto,
  }) async {
    final idPagador = _supabase.auth.currentUser?.id;
    if (idPagador == null) {
      throw Exception('Debes iniciar sesión para otorgar puntos.');
    }

    // 1. Insertar en la tabla pagos
    final now = DateTime.now().toIso8601String();
    final pagoData = await _supabase
        .from('pagos')
        .insert({
          'id_publicacion': idPublicacion,
          'id_solucion': idSolucion,
          'usuario_pagador_id': idPagador,
          'usuario_receptor_id': idReceptor,
          'monto': monto,
          'fecha_pago': now,
          'created_at': now,
        })
        .select()
        .single();

    // 2. Llamar a la función RPC para sumar puntos al receptor
    final response = await _supabase.rpc(
      'sumar_puntos_usuario',
      params: {
        'p_auth_user_id': idReceptor,
        'p_puntos': monto,
      },
    );

    print('✅ Puntos sumados vía RPC. Nuevos valores: $response');

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
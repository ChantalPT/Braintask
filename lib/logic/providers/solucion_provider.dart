import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/solucion_repository.dart';
import '../../data/models/soluciones.dart';   // ← Importa el modelo real
import 'usuario_provider.dart';

part 'solucion_provider.g.dart';

@riverpod
SolucionesRepository solucionesRepository(Ref ref) {   // ← Ref, no SolucionesRepositoryRef
  return SolucionesRepository(Supabase.instance.client);
}

@riverpod
class SolucionesNotifier extends _$SolucionesNotifier {
  @override
  FutureOr<List<Solucion>> build(int idPublicacion) async {
    final repo = ref.read(solucionesRepositoryProvider);
    return await repo.getSolucionesPorPublicacion(idPublicacion);
  }

  Future<void> agregarSolucion({
    required int idPublicacion,
    required String comentario,
    File? archivo,
  }) async {
    final usuario = await ref.read(usuarioProvider.future);
    final cedula = usuario.cedula;

    final priorState = state.value ?? [];
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final nuevaLocal = Solucion(
      idSolucion: tempId,
      idPublicacion: idPublicacion,
      cedulaUsuarioSolver: cedula,
      archivoUrl: null,
      comentarioSolucion: comentario,
      fechaSubida: DateTime.now(),
    );
    state = AsyncData([nuevaLocal, ...priorState]);

    try {
      final repo = ref.read(solucionesRepositoryProvider);
      await repo.subirSolucion(
        idPublicacion: idPublicacion,
        cedulaUsuario: cedula,
        comentario: comentario,
        archivo: archivo,
      );
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(priorState);
      rethrow;
    }
  }
}
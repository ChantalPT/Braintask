import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/solucion_repository.dart';
import '../../data/models/soluciones.dart';
import 'usuario_provider.dart';

part 'solucion_provider.g.dart';

@riverpod
SolucionesRepository solucionesRepository(Ref ref) {
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
    final cedulaInt = int.tryParse(usuario.cedula) ?? 0;
    final authId = usuario.authUserId ?? '';

    final priorState = state.value ?? [];
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final nuevaLocal = Solucion(
      idSolucion: tempId,
      idPublicacion: idPublicacion,
      cedulaUsuarioSolver: cedulaInt,
      usuarioId: authId,
      archivoUrl: null,
      comentarioSolucion: comentario,
      fechaSubida: DateTime.now(),
    );
    state = AsyncData([nuevaLocal, ...priorState]);

    try {
      final repo = ref.read(solucionesRepositoryProvider);
      await repo.subirSolucion(
        idPublicacion: idPublicacion,
        cedulaUsuarioSolver: cedulaInt,
        usuarioId: authId,
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

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/foro_respuesta.dart';
import '../../data/repositories/foro_repository.dart';
import 'foro_provider.dart';

part 'foro_respuestas_provider.g.dart';

@riverpod
class ForoRespuestas extends _$ForoRespuestas {
  @override
  FutureOr<List<ForoRespuesta>> build(int idPregunta) async {
    return ref.read(foroRepositoryProvider).getRespuestas(idPregunta);
  }

  Future<void> votar(int id, bool isUpvote) async {
    final repo = ref.read(foroRepositoryProvider);
    await repo.votarRespuesta(id, isUpvote);
    ref.invalidateSelf();
  }

  Future<void> responder(String contenido) async {
    if (contenido.trim().isEmpty) return;

    final repo = ref.read(foroRepositoryProvider);
    await repo.agregarRespuesta(idPregunta, contenido.trim());

    // Invalidamos para que recargue las respuestas
    ref.invalidateSelf();
  }
}

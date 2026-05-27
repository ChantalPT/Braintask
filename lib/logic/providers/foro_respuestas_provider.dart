import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/foro_respuesta.dart';
import 'foro_provider.dart';

part 'foro_respuestas_provider.g.dart';

@riverpod
class ForoRespuestas extends _$ForoRespuestas {
  @override
  FutureOr<List<ForoRespuesta>> build(int idPregunta) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await ref
        .read(foroRepositoryProvider)
        .getRespuestas(idPregunta);

    return data.map((r) {
      final savedVote = prefs.getInt('respuesta_vote_${r.id}') ?? 0;
      return r.copyWith(userVote: savedVote);
    }).toList();
  }

  Future<void> calificar(int id, int estrellas) async {
    final priorState = state.value;
    if (priorState == null) return;

    final respIndex = priorState.indexWhere((r) => r.id == id);
    if (respIndex == -1) return;

    final prefs = await SharedPreferences.getInstance();
    final previousVote = prefs.getInt('respuesta_vote_$id') ?? 0;
    await prefs.setInt('respuesta_vote_$id', estrellas);

    state = AsyncData(
      priorState.map((r) {
        if (r.id == id) {
          return r.copyWith(
            promedioEstrellas: estrellas.toDouble(),
            totalVotos: 1,
            userVote: estrellas,
          );
        }
        return r;
      }).toList(),
    );

    try {
      final repo = ref.read(foroRepositoryProvider);
      await repo.calificarRespuesta(id, estrellas);
    } catch (e) {
      if (previousVote == 0) {
        await prefs.remove('respuesta_vote_$id');
      } else {
        await prefs.setInt('respuesta_vote_$id', previousVote);
      }
      state = AsyncData(priorState);
      rethrow;
    }
  }

  Future<void> responder(int preguntaId, String contenido) async {
    final contenidoLimpio = contenido.trim();
    if (contenidoLimpio.isEmpty) return;

    final repo = ref.read(foroRepositoryProvider);
    await repo.agregarRespuesta(preguntaId, contenidoLimpio);

    ref.invalidateSelf();
    ref.invalidate(foroPreguntasProvider);
  }
}

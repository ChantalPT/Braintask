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

  Future<void> votar(int id, bool isUpvote) async {
    final priorState = state.value;
    if (priorState == null) return;

    final respIndex = priorState.indexWhere((r) => r.id == id);
    if (respIndex == -1) return;

    final resp = priorState[respIndex];

    final targetVote = isUpvote ? 1 : -1;
    if (resp.userVote == targetVote) return;

    int difference = targetVote;
    if (resp.userVote != 0) {
      difference = targetVote * 2;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('respuesta_vote_$id', targetVote);

    state = AsyncData(
      priorState.map((r) {
        if (r.id == id) {
          return r.copyWith(votos: r.votos + difference, userVote: targetVote);
        }
        return r;
      }).toList(),
    );

    try {
      final repo = ref.read(foroRepositoryProvider);
      if (resp.userVote != 0) {
        await repo.votarRespuesta(id, isUpvote);
        await repo.votarRespuesta(id, isUpvote);
      } else {
        await repo.votarRespuesta(id, isUpvote);
      }
    } catch (e) {
      await prefs.setInt('respuesta_vote_$id', resp.userVote);
      state = AsyncData(priorState);
      rethrow;
    }
  }

  Future<void> responder(int preguntaId, String contenido) async {
    if (contenido.trim().isEmpty) return;

    final repo = ref.read(foroRepositoryProvider);
    await repo.agregarRespuesta(preguntaId, contenido.trim());

    // Agregamos localmente al contador de la pregunta en la UI
    ref.read(foroPreguntasProvider.notifier).incrementAnswers(preguntaId);

    // Invalidamos para que recargue las respuestas
    ref.invalidateSelf();
  }
}

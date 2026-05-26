import 'dart:async';
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

  Future<void> calificar(int idRespuesta, int estrellas) async {

    if (estrellas < 1 || estrellas > 5) return;

    final priorState = state.value;
    if (priorState == null) return;

    final respIndex = priorState.indexWhere((r) => r.id == idRespuesta);
    if (respIndex == -1) return;

    final resp = priorState[respIndex];
    if (resp.userVote == estrellas) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('respuesta_vote_$idRespuesta', estrellas);

    state = AsyncData(
      priorState.map((r) {
        if (r.id == idRespuesta) {
          return r.copyWith(userVote: estrellas);
        }
        return r;
      }).toList(),
    );

    try {
      await ref.read(foroRepositoryProvider).calificarRespuesta(idRespuesta, estrellas);
      ref.invalidateSelf();
    } catch (e) {
      await prefs.setInt('respuesta_vote_$idRespuesta', resp.userVote);
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

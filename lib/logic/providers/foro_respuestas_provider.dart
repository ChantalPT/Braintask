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

  // --- NUEVA FUNCIÓN PARA VOTAR CON ESTRELLAS ---
  Future<void> calificar(int id, int estrellas) async {
    final priorState = state.value;
    if (priorState == null) return;

    final respIndex = priorState.indexWhere((r) => r.id == id);
    if (respIndex == -1) return;

    final resp = priorState[respIndex];

    // Si ya calificó esta respuesta, no hacemos nada
    if (resp.userVote != 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('respuesta_vote_$id', estrellas);

    // Recálculo matemático en vivo (Optimistic UI)
    final totalVotosNuevos = resp.totalVotos + 1;
    final nuevoPromedio = ((resp.promedioEstrellas * resp.totalVotos) + estrellas) / totalVotosNuevos;

    state = AsyncData(
      priorState.map((r) {
        if (r.id == id) {
          return r.copyWith(
            promedioEstrellas: nuevoPromedio,
            totalVotos: totalVotosNuevos,
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
      // Rollback si la BD falla
      await prefs.remove('respuesta_vote_$id');
      state = AsyncData(priorState);
      rethrow;
    }
  }

  Future<void> responder(int preguntaId, String contenido) async {
    if (contenido.trim().isEmpty) return;

    final repo = ref.read(foroRepositoryProvider);
    await repo.agregarRespuesta(preguntaId, contenido);
    
    // Invalida para recargar de la BD
    ref.invalidateSelf();
    
    // Invalida el contador de preguntas en el foro principal
    ref.invalidate(foroPreguntasProvider);
  }
}
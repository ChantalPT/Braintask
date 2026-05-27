import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/foro_pregunta.dart';
import '../../data/repositories/foro_repository.dart';

part 'foro_provider.g.dart';

// Provide the repository
@riverpod
ForoRepository foroRepository(Ref ref) {
  return ForoRepository(Supabase.instance.client);
}

// Controller for the list of questions on the forum
@riverpod
class ForoPreguntas extends _$ForoPreguntas {
  String _searchQuery = '';

  @override
  FutureOr<List<ForoPregunta>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final data = await ref
        .read(foroRepositoryProvider)
        .getPreguntas(search: _searchQuery);

    return data.map((p) {
      final savedVote = prefs.getInt('pregunta_vote_${p.id}') ?? 0;
      return p.copyWith(userVote: savedVote);
    }).toList();
  }

  void search(String query) {
    _searchQuery = query;
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  Future<void> votar(int id, bool isUpvote) async {
    final priorState = state.value;
    if (priorState == null) return;

    final pubIndex = priorState.indexWhere((p) => p.id == id);
    if (pubIndex == -1) return;

    final pub = priorState[pubIndex];

    // Si ya le dio like a esto no hacer nada de nuevo (Para evitar SPAM)
    final targetVote = isUpvote ? 1 : -1;
    if (pub.userVote == targetVote) return;

    // Calculamos qué tanto debe cambiar el puntaje
    int difference = targetVote;
    if (pub.userVote != 0) {
      // Si cambia de dislike a like suma doble, etc
      difference = targetVote * 2;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pregunta_vote_$id', targetVote);

    state = AsyncData(
      priorState.map((p) {
        if (p.id == id) {
          return p.copyWith(votos: p.votos + difference, userVote: targetVote);
        }
        return p;
      }).toList(),
    );

    try {
      final repo = ref.read(foroRepositoryProvider);
      if (pub.userVote != 0) {
        await repo.votarPregunta(id, isUpvote);
        await repo.votarPregunta(id, isUpvote);
      } else {
        await repo.votarPregunta(id, isUpvote);
      }
    } catch (e) {
      // Rollback en caso de error
      await prefs.setInt('pregunta_vote_$id', pub.userVote);
      state = AsyncData(priorState);
      rethrow;
    }
  }

  void incrementAnswers(int id) {
    // Actualización del conteo al responder
    final priorState = state.value;
    if (priorState != null) {
      state = AsyncData(
        priorState.map((p) {
          if (p.id == id) {
            return p.copyWith(respuestasCount: p.respuestasCount + 1);
          }
          return p;
        }).toList(),
      );
    }
  }
}

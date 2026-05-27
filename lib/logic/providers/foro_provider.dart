import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/foro_pregunta.dart';
import '../../data/repositories/foro_repository.dart';

part 'foro_provider.g.dart';

@riverpod
ForoRepository foroRepository(Ref ref) {
  return ForoRepository(Supabase.instance.client);
}

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
    final targetVote = isUpvote ? 1 : -1;
    final nextVote = pub.userVote == targetVote ? 0 : targetVote;
    final difference = (nextVote - pub.userVote).clamp(-1, 1);

    final prefs = await SharedPreferences.getInstance();
    if (nextVote == 0) {
      await prefs.remove('pregunta_vote_$id');
    } else {
      await prefs.setInt('pregunta_vote_$id', nextVote);
    }

    state = AsyncData(
      priorState.map((p) {
        if (p.id == id) {
          return p.copyWith(
            votos: (p.votos + difference).clamp(0, 999999),
            userVote: nextVote,
          );
        }
        return p;
      }).toList(),
    );

    try {
      final repo = ref.read(foroRepositoryProvider);
      if (difference != 0) {
        await repo.ajustarVotoPregunta(id, difference);
      }
    } catch (e) {
      if (pub.userVote == 0) {
        await prefs.remove('pregunta_vote_$id');
      } else {
        await prefs.setInt('pregunta_vote_$id', pub.userVote);
      }
      state = AsyncData(priorState);
      rethrow;
    }
  }

  void incrementAnswers(int id) {
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

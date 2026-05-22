import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return ref.read(foroRepositoryProvider).getPreguntas(search: _searchQuery);
  }

  void search(String query) {
    _searchQuery = query;
    state = const AsyncLoading();
    ref.invalidateSelf();
  }

  Future<void> votar(int id, bool isUpvote) async {
    // Optimistic UI updates could go here
    final repo = ref.read(foroRepositoryProvider);
    await repo.votarPregunta(id, isUpvote);
    // Refresh
    ref.invalidateSelf();
  }
}

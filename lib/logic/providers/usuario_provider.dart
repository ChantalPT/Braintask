import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';

part 'usuario_provider.g.dart';

@riverpod
UsuarioRepository usuarioRepository(Ref ref) {
  return UsuarioRepository(Supabase.instance.client);
}

@riverpod
class UsuarioNotifier extends _$UsuarioNotifier {
  @override
  Future<UsuarioModel> build() async {
    return await ref.read(usuarioRepositoryProvider).obtenerPerfilActual();
  }

  Future<void> modificarPerfil({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carnet,
    int? carreraId,
  }) async {
    final priorState = state.value;
    if (priorState == null) return;

    final usuarioModificado = priorState.copyWith(
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      carnet: carnet,
      carreraId: carreraId,
    );

    state = AsyncData(usuarioModificado);

    try {
      await ref.read(usuarioRepositoryProvider).actualizarPerfil(usuarioModificado);
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(priorState);
      rethrow;
    }
  }
}
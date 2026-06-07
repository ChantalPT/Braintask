import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/usuario_model.dart';
import 'usuario_provider.dart';

part 'perfil_publico_provider.g.dart';

@riverpod
Future<UsuarioModel> perfilPublico(Ref ref, String authUserId) async {
  return ref.read(usuarioRepositoryProvider).obtenerPerfilPublico(authUserId);
}

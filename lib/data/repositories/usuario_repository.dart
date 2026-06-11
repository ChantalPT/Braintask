import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final SupabaseClient _supabase;

  UsuarioRepository(this._supabase);

  Future<UsuarioModel> obtenerPerfilActual() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay una sesión activa');

    final data = await _supabase
        .from('usuarios')
        .select()
        .eq('auth_user_id', user.id)
        .single();

    return UsuarioModel.fromJson(data);
  }

  Future<void> actualizarPerfil(UsuarioModel usuario) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay una sesión activa');

    await _supabase
        .from('usuarios')
        .update(usuario.toUpdateJson())
        .eq('auth_user_id', user.id);
  }

  Future<UsuarioModel> obtenerPerfilPublico(String authUserId) async {
    final data = await _supabase
        .from('usuarios')
        .select()
        .eq('auth_user_id', authUserId)
        .single();

    return UsuarioModel.fromJson(data);
  }

  Future<UsuarioModel> obtenerPerfilPorCedula(int cedula) async {
    final data = await _supabase
        .from('usuarios')
        .select()
        .eq('cedula', cedula)
        .single();

    return UsuarioModel.fromJson(data);
  }
}

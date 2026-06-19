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

    return await _agregarConteoReportes(data, user.id);
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

    return await _agregarConteoReportes(data, authUserId);
  }

  Future<UsuarioModel> obtenerPerfilPorCedula(int cedula) async {
    final data = await _supabase
        .from('usuarios')
        .select()
        .eq('cedula', cedula)
        .single();

    final authUserId = data['auth_user_id']?.toString();
    return await _agregarConteoReportes(data, authUserId);
  }

  
  Future<UsuarioModel> _agregarConteoReportes(Map<String, dynamic> data, String? authUserId) async {
    final mutableData = Map<String, dynamic>.from(data);
    
    if (authUserId == null || authUserId.isEmpty) {
      mutableData['total_reportes'] = 0;
      return UsuarioModel.fromJson(mutableData);
    }

    try {

      final reportes = await _supabase
          .from('reportes')
          .select('id_usuario_reportado') 
          .eq('id_usuario_reportado', authUserId);
          
      // La cantidad de elementos en la lista es el número de reportes
      mutableData['total_reportes'] = reportes.length;
    } catch (e) {
      // Si por alguna razón falla (ej. problemas de red), devolvemos 0 para no colgar la app
      mutableData['total_reportes'] = 0;
      print('Aviso: No se pudieron cargar los reportes - $e');
    }

    return UsuarioModel.fromJson(mutableData);
  }
}
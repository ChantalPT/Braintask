import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reporte.dart';

class ReporteRepository {
  final SupabaseClient _supabase;

  ReporteRepository(this._supabase);

  Future<void> registrarReporte(Reporte reporte) async {
    try {
      final idUserLogueado = _supabase.auth.currentUser?.id;
      
      if (idUserLogueado == null) {
        throw Exception('Debes iniciar sesión en la plataforma para poder reportar contenido.');
      }

      if (idUserLogueado == reporte.idUsuarioReportado) {
        throw Exception('Operación no permitida: No puedes reportar tu propio contenido.');
      }

      final jsonInsertar = reporte.toJson();
      jsonInsertar['id_denunciante'] = idUserLogueado;

      // Intentamos insertar el reporte en Supabase
      await _supabase.from('reportes').insert(jsonInsertar);
      
    } on PostgrestException catch (e) {
      // 🚨 CÓDIGO 23505: El usuario ya reportó esto (viola el UNIQUE de Supabase)
      if (e.code == '23505') {
        throw Exception('Ya has reportado este contenido anteriormente.');
      }
      // Cualquier otro error de Supabase
      throw Exception('Error en la base de datos: ${e.message}');
    } catch (e) {
      // Errores generales
      throw Exception('Error al procesar el reporte: $e');
    }
  }
}
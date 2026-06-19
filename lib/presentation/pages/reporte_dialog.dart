import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:braintask/data/models/reporte.dart'; 
import 'package:braintask/data/repositories/reporte_repository.dart';

class ReporteDialog {

  static void mostrar({
    required BuildContext context,
    required String idUsuarioReportado, 
    required String tipoReporte,        
    required int idObjetoReportado, 
    VoidCallback? onReporteEnviado,    
  }) {
    // Lista de motivos predefinidos válidos
    final List<String> motivos = [
      'Plagio / Copia',
      'Fraude / Trampa en examen o tarea',
      'Comportamiento Inadecuado u Ofensivo',
      'Contenido fuera de contexto académico'
    ];

    String motivoSeleccionado = motivos.first;
    final TextEditingController detallesController = TextEditingController();
    final ReporteRepository repository = ReporteRepository(Supabase.instance.client);

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Row(
                children: const [
                  Icon(Icons.report_problem, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Reportar Contenido'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ayúdanos a mantener un entorno seguro y ético. Selecciona el motivo de tu denuncia:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: motivoSeleccionado,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Motivo',
                      ),
                      items: motivos.map((String motivo) {
                        return DropdownMenuItem<String>(
                          value: motivo,
                          child: Text(motivo, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            motivoSeleccionado = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: detallesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Detalles adicionales (Opcional)',
                        hintText: 'Describe brevemente qué sucedió...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final nuevoReporte = Reporte(
                      idUsuarioReportado: idUsuarioReportado,
                      tipoReporte: tipoReporte,
                      idObjetoReportado: idObjetoReportado,
                      motivo: motivoSeleccionado,
                      detalles: detallesController.text.trim().isEmpty 
                          ? null 
                          : detallesController.text.trim(),
                    );

                    Navigator.pop(dialogContext);

                    try {
                      await repository.registrarReporte(nuevoReporte);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reporte enviado con éxito. Será revisado por administración.'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        
                        if (onReporteEnviado != null) {
                          onReporteEnviado();
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                      
                        final mensajeLimpio = e.toString().replaceAll('Exception: ', '');
                        final esDuplicado = mensajeLimpio.contains('anteriormente');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(mensajeLimpio),
                            backgroundColor: esDuplicado ? Colors.orange.shade800 : Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Enviar Reporte'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
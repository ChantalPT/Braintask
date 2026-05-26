import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as java_io;
import 'package:file_picker/file_picker.dart' as file_picker;

class DetallePublicacionPage extends StatefulWidget {
  final int publicacionId;
  const DetallePublicacionPage({super.key, required this.publicacionId});

  @override
  State<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends State<DetallePublicacionPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _publicacion;
  List<Map<String, dynamic>> _soluciones = [];
  bool _cargando = true;
  String? _error;

  // Variables para la solución del usuario
  final TextEditingController _solucionController = TextEditingController();
  java_io.File? _archivoSolucion;
  String? _nombreArchivoSolucion;
  bool _enviandoSolucion = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _solucionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      // 1. Cargar el detalle del ejercicio
      final pubData = await _supabase
          .from('publicaciones')
          .select('''
            *,
            materias (
              nombre_materias,
              facultades (nombre_facultad)
            )
          ''')
          .eq('id_publicacion', widget.publicacionId)
          .single();

      // 2. Cargar las soluciones con sus calificaciones (CORREGIDO A SINGULAR)
      final solData = await _supabase
          .from('soluciones')
          .select('''
            *,
            calificacion_soluciones (
              estrellas,
              usuario_id
            )
          ''')
          .eq('id_publicacion', widget.publicacionId)
          .order('id_solucion', ascending: false);

      setState(() {
        _publicacion = pubData;
        _soluciones = List<Map<String, dynamic>>.from(solData);
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _calificarSolucion(int idSolucion, int estrellas) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para calificar')),
      );
      return;
    }

    try {
      // Validar si el usuario ya votó por esta solución localmente en la lista
      final solucion = _soluciones.firstWhere((s) => s['id_solucion'] == idSolucion);
      final calificaciones = List<Map<String, dynamic>>.from(solucion['calificacion_soluciones'] ?? []);
      final yaVoto = calificaciones.any((c) => c['usuario_id'] == user.id);

      if (yaVoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has calificado esta solución')),
        );
        return;
      }

      // Insertar calificación en Supabase (CORREGIDO A SINGULAR)
      await _supabase.from('calificacion_soluciones').insert({
        'id_solucion': idSolucion,
        'usuario_id': user.id,
        'estrellas': estrellas,
      });

      // Recargar para actualizar los promedios
      await _cargarDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Calificación guardada!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al calificar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Lógica para enviar una nueva solución
  Future<void> _seleccionarArchivoSolucion() async {
    final resultado = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _archivoSolucion = java_io.File(resultado.files.single.path!);
        _nombreArchivoSolucion = resultado.files.single.name;
      });
    }
  }

  Future<void> _subirYEnviarSolucion() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_solucionController.text.trim().isEmpty && _archivoSolucion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe una explicación o adjunta un archivo.')),
      );
      return;
    }

    setState(() => _enviandoSolucion = true);
    String? urlArchivoSubido;

    try {
      if (_archivoSolucion != null) {
        final pathArchivo = 'soluciones/${DateTime.now().millisecondsSinceEpoch}_$_nombreArchivoSolucion';
        await _supabase.storage.from('publicaciones').upload(pathArchivo, _archivoSolucion!);
        urlArchivoSubido = _supabase.storage.from('publicaciones').getPublicUrl(pathArchivo);
      }

      await _supabase.from('soluciones').insert({
        'id_publicacion': widget.publicacionId,
        'usuario_id': user.id,
        'contenido': _solucionController.text.trim(),
        'archivo_url': urlArchivoSubido,
        'aceptada': false,
      });

      _solucionController.clear();
      setState(() {
        _archivoSolucion = null;
        _nombreArchivoSolucion = null;
      });

      await _cargarDatos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solución publicada!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _enviandoSolucion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _publicacion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _publicacion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_error ?? 'No se encontró la publicación')),
      );
    }

    final pub = _publicacion!;
    final titulo = pub['titulo'] ?? 'Sin título';
    final descripcion = pub['descripcion'] ?? 'Sin descripción';
    final puntosBase = pub['puntuacion'] ?? 0;
    final archivoPubUrl = pub['archivo_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalle del Ejercicio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TARJETA DEL ENUNCIADO (PUBLICACIÓN)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.orange, size: 18),
                        const SizedBox(width: 5),
                        Text('$puntosBase pts base', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text('Enunciado:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(descripcion, style: const TextStyle(fontSize: 15)),
                    if (archivoPubUrl != null) ...[
                      const SizedBox(height: 12),
                      _buildArchivoGrande(archivoPubUrl),
                    ]
                  ],
                ),
              ),
            ),

            // 2. FORMULARIO PARA SUBIR SOLUCIÓN
            _buildFormularioSolucion(),

            const SizedBox(height: 20),
            const Text('Soluciones Propuestas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),

            // 3. LISTA DE SOLUCIONES DINÁMICAS
            if (_soluciones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text('Sé el primero en resolver este ejercicio.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _soluciones.length,
                itemBuilder: (context, index) {
                  return _buildTarjetaSolucion(_soluciones[index], puntosBase);
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaSolucion(Map<String, dynamic> solucion, int puntosBase) {
    final contenido = solucion['contenido'] ?? '';
    final archivoUrl = solucion['archivo_url'];
    final idSolucion = solucion['id_solucion'];
    
    // Cálculo de la fórmula dinámica (CORREGIDO A SINGULAR)
    final calificaciones = List<Map<String, dynamic>>.from(solucion['calificacion_soluciones'] ?? []);
    double promedioEstrellas = 0.0;
    int puntosReales = 0;

    if (calificaciones.isNotEmpty) {
      final sumaVotos = calificaciones.fold<int>(0, (sum, item) => sum + (item['estrellas'] as int));
      promedioEstrellas = sumaVotos / calificaciones.length;
      puntosReales = (puntosBase * (promedioEstrellas / 5)).round(); // Fórmula aplicada
    }

    // Identificar si el usuario actual ya votó
    final currentUser = _supabase.auth.currentUser;
    int? votoUsuarioActual;
    if (currentUser != null && calificaciones.isNotEmpty) {
      try {
        final miVoto = calificaciones.firstWhere((c) => c['usuario_id'] == currentUser.id);
        votoUsuarioActual = miVoto['estrellas'];
      } catch (_) {} // No ha votado
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Solución de un Alumno', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: calificaciones.isEmpty ? Colors.grey.shade200 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    calificaciones.isEmpty ? 'Pendiente' : 'Gana $puntosReales pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                      color: calificaciones.isEmpty ? Colors.grey.shade700 : Colors.green.shade800
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            
            if (contenido.isNotEmpty) Text(contenido, style: const TextStyle(fontSize: 14)),
            if (archivoUrl != null) ...[
              const SizedBox(height: 10),
              _buildArchivoGrande(archivoUrl),
            ],
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  calificaciones.isEmpty 
                    ? '0 votos' 
                    : '${promedioEstrellas.toStringAsFixed(1)} ★ (${calificaciones.length} votos)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    final isFilled = (votoUsuarioActual != null && starValue <= votoUsuarioActual) || 
                                     (votoUsuarioActual == null && starValue <= promedioEstrellas.round());
                    return InkWell(
                      onTap: () => _calificarSolucion(idSolucion, starValue),
                      child: Icon(
                        isFilled ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      ),
                    );
                  }),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioSolucion() {
    final user = _supabase.auth.currentUser;
    final esMiPropioEjercicio = _publicacion != null && user != null && _publicacion!['autor_id'] == user.id;

    if (esMiPropioEjercicio) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Montar tu solución', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _enviandoSolucion ? null : _seleccionarArchivoSolucion,
                icon: const Icon(Icons.add_photo_alternate, size: 22),
                label: const Text('SELECCIONAR FOTO / PDF DE TU SOLUCIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            
            if (_nombreArchivoSolucion != null) ...[
              Text('Adjunto: $_nombreArchivoSolucion', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _solucionController,
              maxLines: 3,
              enabled: !_enviandoSolucion,
              decoration: InputDecoration(
                hintText: 'Explica tu resolución...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _enviandoSolucion ? null : _subirYEnviarSolucion,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF)),
                child: _enviandoSolucion 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENVIAR SOLUCIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoGrande(String url) {
    final extension = url.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red),
            SizedBox(width: 8),
            Text('Ver Archivo PDF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    }
  }
}
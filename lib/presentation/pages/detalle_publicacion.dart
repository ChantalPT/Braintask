import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:braintask/presentation/pages/detalle_foro_pregunta.dart';
import 'package:braintask/data/models/foro_pregunta.dart';

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
  bool _cargandoPublicacion = true;
  bool _cargandoSoluciones = true;
  String? _error;

  final TextEditingController _solucionController = TextEditingController();
  File? _archivoSolucion;
  String? _nombreArchivoSolucion;
  bool _enviandoSolucion = false;
  String? _cedulaUsuario;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _obtenerCedulaUsuario();
  }

  Future<void> _obtenerCedulaUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final data = await _supabase
          .from('usuarios')
          .select('cedula')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      if (data != null) {
        _cedulaUsuario = data['cedula']?.toString();
      }
    }
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargandoPublicacion = true;
      _cargandoSoluciones = true;
    });
    try {
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

      setState(() {
        _publicacion = pubData;
        _cargandoPublicacion = false;
      });

      await _recargarSoluciones();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargandoPublicacion = false;
        _cargandoSoluciones = false;
      });
    }
  }

  Future<void> _recargarSoluciones() async {
    debugPrint(
      "🔄 Recargando soluciones para publicación ${widget.publicacionId}...",
    );
    setState(() => _cargandoSoluciones = true);
    try {
      final solData = await _supabase
          .from('soluciones')
          .select('*')
          .eq('id_publicacion', widget.publicacionId)
          .order('fecha_subida', ascending: false);
      debugPrint("📦 Se obtuvieron ${solData.length} soluciones.");
      setState(() {
        _soluciones = List<Map<String, dynamic>>.from(solData);
        _cargandoSoluciones = false;
      });
    } catch (e) {
      debugPrint("❌ Error cargando soluciones: $e");
      setState(() => _cargandoSoluciones = false);
    }
  }

  Future<void> _seleccionarArchivoSolucion() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _archivoSolucion = File(resultado.files.single.path!);
        _nombreArchivoSolucion = resultado.files.single.name;
      });
    }
  }

  Future<void> _subirYEnviarSolucion() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_solucionController.text.trim().isEmpty && _archivoSolucion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una explicación o adjunta un archivo.'),
        ),
      );
      return;
    }

    if (_cedulaUsuario == null) {
      await _obtenerCedulaUsuario();
    }

    setState(() => _enviandoSolucion = true);
    String? urlArchivoSubido;

    try {
      if (_archivoSolucion != null) {
        final extension = _archivoSolucion!.path.split('.').last;
        final pathArchivo =
            'soluciones/${DateTime.now().millisecondsSinceEpoch}.$extension';
        await _supabase.storage
            .from('soluciones')
            .upload(pathArchivo, _archivoSolucion!);
        urlArchivoSubido = _supabase.storage
            .from('soluciones')
            .getPublicUrl(pathArchivo);
      }

      await _supabase.from('soluciones').insert({
        'id_publicacion': widget.publicacionId,
        'usuario_id': user.id,
        'cedula_usuario_solver': _cedulaUsuario ?? 'sin_cedula',
        'comentario_solucion': _solucionController.text.trim(),
        'archivo_url': urlArchivoSubido,
        'aceptada': false,
        'fecha_subida': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ Solución insertada correctamente.");

      _solucionController.clear();
      setState(() {
        _archivoSolucion = null;
        _nombreArchivoSolucion = null;
      });

      await Future.delayed(const Duration(milliseconds: 500), () async {
        await _recargarSoluciones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Solución publicada!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("❌ Error al enviar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoSolucion = false);
    }
  }

  void _abrirForo() {
    if (_publicacion == null) return;
    final titulo = _publicacion!['titulo'] ?? 'Sin título';
    final descripcion = _publicacion!['descripcion'] ?? 'Sin descripción';
    final autorNombre = _publicacion!['autor_nombre'] ?? 'Usuario';

    final puntosBase = (_publicacion!['puntuacion'] as int?) ?? 0;
    final votosForo = (_publicacion!['votos_foro'] as int?) ?? 0;

    final preguntaForo = ForoPregunta(
      id: widget.publicacionId,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: votosForo,
      puntosBase: puntosBase,
      respuestasCount: 0,
      tiempo: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleForoPreguntaPage(pregunta: preguntaForo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoPublicacion) {
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum, color: Colors.blue),
            onPressed: _abrirForo,
            tooltip: 'Foro de discusión',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () async {
              await _recargarSoluciones();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Recargado: ${_soluciones.length} soluciones',
                    ),
                  ),
                );
              }
            },
            tooltip: 'Recargar soluciones',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recargarSoluciones,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$puntosBase pts base',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Enunciado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(descripcion, style: const TextStyle(fontSize: 15)),
                      if (archivoPubUrl != null) ...[
                        const SizedBox(height: 12),
                        _buildArchivoGrande(archivoPubUrl),
                      ],
                    ],
                  ),
                ),
              ),
              _buildFormularioSolucion(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soluciones Propuestas (${_soluciones.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_cargandoSoluciones)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const Divider(),
              if (_cargandoSoluciones)
                const Center(child: CircularProgressIndicator())
              else if (_soluciones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Sé el primero en resolver este ejercicio.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _soluciones.length,
                  itemBuilder: (context, index) {
                    final sol = _soluciones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Solución',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (sol['aceptada'] == true)
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sol['aceptada'] == true
                                        ? 'Aceptada'
                                        : 'Pendiente',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: sol['aceptada'] == true
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if ((sol['comentario_solucion'] ?? '').isNotEmpty)
                              Text(
                                sol['comentario_solucion'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            if (sol['archivo_url'] != null) ...[
                              const SizedBox(height: 10),
                              _buildArchivoGrande(sol['archivo_url']),
                            ],
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Calificación: ${sol['calificacion'] ?? 'Sin calificar'}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioSolucion() {
    final user = _supabase.auth.currentUser;
    final esMiPropioEjercicio =
        _publicacion != null &&
        user != null &&
        _publicacion!['autor_id'] == user.id;
    if (esMiPropioEjercicio) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Montar tu solución',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _enviandoSolucion
                    ? null
                    : _seleccionarArchivoSolucion,
                icon: const Icon(Icons.add_photo_alternate, size: 22),
                label: const Text(
                  'SELECCIONAR FOTO / PDF DE TU SOLUCIÓN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_nombreArchivoSolucion != null) ...[
              Text(
                'Adjunto: $_nombreArchivoSolucion',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _solucionController,
              maxLines: 3,
              enabled: !_enviandoSolucion,
              decoration: InputDecoration(
                hintText: 'Explica tu resolución...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _enviandoSolucion ? null : _subirYEnviarSolucion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                ),
                child: _enviandoSolucion
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENVIAR SOLUCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Ver Archivo PDF',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
  }
}

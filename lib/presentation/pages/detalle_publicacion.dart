import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:braintask/presentation/pages/detalle_foro_pregunta.dart';
import 'package:braintask/data/models/foro_pregunta.dart';
import 'package:braintask/data/repositories/solucion_repository.dart';

class DetallePublicacionPage extends StatefulWidget {
  final int publicacionId;
  const DetallePublicacionPage({super.key, required this.publicacionId});

  @override
  State<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends State<DetallePublicacionPage> {
  final _supabase = Supabase.instance.client;
  late final SolucionesRepository _solucionesRepository;
  Map<String, dynamic>? _publicacion;
  List<Map<String, dynamic>> _soluciones = [];
  bool _cargandoPublicacion = true;
  bool _cargandoSoluciones = true;
  String? _error;

  final TextEditingController _solucionController = TextEditingController();
  Uint8List? _archivoSolucionBytes;
  String? _nombreArchivoSolucion;
  bool _enviandoSolucion = false;
  String? _cedulaUsuario;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _solucionesRepository = SolucionesRepository(_supabase);
    _cargarTodo();
    _obtenerDatosUsuario();
  }

  Future<void> _obtenerDatosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
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
      final solData = await _solucionesRepository
          .getSolucionesVistaPorPublicacion(widget.publicacionId);
      debugPrint("📦 Se obtuvieron ${solData.length} soluciones.");
      setState(() {
        _soluciones = solData;
        _cargandoSoluciones = false;
      });
    } catch (e) {
      debugPrint("❌ Error cargando soluciones: $e");
      setState(() => _cargandoSoluciones = false);
    }
  }

  Future<void> _calificarSolucion(int idSolucion, int estrellas) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para calificar')),
      );
      return;
    }

    // Buscar la solución para ver si es propia
    final solucion = _soluciones.firstWhere(
      (s) => s['id_solucion'] == idSolucion,
    );
    if (solucion['usuario_id'] == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes calificar tu propia solución')),
      );
      return;
    }

    // Verificar si ya calificó
    final calificaciones = List<Map<String, dynamic>>.from(
      solucion['calificacion_soluciones'] ?? [],
    );
    final yaVoto = calificaciones.any((c) => c['usuario_id'] == _currentUserId);
    if (yaVoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has calificado esta solución')),
      );
      return;
    }

    try {
      await _supabase.from('calificacion_soluciones').insert({
        'id_solucion': idSolucion,
        'usuario_id': _currentUserId,
        'estrellas': estrellas,
      });
      await _recargarSoluciones();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificación guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calificar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _aceptarSolucion(int idSolucion) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para aceptar soluciones'),
        ),
      );
      return;
    }

    final esAutor = _publicacion?['autor_id'] == _currentUserId;
    if (!esAutor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el autor puede aceptar una solución'),
        ),
      );
      return;
    }

    if (_publicacion?['estado'] == 'resuelto' ||
        _publicacion?['estado'] == 'pagado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta publicaciÃ³n ya fue resuelta')),
      );
      return;
    }

    try {
      await _solucionesRepository.aceptarSolucion(
        idPublicacion: widget.publicacionId,
        idSolucion: idSolucion,
      );

      await _recargarSoluciones();
      await _cargarTodo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solución aceptada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarArchivoSolucion() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      withData: true,
    );
    final archivo = resultado?.files.single;
    if (archivo != null && archivo.bytes != null) {
      setState(() {
        _archivoSolucionBytes = archivo.bytes;
        _nombreArchivoSolucion = archivo.name;
      });
    }
  }

  Future<void> _subirYEnviarSolucion() async {
    if (_currentUserId == null) return;

    final estaPendiente = await _solucionesRepository.publicacionEstaPendiente(
      widget.publicacionId,
    );
    if (!mounted) return;

    if (!estaPendiente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta publicacion ya fue resuelta'),
          backgroundColor: Colors.orange,
        ),
      );
      await _cargarTodo();
      return;
    }

    if (_publicacion?['autor_id'] == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes responder a tu propia pregunta.'),
        ),
      );
      return;
    }

    if (_solucionController.text.trim().isEmpty &&
        _archivoSolucionBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una explicación o adjunta un archivo.'),
        ),
      );
      return;
    }

    if (_cedulaUsuario == null) {
      await _obtenerDatosUsuario();
    }

    setState(() => _enviandoSolucion = true);
    String? urlArchivoSubido;

    try {
      if (_archivoSolucionBytes != null) {
        final extension = (_nombreArchivoSolucion ?? 'jpg').split('.').last;
        final pathArchivo =
            'soluciones/${DateTime.now().millisecondsSinceEpoch}.$extension';
        await _supabase.storage
            .from('soluciones')
            .uploadBinary(
              pathArchivo,
              _archivoSolucionBytes!,
              fileOptions: FileOptions(
                contentType: extension.toLowerCase() == 'pdf'
                    ? 'application/pdf'
                    : 'image/jpeg',
              ),
            );
        urlArchivoSubido = _supabase.storage
            .from('soluciones')
            .getPublicUrl(pathArchivo);
      }

      final solucionGuardada = await _solucionesRepository
          .subirSolucionDesdeApp(
            idPublicacion: widget.publicacionId,
            comentario: _solucionController.text.trim(),
            archivoUrl: urlArchivoSubido,
          );

      debugPrint("✅ Solución insertada correctamente.");

      _solucionController.clear();
      setState(() {
        _archivoSolucionBytes = null;
        _nombreArchivoSolucion = null;
        _soluciones = [solucionGuardada, ..._soluciones];
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
    final puntosBase =
        _publicacion!['puntuacion'] ?? 0; // ← Obtén los puntos base

    final preguntaForo = ForoPregunta(
      id: widget.publicacionId,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: 0,
      puntosBase: puntosBase, // ← Agrega este argumento
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
    final archivoPubUrl = pub['foto_url'] ?? pub['archivo_url'];

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
              // Tarjeta del enunciado
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
                    final esAutor = _publicacion?['autor_id'] == _currentUserId;
                    final publicacionResuelta =
                        _publicacion?['estado'] == 'resuelto' ||
                        _publicacion?['estado'] == 'pagado';
                    final estaAceptada = sol['aceptada'] == true;
                    //final sol = _soluciones[index];
                    final autor = sol['usuarios'] != null
                        ? '${sol['usuarios']['nombre']} ${sol['usuarios']['apellido']}'
                        : 'Usuario desconocido';
                    final calificaciones = List<Map<String, dynamic>>.from(
                      sol['calificacion_soluciones'] ?? [],
                    );
                    double promedio = 0.0;
                    int totalVotos = calificaciones.length;
                    if (totalVotos > 0) {
                      final suma = calificaciones.fold<int>(
                        0,
                        (s, c) => s + (c['estrellas'] as int),
                      );
                      promedio = suma / totalVotos;
                    }
                    final puntosGanados = (promedio / 5) * (puntosBase ?? 0);
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
                                Text(
                                  autor,
                                  style: const TextStyle(
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
                            if (esAutor &&
                                !publicacionResuelta &&
                                !estaAceptada)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _aceptarSolucion(sol['id_solucion']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      40,
                                    ),
                                  ),
                                  child: const Text(
                                    'ACEPTAR SOLUCIÓN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if ((sol['comentario_solucion'] ?? '').isNotEmpty)
                              Text(
                                sol['comentario_solucion'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            if ((sol['archivo_url'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildArchivoGrande(sol['archivo_url']),
                            ],
                            const Divider(height: 24),
                            // Estrellas y promedio
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  totalVotos == 0
                                      ? 'Sin votos'
                                      : '${promedio.toStringAsFixed(1)} ★ ($totalVotos)',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    final starValue = index + 1;
                                    // Resaltar estrellas según el promedio (visual)
                                    final isFilled =
                                        starValue <= promedio.round();
                                    return InkWell(
                                      onTap: () => _calificarSolucion(
                                        sol['id_solucion'],
                                        starValue,
                                      ),
                                      child: Icon(
                                        isFilled
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puntos ganados por el autor: ${puntosGanados.toStringAsFixed(0)} pts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
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
    if (_publicacion == null) return const SizedBox.shrink();
    final esMiPropioEjercicio = _publicacion!['autor_id'] == _currentUserId;
    final estaResuelta =
        _publicacion!['estado'] == 'resuelto' ||
        _publicacion!['estado'] == 'pagado';

    if (estaResuelta) {
      return Card(
        margin: const EdgeInsets.only(top: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Solicitud cerrada: ya hay una soluciÃ³n aceptada.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            if (esMiPropioEjercicio) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'No puedes responder a tu propia pregunta.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _enviandoSolucion || esMiPropioEjercicio
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
              enabled: !_enviandoSolucion && !esMiPropioEjercicio,
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
                onPressed: _enviandoSolucion || esMiPropioEjercicio
                    ? null
                    : _subirYEnviarSolucion,
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

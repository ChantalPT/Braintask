import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:braintask/presentation/pages/detalle_foro_pregunta.dart';
import 'package:braintask/data/models/foro_pregunta.dart';
import 'package:braintask/data/repositories/solucion_repository.dart';
import 'package:braintask/data/repositories/pago_repository.dart';
import 'package:braintask/logic/providers/usuario_provider.dart';

class DetallePublicacionPage extends ConsumerStatefulWidget {
  final int publicacionId;
  const DetallePublicacionPage({super.key, required this.publicacionId});

  @override
  ConsumerState<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends ConsumerState<DetallePublicacionPage> {
  final _supabase = Supabase.instance.client;
  late final SolucionesRepository _solucionesRepository;
  late final PagoRepository _pagoRepository;
  Map<String, dynamic>? _publicacion;
  Map<String, dynamic>? _autorPublicacion;
  List<Map<String, dynamic>> _soluciones = [];
  bool _cargandoPublicacion = true;
  bool _cargandoSoluciones = true;
  String? _error;

  final TextEditingController _solucionController = TextEditingController();
  Uint8List? _archivoSolucionBytes;
  String? _nombreArchivoSolucion;
  bool _enviandoSolucion = false;
  bool _procesandoPago = false;
  String? _cedulaUsuario;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _solucionesRepository = SolucionesRepository(_supabase);
    _pagoRepository = PagoRepository(_supabase);
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
      });

      if (pubData['autor_id'] != null) {
        final autorData = await _supabase
            .from('usuarios')
            .select('nombre, apellido, puntuacion')
            .eq('auth_user_id', pubData['autor_id'])
            .maybeSingle();
        setState(() {
          _autorPublicacion = autorData;
        });
      }

      setState(() {
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
    setState(() => _cargandoSoluciones = true);
    try {
      final solData = await _supabase
          .from('soluciones')
          .select('''
            *,
            usuarios!soluciones_usuario_id_fkey (
              nombre,
              apellido,
              puntuacion,
              auth_user_id
            )
          ''')
          .eq('id_publicacion', widget.publicacionId)
          .order('fecha_subida', ascending: false);
      setState(() {
        _soluciones = List<Map<String, dynamic>>.from(solData);
        _cargandoSoluciones = false;
      });
    } catch (e) {
      print('❌ Error al recargar soluciones: $e');
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

    final solucion = _soluciones.firstWhere(
      (s) => s['id_solucion'] == idSolucion,
    );
    if (solucion['usuario_id'] == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes calificar tu propia solución')),
      );
      return;
    }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calificación guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calificar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<int?> _mostrarDialogoCalificacion({
    required String solverNombre,
    required int puntosBase,
  }) {
    int estrellasSeleccionadas = 0;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Calificar solución',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Solución de: $solverNombre'),
                const SizedBox(height: 16),
                Text(
                  'Puntos base: $puntosBase pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Asigna una calificación de 1 a 5 estrellas:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= estrellasSeleccionadas
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          estrellasSeleccionadas = starValue;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (estrellasSeleccionadas > 0)
                  Text(
                    'Puntos a otorgar: ${(puntosBase * estrellasSeleccionadas / 5).round()} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: estrellasSeleccionadas == 0
                    ? null
                    : () => Navigator.of(ctx).pop(estrellasSeleccionadas),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aceptar y otorgar puntos'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _aceptarSolucionConCalificacion(
    int idSolucion,
    Map<String, dynamic> solucion,
  ) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para aceptar soluciones')),
      );
      return;
    }

    final esAutor = _publicacion?['autor_id'] == _currentUserId;
    if (!esAutor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo el autor puede aceptar una solución')),
      );
      return;
    }

    final estado = _publicacion?['estado'];
    if (estado == 'resuelto' || estado == 'pagado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta publicación ya fue resuelta')),
      );
      return;
    }

    final puntosBase = (_publicacion?['puntuacion'] as int?) ?? 0;

    final usuarioData = solucion['usuarios'];
    final idSolver = usuarioData?['auth_user_id'] as String?;
    final solverNombre = '${usuarioData?['nombre'] ?? ''} ${usuarioData?['apellido'] ?? ''}'.trim();

    if (idSolver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el auth_user_id del solver')),
      );
      return;
    }

    final estrellas = await _mostrarDialogoCalificacion(
      solverNombre: solverNombre,
      puntosBase: puntosBase,
    );
    if (estrellas == null || estrellas < 1 || estrellas > 5) return;

    final puntosOtorgados = (puntosBase * estrellas / 5).round();

    setState(() => _procesandoPago = true);
    try {
      await _supabase
          .from('soluciones')
          .update({
            'aceptada': true,
            'calificacion': estrellas,
          })
          .eq('id_solucion', idSolucion)
          .eq('id_publicacion', widget.publicacionId);

      await _supabase
          .from('publicaciones')
          .update({'estado': 'pagado'})
          .eq('id_publicacion', widget.publicacionId);

      final pago = await _pagoRepository.otorgarPuntos(
        idPublicacion: widget.publicacionId,
        idSolucion: idSolucion,
        idReceptor: idSolver,
        monto: puntosOtorgados,
      );

      // 🔁 REFRESCAR EL PROVIDER DEL USUARIO SI EL SOLVER ES EL USUARIO ACTUAL
      if (idSolver == _currentUserId) {
        ref.refresh(usuarioProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Tus puntos han sido actualizados!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      await _cargarTodo();

      if (!mounted) return;
      _mostrarConfirmacionPago(pago.idPago, puntosOtorgados, solverNombre, estrellas);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesandoPago = false);
    }
  }

  void _mostrarConfirmacionPago(int idPago, int monto, String solverNombre, int estrellas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 8),
            const Text(
              '¡Solución aceptada!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calificación: $estrellas ★',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Se han otorgado $monto puntos a $solverNombre.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ID de transacción: #$idPago',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
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

      final insertData = {
        'id_publicacion': widget.publicacionId,
        'usuario_id': _currentUserId,
        'cedula_usuario_solver': _cedulaUsuario ?? 'sin_cedula',
        'comentario_solucion': _solucionController.text.trim(),
        'archivo_url': urlArchivoSubido,
        'aceptada': false,
        'fecha_subida': DateTime.now().toIso8601String(),
      };
      await _supabase.from('soluciones').insert(insertData);

      _solucionController.clear();
      setState(() {
        _archivoSolucionBytes = null;
        _nombreArchivoSolucion = null;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _recargarSoluciones();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solución publicada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
    final puntosBase = _publicacion!['puntuacion'] ?? 0;

    final preguntaForo = ForoPregunta(
      id: widget.publicacionId,
      titulo: titulo,
      descripcion: descripcion,
      autorNombre: autorNombre,
      votos: 0,
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
    final archivoPubUrl = pub['foto_url'] ?? pub['archivo_url'];
    final estadoPublicacion = pub['estado'] ?? 'pendiente';

    final autorNombre = _autorPublicacion != null
        ? '${_autorPublicacion!['nombre']} ${_autorPublicacion!['apellido']}'
        : 'Usuario desconocido';
    final autorPuntos = _autorPublicacion != null ? _autorPublicacion!['puntuacion'] ?? 0 : 0;

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
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () async {
              await _recargarSoluciones();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recargado: ${_soluciones.length} soluciones'),
                ),
              );
            },
            tooltip: 'Recargar soluciones',
          ),
        ],
      ),
      body: _procesandoPago
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Procesando...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    titulo,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildEstadoBadge(estadoPublicacion),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.blue),
                                const SizedBox(width: 5),
                                Text(
                                  autorNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$autorPuntos pts',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.orange, size: 18),
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
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          final publicacionCerrada = estadoPublicacion == 'resuelto' || estadoPublicacion == 'pagado';
                          final estaAceptada = sol['aceptada'] == true;
                          final usuarioSol = sol['usuarios'] ?? {};
                          final nombreSolver = '${usuarioSol['nombre'] ?? 'Usuario'} ${usuarioSol['apellido'] ?? ''}'.trim();
                          final puntosSolver = usuarioSol['puntuacion'] ?? 0;
                          final calificacionAutor = sol['calificacion'] as int?;
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
                          final puntosGanados = estaAceptada && calificacionAutor != null
                              ? ((puntosBase * calificacionAutor / 5).round())
                              : 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: estaAceptada && estadoPublicacion == 'pagado'
                                    ? Colors.green.shade300
                                    : Colors.grey.shade300,
                                width: estaAceptada && estadoPublicacion == 'pagado' ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            nombreSolver,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '$puntosSolver pts',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildSolucionBadge(estaAceptada, estadoPublicacion),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (esAutor && !publicacionCerrada && !estaAceptada)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: ElevatedButton.icon(
                                        onPressed: () => _aceptarSolucionConCalificacion(
                                          sol['id_solucion'],
                                          sol,
                                        ),
                                        icon: const Icon(Icons.star),
                                        label: const Text(
                                          'CALIFICAR Y ACEPTAR SOLUCIÓN',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size(double.infinity, 44),
                                        ),
                                      ),
                                    ),
                                  if ((sol['comentario_solucion'] ?? '').isNotEmpty)
                                    Text(sol['comentario_solucion'], style: const TextStyle(fontSize: 14)),
                                  if ((sol['archivo_url'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _buildArchivoGrande(sol['archivo_url']),
                                  ],
                                  const Divider(height: 24),
                                  if (estaAceptada && calificacionAutor != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Calificación del autor: $calificacionAutor ★',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        totalVotos == 0
                                            ? 'Sin votos'
                                            : '${promedio.toStringAsFixed(1)} ★ ($totalVotos)',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                      Row(
                                        children: List.generate(5, (index) {
                                          final starValue = index + 1;
                                          final isFilled = starValue <= promedio.round();
                                          return InkWell(
                                            onTap: () => _calificarSolucion(
                                              sol['id_solucion'],
                                              starValue,
                                            ),
                                            child: Icon(
                                              isFilled ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                              size: 24,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (puntosGanados > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Puntos otorgados al solver: $puntosGanados pts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
                                        ),
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

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String label;
    IconData icon;
    switch (estado) {
      case 'pagado':
        color = Colors.green;
        label = 'Pagado';
        icon = Icons.verified;
        break;
      case 'resuelto':
        color = Colors.blue;
        label = 'Resuelto';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.orange;
        label = 'Pendiente';
        icon = Icons.pending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolucionBadge(bool aceptada, String estadoPublicacion) {
    if (aceptada && estadoPublicacion == 'pagado') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 14, color: Colors.green.shade800),
            const SizedBox(width: 4),
            Text(
              'Aceptada · Pagada',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: aceptada ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        aceptada ? 'Aceptada' : 'Pendiente',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: aceptada ? Colors.blue.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildFormularioSolucion() {
    if (_publicacion == null) return const SizedBox.shrink();
    final esMiPropioEjercicio = _publicacion!['autor_id'] == _currentUserId;
    final estado = _publicacion!['estado'];
    final estaResuelta = estado == 'resuelto' || estado == 'pagado';

    if (estaResuelta) {
      return Card(
        margin: const EdgeInsets.only(top: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                estado == 'pagado' ? Icons.verified : Icons.check_circle,
                color: estado == 'pagado' ? Colors.green.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  estado == 'pagado'
                      ? 'Ejercicio completado: solución aceptada y recompensa pagada.'
                      : 'Solicitud cerrada: ya hay una solución aceptada.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                  style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _enviandoSolucion || esMiPropioEjercicio ? null : _seleccionarArchivoSolucion,
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
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _solucionController,
              maxLines: 3,
              enabled: !_enviandoSolucion && !esMiPropioEjercicio,
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
                onPressed: _enviandoSolucion || esMiPropioEjercicio ? null : _subirYEnviarSolucion,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF)),
                child: _enviandoSolucion
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENVIAR SOLUCIÓN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
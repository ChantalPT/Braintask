import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:braintask/presentation/pages/perfil_publico_page.dart';
import 'package:braintask/data/repositories/comentario_repository.dart';
import 'package:braintask/data/models/comentarios.dart';
import 'package:braintask/data/repositories/solucion_repository.dart';
import 'package:braintask/data/repositories/pago_repository.dart';
import 'reporte_dialog.dart';
import '../../data/models/soluciones.dart';

class DetallePublicacionPage extends StatefulWidget {
  final int publicacionId;
  const DetallePublicacionPage({super.key, required this.publicacionId});

  @override
  State<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends State<DetallePublicacionPage> {
  final _supabase = Supabase.instance.client;
  late final ComentarioRepository _comentarioRepo;
  late final SolucionesRepository _solucionesRepository;
  late final PagoRepository _pagoRepository;

  Map<String, dynamic>? _publicacion;
  Map<String, dynamic>? _autorPublicacion;
  List<Map<String, dynamic>> _soluciones = [];
  List<Comentario> _comentarios = [];

  bool _cargandoPublicacion = true;
  bool _cargandoSoluciones = true;
  bool _cargandoComentarios = true;
  String? _error;

  // Estado de pestañas: 0 = Soluciones, 1 = Comentarios
  int _tabActiva = 0;

  // Estado formulario solución (expansible)
  bool _formularioSolucionVisible = false;
  final TextEditingController _solucionController = TextEditingController();
  Uint8List? _archivoSolucionBytes;
  String? _nombreArchivoSolucion;
  bool _enviandoSolucion = false;

  // Estado formulario comentario
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviandoComentario = false;

  bool _procesandoPago = false;

  String? _cedulaUsuario;
  int? _cedulaUsuarioInt;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _comentarioRepo = ComentarioRepository(_supabase);
    _solucionesRepository = SolucionesRepository(_supabase);
    _pagoRepository = PagoRepository(_supabase);
    _cargarTodo();
    _obtenerDatosUsuario();
  }

  @override
  void dispose() {
    _solucionController.dispose();
    _comentarioController.dispose();
    super.dispose();
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
        _cedulaUsuarioInt = int.tryParse(_cedulaUsuario ?? '');
      }
    }
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargandoPublicacion = true;
      _cargandoSoluciones = true;
      _cargandoComentarios = true;
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

      // Obtener datos del autor
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

      await Future.wait([_recargarSoluciones(), _recargarComentarios()]);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargandoPublicacion = false;
        _cargandoSoluciones = false;
        _cargandoComentarios = false;
      });
    }
  }

  Future<void> _recargarSoluciones() async {
    setState(() => _cargandoSoluciones = true);
    try {
      final solData = await _supabase
          .from('soluciones')
          //AQUÍ ESTÁ EL CAMBIO: Agregue 'total_reportes,' en el select
          .select('''
            *, 
            total_reportes,
            usuarios!cedula_usuario_solver(nombre, apellido), 
            calificacion_soluciones(usuario_id, estrellas)
          ''')
          .eq('id_publicacion', widget.publicacionId)
          .order('fecha_subida', ascending: false);

      final List<Map<String, dynamic>> solucionesConUsuario = [];
      for (var sol in solData) {
        final usuario = sol['usuarios'] ?? {};
        solucionesConUsuario.add({...sol, 'usuarios': usuario});
      }

      setState(() {
        _soluciones = solucionesConUsuario;
        _cargandoSoluciones = false;
      });
    } catch (e) {
      debugPrint('Error cargando soluciones: $e');
      setState(() => _cargandoSoluciones = false);
    }
  }

  Future<void> _recargarComentarios() async {
    setState(() => _cargandoComentarios = true);
    try {
      final lista = await _comentarioRepo.obtenerComentarios(
        widget.publicacionId,
      );
      setState(() {
        _comentarios = lista;
        _cargandoComentarios = false;
      });
    } catch (e) {
      debugPrint('Error cargando comentarios: $e');
      setState(() => _cargandoComentarios = false);
    }
  }

  // ── SOLUCIONES ──────────────────────────────────────────────────────────────

  Future<void> _calificarSolucion(int idSolucion, int estrellas) async {
    if (_currentUserId == null) {
      _snack('Debes iniciar sesión para calificar');
      return;
    }
    final solucion = _soluciones.firstWhere(
      (s) => s['id_solucion'] == idSolucion,
    );
    if (solucion['usuario_id'] == _currentUserId) {
      _snack('No puedes calificar tu propia solución');
      return;
    }
    final calificaciones = List<Map<String, dynamic>>.from(
      solucion['calificacion_soluciones'] ?? [],
    );
    if (calificaciones.any((c) => c['usuario_id'] == _currentUserId)) {
      _snack('Ya has calificado esta solución');
      return;
    }
    try {
      await _supabase.from('calificacion_soluciones').insert({
        'id_solucion': idSolucion,
        'usuario_id': _currentUserId,
        'estrellas': estrellas,
      });
      await _recargarSoluciones();
      _snack('Calificación guardada', color: Colors.green);
    } catch (e) {
      _snack('Error al calificar: $e', color: Colors.red);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
    String idSolver,
    String solverNombre,
  ) async {
    print("Entrando a _aceptarSolucionConCalificacion");
    if (_currentUserId == null) {
      _snack('Debes iniciar sesión para aceptar soluciones');
      return;
    }

    final esAutor = _publicacion?['autor_id'] == _currentUserId;
    if (!esAutor) {
      _snack('Solo el autor puede aceptar una solución');
      return;
    }

    final estado = _publicacion?['estado'];
    if (estado == 'resuelto' || estado == 'pagado') {
      _snack('Esta publicación ya fue resuelta');
      return;
    }

    final puntosBase = (_publicacion?['puntuacion'] as int?) ?? 0;
    print("1. Antes de mostrar diálogo");
    final estrellas = await _mostrarDialogoCalificacion(
      solverNombre: solverNombre,
      puntosBase: puntosBase,
    );
    print("2. Diálogo cerrado, estrellas: $estrellas");
    if (estrellas == null || estrellas < 1 || estrellas > 5) return;
    print("3. Estrellas inválidas, saliendo");

    final puntosOtorgados = (puntosBase * estrellas / 5).round();
    print("4. Calculando puntos: $puntosOtorgados");
    setState(() => _procesandoPago = true);
    print("5. Actualizando soluciones...");
    try {
      await _supabase
          .from('soluciones')
          .update({'aceptada': true, 'calificacion': estrellas})
          .eq('id_solucion', idSolucion)
          .eq('id_publicacion', widget.publicacionId);
      print("6. Soluciones actualizadas");
      await _supabase
          .from('publicaciones')
          .update({'estado': 'pagado'})
          .eq('id_publicacion', widget.publicacionId);
      print("7. Publicaciones actualizadas");
      print("8. Antes de pago repository");
      final pago = await _pagoRepository.otorgarPuntos(
        idPublicacion: widget.publicacionId,
        idReceptor: idSolver,
        monto: puntosOtorgados,
        idSolucion: idSolucion,
      );
      print("9. Pago realizado, id: ${pago.idPago}");
      print("10. Insertando notificación...");
      // Insert notification for the solver
      print("idSolver: '$idSolver'");
      final titulo = _publicacion?['titulo'] ?? 'un ejercicio';
      await _supabase.from('notificaciones').insert({
        'usuario_id': idSolver,
        'mensaje':
            '¡Tu solución fue aceptada! Recibiste $puntosOtorgados puntos por resolver "$titulo".',
        'tipo': 'solucion_aceptada',
        'id_publicacion': widget.publicacionId,
        'leida': false,
      });
      print("Notificación insertada correctamente");

      await _cargarTodo();
      if (!mounted) return;
      _mostrarConfirmacionPago(
        pago.idPago,
        puntosOtorgados,
        solverNombre,
        estrellas,
      );
    } catch (e) {
      if (!mounted) return;
      _snack('Error al procesar: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _procesandoPago = false);
    }
  }

  void _mostrarConfirmacionPago(
    int idPago,
    int monto,
    String solverNombre,
    int estrellas,
  ) {
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
    print(" SOLUCIÓN INSERTADA");
    final estaPendiente = await _solucionesRepository.publicacionEstaPendiente(
      widget.publicacionId,
    );
    if (!mounted) return;

    if (!estaPendiente) {
      _snack('Esta publicacion ya fue resuelta', color: Colors.orange);
      await _cargarTodo();
      return;
    }

    if (_publicacion?['autor_id'] == _currentUserId) {
      _snack('No puedes responder a tu propia pregunta.');
      return;
    }

    if (_solucionController.text.trim().isEmpty &&
        _archivoSolucionBytes == null) {
      _snack('Escribe una explicación o adjunta un archivo.');
      return;
    }
    if (_cedulaUsuario == null) await _obtenerDatosUsuario();

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

      //Funcion para obtener la notificacion de la solucion enviada, para luego
      //enviar la notificacion al autor de la publicacion
      final autorId = _publicacion?['autor_id'];
      if (autorId != null &&
          autorId != _currentUserId &&
          _currentUserId != null) {
        print("autorId: $autorId");
        try {
          final solverData = await _supabase
              .from('usuarios')
              .select('nombre, apellido')
              .eq('auth_user_id', _currentUserId!)
              .single();
          final solverNombreCompleto =
              '${solverData['nombre']} ${solverData['apellido']}';
          print("📌 _currentUserId: $_currentUserId");
          print("📌 solverNombreCompleto: $solverNombreCompleto");
          //Notificación al autor
          await _supabase.from('notificaciones').insert({
            'usuario_id': autorId,
            'mensaje':
                '$solverNombreCompleto ha enviado una solución a tu ejercicio "${_publicacion!['titulo']}".',
            'tipo': 'nueva_solucion',
            'id_publicacion': widget.publicacionId,
            'leida': false,
          });
          print("📌 id_publicacion: ${widget.publicacionId}");
        } catch (e) {
          debugPrint('Error al enviar notificación: $e');
        }
      }

      _solucionController.clear();
      setState(() {
        _archivoSolucionBytes = null;
        _nombreArchivoSolucion = null;
        _formularioSolucionVisible = false;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      await _recargarSoluciones();
      if (mounted) _snack('¡Solución publicada!', color: Colors.green);
    } catch (e) {
      if (mounted) _snack('Error al enviar: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _enviandoSolucion = false);
    }
  }

  // ── COMENTARIOS ─────────────────────────────────────────────────────────────

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) return;
    if (_cedulaUsuarioInt == null) {
      _snack('No se pudo obtener tu cédula. Intenta de nuevo.');
      return;
    }
    setState(() => _enviandoComentario = true);
    try {
      await _comentarioRepo.insertarComentario(
        publicacionId: widget.publicacionId,
        usuarioCedula: _cedulaUsuarioInt!,
        contenido: texto,
      );
      _comentarioController.clear();
      await _recargarComentarios();
    } catch (e) {
      if (mounted) _snack('Error al comentar: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _enviandoComentario = false);
    }
  }

  Future<void> _votarComentario(int idComentario, int delta) async {
    try {
      await _comentarioRepo.votarComentario(
        idComentario: idComentario,
        delta: delta,
      );
      await _recargarComentarios();
    } catch (e) {
      if (mounted) _snack('Error al votar: $e', color: Colors.red);
    }
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  /// Navega al perfil pasando directamente un auth_user_id (UUID).
  void _irAPerfil(String authUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilPublicoPage(userId: authUserId)),
    );
  }

  /// Navega al perfil buscando primero el auth_user_id por cédula (int).
  Future<void> _irAPerfilPorCedula(int cedula) async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select('auth_user_id')
          .eq('cedula', cedula)
          .maybeSingle();
      final authId = data?['auth_user_id']?.toString();
      if (authId != null && mounted) {
        _irAPerfil(authId);
      }
    } catch (e) {
      if (mounted) _snack('No se pudo abrir el perfil', color: Colors.red);
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

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
    final autorPuntos = _autorPublicacion != null
        ? _autorPublicacion!['puntuacion'] ?? 0
        : 0;

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
              onRefresh: _cargarTodo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tarjeta del enunciado ──────────────────────────────────────
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
                            // Autor y sus puntos
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.blue,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
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
                            Text(
                              descripcion,
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (archivoPubUrl != null) ...[
                              const SizedBox(height: 12),
                              _buildArchivoGrande(archivoPubUrl),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Selector de pestañas ───────────────────────────────────────
                    _buildTabSelector(),
                    const SizedBox(height: 12),

                    // ── Contenido de la pestaña activa ────────────────────────────
                    if (_tabActiva == 0)
                      _buildVistaSoluciones(puntosBase)
                    else
                      _buildVistaComentarios(),
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

  Widget _buildSolucionBadge(
    bool estaAceptada,
    String estadoPublicacion,
    Map<String, dynamic> sol,
  ) {
    //Leer el campo directamente desde el mapa dinámico que viene de Supabase
    final int conteoReportes = sol['total_reportes'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: estaAceptada
                ? Colors.green.shade100
                : (estadoPublicacion == 'resuelto' ||
                          estadoPublicacion == 'pagado'
                      ? Colors.grey.shade200
                      : Colors.orange.shade100),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            estaAceptada
                ? 'Aceptada'
                : (estadoPublicacion == 'resuelto' ||
                          estadoPublicacion == 'pagado'
                      ? 'No elegida'
                      : 'Pendiente'),
            style: TextStyle(
              color: estaAceptada
                  ? Colors.green.shade700
                  : (estadoPublicacion == 'resuelto' ||
                            estadoPublicacion == 'pagado'
                        ? Colors.grey.shade700
                        : Colors.orange.shade700),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        // SI TIENE REPORTES ACUMULADOS, SE MUESTRA DEBAJO DEL BADGE
        if (conteoReportes > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.report_problem_outlined,
                color: conteoReportes >= 2
                    ? Colors.red
                    : Colors.orange.shade800,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                'Reportada: $conteoReportes',
                style: TextStyle(
                  color: conteoReportes >= 2
                      ? Colors.red
                      : Colors.orange.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── TAB SELECTOR ─────────────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(
            label: 'Soluciones (${_soluciones.length})',
            index: 0,
          ),
          _buildTabButton(
            label: 'Comentarios (${_comentarios.length})',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final isActive = _tabActiva == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActiva = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF007BFF) : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVistaSoluciones(int puntosBase) {
    final esMiPropioEjercicio = _publicacion?['autor_id'] == _currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón expansible "Publicar Solución"
        if (!esMiPropioEjercicio) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(
                () => _formularioSolucionVisible = !_formularioSolucionVisible,
              ),
              icon: Icon(
                _formularioSolucionVisible
                    ? Icons.expand_less
                    : Icons.add_circle_outline,
                size: 20,
              ),
              label: Text(
                _formularioSolucionVisible ? 'Cancelar' : 'Publicar Solución',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF007BFF),
                side: const BorderSide(color: Color(0xFF007BFF)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_formularioSolucionVisible) ...[
            const SizedBox(height: 12),
            _buildFormularioSolucionExpandido(),
          ],
          const SizedBox(height: 16),
        ],

        // Lista de soluciones
        if (_cargandoSoluciones)
          const Center(child: CircularProgressIndicator())
        else if (_soluciones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
            itemBuilder: (context, index) =>
                _buildSolucionCard(_soluciones[index], puntosBase),
          ),
      ],
    );
  }

  Widget _buildFormularioSolucionExpandido() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _enviandoSolucion
                    ? null
                    : _seleccionarArchivoSolucion,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text(
                  'Adjuntar Foto / PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            if (_nombreArchivoSolucion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Adjunto: $_nombreArchivoSolucion',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _enviandoSolucion ? null : _subirYEnviarSolucion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _enviandoSolucion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
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

  Widget _buildSolucionCard(Map<String, dynamic> sol, int puntosBase) {
    final int conteoReportes = sol['total_reportes'] as int? ?? 0;

    if (conteoReportes >= 3) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad_outlined, color: Colors.redAccent, size: 36),
              SizedBox(height: 8),
              Text(
                'Solución Bloqueada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Esta respuesta ha sido ocultada automáticamente debido a múltiples reportes de la comunidad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    final esAutorPublicacion = _publicacion?['autor_id'] == _currentUserId;
    final estadoPublicacion = _publicacion?['estado'] ?? 'pendiente';
    final publicacionCerrada =
        estadoPublicacion == 'resuelto' || estadoPublicacion == 'pagado';
    final estaAceptada = sol['aceptada'] == true;
    // Usamos cedula_usuario_solver (int8) para buscar el auth_user_id y navegar al perfil
    final cedulaSolverRaw = sol['cedula_usuario_solver'];
    final cedulaSolverInt = cedulaSolverRaw is int
        ? cedulaSolverRaw
        : int.tryParse(cedulaSolverRaw?.toString() ?? '');
    final usuarioSol = sol['usuarios'] != null
        ? sol['usuarios'] as Map<String, dynamic>
        : <String, dynamic>{};
    final autor =
        '${usuarioSol['nombre'] ?? 'Usuario'} ${usuarioSol['apellido'] ?? ''}'
            .trim();
    final idSolver = sol['usuario_id']?.toString() ?? '';
    final calificacionAutor = sol['calificacion'] as int?;
    final calificaciones = List<Map<String, dynamic>>.from(
      sol['calificacion_soluciones'] ?? [],
    );
    double promedio = 0.0;
    final totalVotos = calificaciones.length;
    if (totalVotos > 0) {
      final suma = calificaciones.fold<int>(
        0,
        (s, c) => s + (c['estrellas'] as int),
      );
      promedio = suma / totalVotos;
    }
    final puntosGanados = estaAceptada && calificacionAutor != null
        ? ((puntosBase * calificacionAutor / 5).round())
        : ((promedio / 5) * puntosBase).round();

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
            // Cabecera: autor + badge estado
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: cedulaSolverInt != null
                        ? () => _irAPerfilPorCedula(cedulaSolverInt)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            autor,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'reportar') {
                      ReporteDialog.mostrar(
                        context: context,
                        idUsuarioReportado: idSolver,
                        tipoReporte: 'solucion',
                        idObjetoReportado: sol['id_solucion'],
                        //AQUÍ SE AGREGO EL CALLBACK PARA QUE RECARGUE LA LISTA AL INSTANTE
                        onReporteEnviado: () {
                          _recargarSoluciones();
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'reportar',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Reportar solución'),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildSolucionBadge(estaAceptada, estadoPublicacion, sol),
              ],
            ),
            const SizedBox(height: 10),

            // Botón aceptar (solo autor de la publicación, publicación abierta)
            if (esAutorPublicacion && !publicacionCerrada && !estaAceptada)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _aceptarSolucionConCalificacion(
                    sol['id_solucion'],
                    idSolver,
                    autor,
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

            // Contenido
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

            // Calificación del autor (si fue aceptada)
            if (estaAceptada && calificacionAutor != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Calificación del autor: $calificacionAutor ★',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),

            // Calificación por estrellas (comunidad)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalVotos == 0
                      ? 'Sin calificaciones'
                      : '${promedio.toStringAsFixed(1)} ★ ($totalVotos)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return InkWell(
                      onTap: () =>
                          _calificarSolucion(sol['id_solucion'], starValue),
                      child: Icon(
                        starValue <= promedio.round()
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
            const SizedBox(height: 4),
            Text(
              'Puntos ganados: $puntosGanados pts',
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
  }

  // ── VISTA COMENTARIOS ────────────────────────────────────────────────────────

  Widget _buildVistaComentarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de comentarios
        if (_cargandoComentarios)
          const Center(child: CircularProgressIndicator())
        else if (_comentarios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Aún no hay comentarios. ¡Sé el primero!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comentarios.length,
            itemBuilder: (context, index) =>
                _buildComentarioCard(_comentarios[index]),
          ),

        const SizedBox(height: 16),

        // Campo de nuevo comentario (fijo al final)
        _buildFormularioComentario(),
      ],
    );
  }

  Widget _buildComentarioCard(Comentario comentario) {
    if (comentario.totalReportes >= 3) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.gpp_bad_outlined, color: Colors.redAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comentario ocultado por la comunidad debido a múltiples reportes.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =========================================================
    // SI ESTÁ LIMPIO, MOSTRAMOS TU DISEÑO ORIGINAL
    // =========================================================

    final cedulaAutor = comentario.usuarioCedula;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna de votos estilo Reddit
            Column(
              children: [
                InkWell(
                  onTap: () => _votarComentario(comentario.idComentario, 1),
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${comentario.votos}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: comentario.votos > 0
                        ? Colors.orange
                        : comentario.votos < 0
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _votarComentario(comentario.idComentario, -1),
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(
                    Icons.arrow_downward,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Contenido del comentario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _irAPerfilPorCedula(cedulaAutor),
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          comentario.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 24,
                        width: 24,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'reportar') {
                              ReporteDialog.mostrar(
                                context: context,
                                idUsuarioReportado: cedulaAutor.toString(),
                                tipoReporte: 'comentario',
                                idObjetoReportado: comentario.idComentario,
                                onReporteEnviado: () {
                                  //QUÍ ESTÁ LA FUNCIÓN EXACTA PARA RECARGAR
                                  _recargarComentarios();
                                },
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'reportar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Reportar comentario'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comentario.contenido,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFecha(comentario.fechaCreacion),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioComentario() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _comentarioController,
              maxLines: 3,
              minLines: 1,
              enabled: !_enviandoComentario,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _enviandoComentario ? null : _enviarComentario,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: _enviandoComentario
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── UTILIDADES ───────────────────────────────────────────────────────────────

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  Widget _buildArchivoGrande(String url) {
    final extension = url.split('.').last.toLowerCase().split('?').first;
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
          errorBuilder: (context, error, stackTrace) => Container(
            height: 80,
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      );
    }
  }
}

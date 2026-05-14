import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetallePublicacionPage extends StatefulWidget {
  final int publicacionId;
  const DetallePublicacionPage({super.key, required this.publicacionId});

  @override
  State<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends State<DetallePublicacionPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _publicacion;
  bool _cargando = true;
  String? _error;

  // Calificaciones
  double? _averageDifficulty;
  int? _userRating;
  bool _ratingLoading = false;
  final Set<int> _ratedPublications = {};

  @override
  void initState() {
    super.initState();
    _cargarCalificacionesLocales();
    _cargarDetalle();
    _cargarRatingInfo();
  }

  Future<void> _cargarCalificacionesLocales() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? rated = prefs.getStringList('rated_publications');
    if (rated != null) {
      _ratedPublications.addAll(rated.map(int.parse));
    }
  }

  Future<void> _guardarCalificacionLocal(int rating) async {
    final prefs = await SharedPreferences.getInstance();
    _ratedPublications.add(widget.publicacionId);
    await prefs.setStringList(
        'rated_publications', _ratedPublications.map((e) => e.toString()).toList());
    await prefs.setInt('rating_${widget.publicacionId}', rating);
  }

  Future<void> _cargarDetalle() async {
    try {
      final response = await _supabase
          .from('publicaciones')
          .select('''
            *,
            materias!left (
              nombre_materias,
              id_facultad,
              facultades!left (nombre_facultad)
            )
          ''')
          .eq('id_publicacion', widget.publicacionId)
          .single();
      setState(() {
        _publicacion = response;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _cargarRatingInfo() async {
    try {
      final avgData = await _supabase
          .from('calificaciones_dificultad')
          .select('dificultad')
          .eq('id_publicacion', widget.publicacionId);

      if (avgData.isNotEmpty) {
        final sum = avgData.fold<int>(0, (p, n) => p + (n['dificultad'] as int));
        setState(() {
          _averageDifficulty = sum / avgData.length;
        });
      } else {
        setState(() => _averageDifficulty = null);
      }

      if (_ratedPublications.contains(widget.publicacionId)) {
        final prefs = await SharedPreferences.getInstance();
        final savedRating = prefs.getInt('rating_${widget.publicacionId}');
        if (savedRating != null) {
          setState(() => _userRating = savedRating);
        }
      }
    } catch (e) {
      debugPrint('Error cargando calificaciones: $e');
    }
  }

  Future<void> _enviarCalificacion(int rating) async {
    if (_ratedPublications.contains(widget.publicacionId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya calificaste este ejercicio anteriormente')),
      );
      return;
    }

    setState(() => _ratingLoading = true);
    try {
      await _supabase.from('calificaciones_dificultad').insert({
        'id_publicacion': widget.publicacionId,
        'dificultad': rating,
      });

      await _guardarCalificacionLocal(rating);
      setState(() => _userRating = rating);
      await _cargarRatingInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Gracias! Calificaste con $rating estrella(s)')),
      );
    } catch (e) {
      String mensaje = 'Error al guardar: $e';
      if (e.toString().contains('row-level security')) {
        mensaje = 'Error de permisos. Contacta al administrador.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _ratingLoading = false);
    }
  }

  Widget _buildRatingSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Califica la dificultad del ejercicio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('⭐ Promedio: ', style: TextStyle(fontSize: 14)),
                if (_averageDifficulty != null)
                  Text('${_averageDifficulty!.toStringAsFixed(1)} / 5',
                      style: const TextStyle(fontWeight: FontWeight.bold))
                else
                  const Text('Sin calificaciones', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Tu calificación:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            _ratingLoading
                ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      int starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          (_userRating != null && starValue <= _userRating!)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () => _enviarCalificacion(starValue),
                        splashRadius: 24,
                      );
                    }),
                  ),
            if (_userRating != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ya calificaste con $_userRating estrella(s). Solo puedes votar una vez.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensajeEnDesarrollo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad "Subir respuesta" en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Ejercicio'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _publicacion == null
                  ? const Center(child: Text('No se encontró la publicación'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _publicacion!['titulo'] ?? 'Sin título',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoMateria(),
                          const SizedBox(height: 20),
                          const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(_publicacion!['descripcion'] ?? 'Sin descripción'),
                          const SizedBox(height: 20),
                          if (_publicacion!['foto_url'] != null) ...[
                            const Text('Archivo adjunto del ejercicio:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildArchivo(_publicacion!['foto_url']),
                            const SizedBox(height: 20),
                          ],
                          _buildRatingSection(),
                          const Divider(height: 30),
                          const Text('Tu respuesta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _mostrarMensajeEnDesarrollo,
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 36, color: Color(0xFF007BFF)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Subir archivo de respuesta (JPG, PNG, PDF)',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    'Funcionalidad en desarrollo',
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Información adicional', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('📌 Tipo: ${_publicacion!['tipo'] ?? 'No especificado'}'),
                                  Text('⭐ Puntos: ${_publicacion!['puntuacion'] ?? 0}'),
                                  Text('📅 Publicado: ${_formatearFecha(_publicacion!['tiempo'])}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoMateria() {
    final materiasData = _publicacion!['materias'];
    if (materiasData == null) {
      return const Text(
        'Materia no especificada',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }
    final facultadesData = materiasData['facultades'];
    final materiaNombre = materiasData['nombre_materias'] ?? 'Materia desconocida';
    final facultadNombre = (facultadesData != null && facultadesData['nombre_facultad'] != null)
        ? facultadesData['nombre_facultad']
        : 'Facultad desconocida';
    return Row(
      children: [
        Icon(Icons.school, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '$facultadNombre • $materiaNombre',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildArchivo(String url) {
    final extension = url.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      return ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abrir PDF (próximamente)')),
          );
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Ver PDF'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, height: 200, fit: BoxFit.cover),
      );
    }
  }

  String _formatearFecha(String? fechaISO) {
    if (fechaISO == null) return 'desconocida';
    try {
      final fecha = DateTime.parse(fechaISO);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute}';
    } catch (e) {
      return 'fecha inválida';
    }
  }
}
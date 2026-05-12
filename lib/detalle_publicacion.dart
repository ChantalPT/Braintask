import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
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
                          // Título
                          Text(
                            _publicacion!['titulo'] ?? 'Sin título',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          // Materia y facultad (con manejo de nulos)
                          _buildInfoMateria(),
                          const SizedBox(height: 20),
                          // Descripción
                          const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(_publicacion!['descripcion'] ?? 'Sin descripción'),
                          const SizedBox(height: 20),
                          // Archivo adjunto original
                          if (_publicacion!['foto_url'] != null) ...[
                            const Text('Archivo adjunto del ejercicio:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildArchivo(_publicacion!['foto_url']),
                            const SizedBox(height: 20),
                          ],
                          // NUEVA SECCIÓN: Subir archivo de respuesta (en desarrollo)
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
                          // Información adicional
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

  // Widget para mostrar materia/facultad de forma segura
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
          // Por ahora solo muestra un mensaje
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
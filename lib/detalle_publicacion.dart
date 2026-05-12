
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
                          // Manejo seguro de materia/facultad nulas
                          _buildInfoMateria(),
                          const SizedBox(height: 20),
                          const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(_publicacion!['descripcion'] ?? 'Sin descripción'),
                          const SizedBox(height: 20),
                          if (_publicacion!['foto_url'] != null) ...[
                            const Text('Archivo adjunto:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildArchivo(_publicacion!['foto_url']),
                          ],
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Información adicional', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('📌 Tipo: ${_publicacion!['tipo_actividad'] ?? 'No especificado'}'),
                                  Text('⭐ Puntos: ${_publicacion!['puntos'] ?? 0}'),
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

  // Widget separado para mostrar materia/facultad con manejo de nulos
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
          print('Abrir PDF: $url');
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
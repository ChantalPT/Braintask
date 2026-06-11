import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/providers/perfil_publico_provider.dart';

class PerfilPublicoPage extends ConsumerStatefulWidget {
  final String userId;

  const PerfilPublicoPage({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<PerfilPublicoPage> createState() => _PerfilPublicoPageState();
}

class _PerfilPublicoPageState extends ConsumerState<PerfilPublicoPage> {
  final _supabase = Supabase.instance.client;
  String _nombreCarrera = 'Cargando...';

  // Creamos la misma logica independiente que usaste en filtro.dart
  Future<void> _cargarNombreCarrera(int? carreraId) async {
    if (carreraId == null) {
      if (mounted) setState(() => _nombreCarrera = 'No especificada');
      return;
    }

    try {
      final data = await _supabase
          .from('carreras')
          .select('nombre')
          .eq('id', carreraId)
          .single();

      if (mounted) {
        setState(() {
          _nombreCarrera = data['nombre'];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _nombreCarrera = 'Desconocida');
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicProfileAsync = ref.watch(perfilPublicoProvider(widget.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Perfil del Usuario',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: publicProfileAsync.when(
        data: (usuario) {
          // Disparamos la busqueda de la carrera usando el ID del usuario
          // Solo si aún dice 'Cargando...' para evitar consultas infinitas
          if (_nombreCarrera == 'Cargando...') {
            _cargarNombreCarrera(usuario.carreraId);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '${usuario.nombre} ${usuario.apellido}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      usuario.reputacionPromedio > 0
                          ? '${usuario.reputacionPromedio.toStringAsFixed(1)} / 5.0'
                          : 'Sin calificaciones',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (usuario.totalCalificaciones > 0)
                      Text(
                        ' (${usuario.totalCalificaciones} reseñas)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.monetization_on,
                          title: 'Puntuación Total',
                          value: '${usuario.puntuacion} pts',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.badge,
                          title: 'Carnet',
                          value: usuario.carnet,
                        ),
                        const Divider(),
                        // AQUI MOSTRAMOS LA VARIABLE DE ESTADO
                        _buildInfoRow(
                          icon: Icons.school,
                          title: 'Carrera',
                          value: _nombreCarrera,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.star_rate_rounded,
                          title: 'Reputación',
                          value: usuario.reputacionPromedio > 0
                              ? '${usuario.reputacionPromedio.toStringAsFixed(1)} / 5.0'
                              : 'Sin estrellas',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          return Center(
            child: Text(
              'Error al cargar perfil: $error',
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

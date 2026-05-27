import 'package:braintask/presentation/pages/detalle_publicacion.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Historial extends StatefulWidget {
  const Historial({super.key});

  @override
  State<Historial> createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _misPublicaciones = [];
  List<Map<String, dynamic>> _ejerciciosResueltos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      // Obtener la cédula del usuario actual
      final userData = await _supabase
          .from('usuarios')
          .select('cedula')
          .eq('auth_user_id', user.id)
          .single();
      final cedula = userData['cedula'] as String;

      final publicaciones = await _supabase
          .from('publicaciones')
          .select('''
            *,
            materias!left (nombre_materias)
          ''')
          .eq('autor_id', user.id)
          .order('tiempo', ascending: false);

      final soluciones = await _supabase
          .from('soluciones')
          .select('''
            id_publicacion,
            archivo_url,
            comentario_solucion,
            fecha_subida,
            publicaciones!inner (
              *,
              materias!left (nombre_materias)
            )
          ''')
          .eq('cedula_usuario_solver', cedula)
          .order('fecha_subida', ascending: false);

      setState(() {
        _misPublicaciones = List<Map<String, dynamic>>.from(publicaciones);
        _ejerciciosResueltos = soluciones
            .map((s) => s['publicaciones'] as Map<String, dynamic>)
            .toList();
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error cargando historial: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Color(0xFF007BFF),
                    labelColor: Color(0xFF007BFF),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Mis pedidos'),
                      Tab(text: 'Ejercicios resueltos'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLista(_misPublicaciones, tipo: 'pedido'),
                        _buildLista(_ejerciciosResueltos, tipo: 'resuelto'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> items, {required String tipo}) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No hay elementos en esta sección',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final pub = items[index];
          final materiaNombre =
              pub['materias']?['nombre_materias'] ?? 'Materia desconocida';
          final estado = pub['estado'] ?? 'pendiente';
          final estadoLabel = estado == 'pendiente' ? 'Pendiente' : 'Resuelto';
          final icono = tipo == 'pedido'
              ? (estado == 'pendiente' ? Icons.edit_note : Icons.check_circle)
              : Icons.assignment_turned_in;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(icono, color: const Color(0xFF007BFF)),
              title: Text(
                pub['titulo'] ?? 'Sin título',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$materiaNombre • ${pub['puntuacion']} pts'),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(estadoLabel),
                    backgroundColor: estado == 'pendiente'
                        ? Colors.orange[100]
                        : Colors.green[100],
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetallePublicacionPage(
                      publicacionId: pub['id_publicacion'],
                    ),
                  ),
                );
                _cargarHistorial();
              },
            ),
          );
        },
      ),
    );
  }
}
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
            aceptada,
            publicaciones!inner (
              *,
              materias!left (nombre_materias)
            )
          ''')
          .eq('usuario_id', user.id)
          .eq('aceptada', true)
          .order('created_at', ascending: false);

      setState(() {
        _misPublicaciones = List<Map<String, dynamic>>.from(publicaciones);
        _ejerciciosResueltos = soluciones
            .map((s) => s['publicaciones'] as Map<String, dynamic>)
            .toList();
        _cargando = false;
      });
    } catch (e) {
      print('Error cargando historial: $e');
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
        itemBuilder: (context, index) {},
      ),
    );
  }
}

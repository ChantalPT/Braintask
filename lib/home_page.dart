import 'package:supabase_flutter/supabase_flutter.dart';
import 'publicaciones.dart';
import 'detalle_publicacion.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _publicaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
  }

  // Carga las publicaciones desde Supabase
  Future<void> _cargarPublicaciones() async {
    print('🔄 Cargando publicaciones...');
    setState(() => _cargando = true);
    try {
      // Consulta con LEFT JOIN (recomendada)
      final data = await _supabase
          .from('publicaciones')
          .select('''
          *,
          materias!left (
            nombre_materias,
            id_facultad,
            facultades!left (nombre_facultad)
          )
        ''')
          .order('tiempo', ascending: false);

      print('✅ Publicaciones encontradas: ${data.length}');

      setState(() {
        _publicaciones = data;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error al cargar: $e');
      setState(() {
        _publicaciones = [];
        _cargando = false;
      });
    }
  }

  // Formatea el tiempo (no se usa en la tarjeta simplificada, pero lo dejo por si acaso)
  String _formatearTiempo(String? fechaISO) {
    if (fechaISO == null) return 'Reciente';
    try {
      final fecha = DateTime.parse(fechaISO);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      return 'Hace ${diff.inDays} d';
    } catch (e) {
      return 'Reciente';
    }
  }

  // Barra de búsqueda con botón de filtros
  Widget _buildSearchBar() {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF007BFF)),
            onPressed: () {
              // Acción para filtros
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Color(0xFF007BFF)),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '¿Qué materia buscas hoy?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Badge de reputación (estático)
  Widget _buildReputationBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars, color: Colors.orange, size: 16),
            SizedBox(width: 4),
            Text(
              '125 pts',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Banner "¿Tienes una duda?" (navega a PublicarPage y recarga al volver)
  Widget _buildActionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublicarPage()),
        );
        _cargarPublicaciones(); // Recarga la lista después de publicar
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF007BFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Text(
              '¿Tienes una duda?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Toca aquí para publicar tu ejercicio',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta simplificada: solo título y materia (al tocarla abre detalle)
  Widget _buildProblemCard(
    String title,
    String materia, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_outlined, color: Color(0xFF007BFF)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    materia,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Braintask',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [_buildReputationBadge(), const SizedBox(width: 15)],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Hola, Ale! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildSearchBar(),
            const SizedBox(height: 25),
            _buildActionBanner(context),
            const SizedBox(height: 25),
            const Text(
              'Problemas publicados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Lista de publicaciones o mensaje de carga/vacío
            if (_cargando)
              const Center(child: CircularProgressIndicator())
            else if (_publicaciones.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No hay publicaciones aún.\n¡Sé el primero en publicar un ejercicio!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _publicaciones.map((pub) {
                  final materiaData = pub['materias'];
                  final materiaNombre =
                      materiaData?['nombre_materias'] ?? 'Materia desconocida';
                  final publicacionId = pub['id_publicacion'];
                  return _buildProblemCard(
                    pub['titulo'] ?? 'Sin título',
                    materiaNombre,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePublicacionPage(
                            publicacionId: publicacionId,
                          ),
                        ),
                      );
                      // Recargar por si hubo cambios (votos, etc.)
                      _cargarPublicaciones();
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PublicarPage()),
            );
            _cargarPublicaciones(); // Recarga después de publicar
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            label: 'Foros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Publicar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

import 'package:braintask/help_support_page.dart';
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

  Future<void> _cargarPublicaciones() async {
    setState(() => _cargando = true);
    try {
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
          .eq('estado', 'pendiente')
          .order('tiempo', ascending: false);
      setState(() {
        _publicaciones = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _publicaciones = [];
        _cargando = false;
      });
      debugPrint('Error al cargar publicaciones: $e');
    }
  }

  // Barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
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

  // Lista de categorías
  Widget _buildCategoryList() {
    final categories = ['Todos', 'Matemáticas', 'Física', 'Química'];

    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: index == 0 ? const Color(0xFF007BFF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                categories[index],
                style: TextStyle(
                  color: index == 0 ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tarjeta con botones más pequeños y alineados a la derecha (misma altura que el título)
  Widget _buildProblemCard(
    String title,
    String materia,
    String descripcion,
    int puntuacion, {
    required VoidCallback onResolver,
    required VoidCallback onForo,
  }) {
    // Vista previa de la descripción (máx 120 caracteres)
    String descripcionPreview = descripcion.trim();
    if (descripcionPreview.length > 120) {
      descripcionPreview = '${descripcionPreview.substring(0, 120)}...';
    }
    if (descripcionPreview.isEmpty) {
      descripcionPreview = 'Sin descripción';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Fila con icono, titulo, materia, pts y botones.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$puntuacion pts',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: onResolver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Resolver'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: onForo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007BFF),
                            side: const BorderSide(color: Color(0xFF007BFF)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Foro'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcionPreview, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) async {
    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PublicarPage()),
      );

      _cargarPublicaciones();
      return;
    }

    if (index == 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HelpSupportPage()),
      );

      return;
    }

    setState(() {
      _currentIndex = index;
    });
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
              'Explorar materias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCategoryList(),
            const SizedBox(height: 25),
            const Text(
              'Problemas publicados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                    pub['descripcion'] ?? '',
                    pub['puntuacion'] ?? 0,
                    onResolver: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePublicacionPage(
                            publicacionId: publicacionId,
                          ),
                        ),
                      );

                      _cargarPublicaciones();
                    },
                    onForo: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad "Foro" en desarrollo'),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'Ayuda',
          ),
        ],
      ),
    );
  }
}

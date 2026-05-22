import 'package:braintask/presentation/pages/historial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../data/models/publicacion.dart';
import '../../data/repositories/publicaciones_repository.dart';
import 'publicaciones.dart';
import 'detalle_publicacion.dart';
import 'filtro.dart';
import 'help_support_page.dart';
import 'foro_page.dart';
import 'pantalla_carga.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PublicacionesRepository _repository;
  List<Publicacion> _publicaciones = [];
  bool _cargando = true;
  String _filtroEstado = 'pendiente';

  String? _filtroFacultadSeleccionada;
  String? _filtroMateriaSeleccionada;
  String? _filtroTipoSeleccionado;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = PublicacionesRepository(Supabase.instance.client);
    _cargarPublicaciones();
  }

  Future<void> _cargarPublicaciones() async {
    setState(() => _cargando = true);
    try {
      final data = await _repository.getPublicaciones(
        estado: _filtroEstado,
        idMateria: _filtroMateriaSeleccionada,
        idFacultad: _filtroFacultadSeleccionada,
        tipo: _filtroTipoSeleccionado,
        search: _searchQuery,
      );

      // Cargar promedios de dificultad en paralelo (opcional, mejorando UX)
      final actualizadas = await Future.wait(
        data.map((p) async {
          final avg = await _repository.getAverageDifficulty(p.id);
          return p.copyWith(promedioDificultad: avg);
        }),
      );

      setState(() {
        _publicaciones = actualizadas;
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

  // Eliminado _getAverageDifficulty y _avgCache ya que se maneja en el repositorio y copyWith

  void _mostrarFiltrosDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FiltroSheet(
          initialFacultad: _filtroFacultadSeleccionada,
          initialMateria: _filtroMateriaSeleccionada,
          initialTipo: _filtroTipoSeleccionado,
          onApply: (facultad, materia, tipo) {
            setState(() {
              _filtroFacultadSeleccionada = facultad;
              _filtroMateriaSeleccionada = materia;
              _filtroTipoSeleccionado = tipo;
            });
            _cargarPublicaciones();
          },
          onClear: () {
            setState(() {
              _filtroFacultadSeleccionada = null;
              _filtroMateriaSeleccionada = null;
              _filtroTipoSeleccionado = null;
            });
            _cargarPublicaciones();
          },
        );
      },
    );
  }

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
              _mostrarFiltrosDialog();
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
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF007BFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _cargarPublicaciones();
                    },
                    decoration: const InputDecoration(
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

  Widget _buildActionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublicarPage()),
        );
        _cargarPublicaciones();
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

  Widget _buildStatusFilter() {
    final opciones = [
      {'valor': 'pendiente', 'label': 'Pendientes'},
      {'valor': 'todos', 'label': 'Todos'},
      {'valor': 'resuelto', 'label': 'Resueltos'},
    ];

    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: opciones.length,
        itemBuilder: (context, index) {
          final opcion = opciones[index];
          final isSelected = _filtroEstado == opcion['valor'];
          return GestureDetector(
            onTap: () {
              if (_filtroEstado != opcion['valor']) {
                setState(() {
                  _filtroEstado = opcion['valor']!;
                });
                _cargarPublicaciones();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF007BFF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  opcion['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProblemCard(Publicacion pub) {
    String descripcionPreview = (pub.descripcion ?? '').trim();
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
                      pub.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pub.nombreMateria ?? 'Materia desconocida',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pub.puntuacion} pts',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pub.promedioDificultad?.toStringAsFixed(1) ??
                                  '--',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetallePublicacionPage(
                                  publicacionId: pub.id,
                                ),
                              ),
                            );
                            _cargarPublicaciones();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Resolver'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () {}, // Foro action
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
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForoPage()),
      );
      // Reset index to current if we navigated back, or keep it depending on UX design.
      // For now, let's keep the home page as 0 when returning.
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

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
        actions: [
          _buildReputationBadge(),
          //=================cambiar proximamente a perfil====================
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Historial()),
              );
            },
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const PantallaCarga()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Cerrar sesión',
          ),
          //==================================================================
        ],
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
            const SizedBox(height: 8),
            _buildStatusFilter(),
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
                  return _buildProblemCard(pub);
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

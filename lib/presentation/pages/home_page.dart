import 'package:braintask/presentation/pages/historial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/publicacion.dart';
import '../../data/repositories/publicaciones_repository.dart';
import 'publicaciones.dart';
import 'detalle_publicacion.dart';
import 'filtro.dart';
import 'help_support_page.dart';
import 'perfil_page.dart';
import '../../logic/providers/usuario_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  late final PublicacionesRepository _repository;
  List<Publicacion> _publicaciones = [];
  bool _cargando = true;
  String _filtroEstado = 'todos'; // 'todos', 'pendiente', 'resuelto'
  RealtimeChannel? _publicacionesChannel;
  RealtimeChannel? _solucionesChannel;
  final Set<int> _solucionesAceptadasNotificadas = {};

  String? _filtroFacultadSeleccionada;
  String? _filtroMateriaSeleccionada;
  String? _filtroTipoSeleccionado;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = PublicacionesRepository(Supabase.instance.client);
    _cargarPublicaciones();
    _suscribirCambiosEnTiempoReal();
  }

  @override
  void dispose() {
    final supabase = Supabase.instance.client;
    final publicacionesChannel = _publicacionesChannel;
    final solucionesChannel = _solucionesChannel;
    if (publicacionesChannel != null) {
      supabase.removeChannel(publicacionesChannel);
    }
    if (solucionesChannel != null) {
      supabase.removeChannel(solucionesChannel);
    }
    super.dispose();
  }

  void _suscribirCambiosEnTiempoReal() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    _publicacionesChannel = supabase
        .channel('public:publicaciones:home')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'publicaciones',
          callback: (_) {
            if (mounted) _cargarPublicaciones();
          },
        )
        .subscribe();

    if (userId == null) return;

    _solucionesChannel = supabase
        .channel('public:soluciones:home:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'soluciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'usuario_id',
            value: userId,
          ),
          callback: (payload) {
            final solucion = payload.newRecord;
            final idSolucion = solucion['id_solucion'];
            final fueAceptada = solucion['aceptada'] == true;
            if (!mounted || !fueAceptada || idSolucion is! int) return;
            if (!_solucionesAceptadasNotificadas.add(idSolucion)) return;

            _cargarPublicaciones();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tu solucion fue aceptada. Ejercicio resuelto.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        )
        .subscribe();
  }

  Future<void> _cargarPublicaciones() async {
    setState(() => _cargando = true);
    try {
      final data = await _repository.getPublicaciones(
        idMateria: _filtroMateriaSeleccionada,
        idFacultad: _filtroFacultadSeleccionada,
        tipo: _filtroTipoSeleccionado,
        search: _searchQuery,
      );

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

  List<Publicacion> get _publicacionesFiltradas {
    if (_filtroEstado == 'todos') {
      return _publicaciones;
    } else if (_filtroEstado == 'pendiente') {
      return _publicaciones.where((pub) => pub.estado != 'resuelto').toList();
    } else if (_filtroEstado == 'resuelto') {
      return _publicaciones.where((pub) => pub.estado == 'resuelto').toList();
    }
    return _publicaciones;
  }

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
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF007BFF)),
            onPressed: _mostrarFiltrosDialog,
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
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                      hintText: '¿Qué tema buscas hoy?',
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

  Widget _buildReputationBadge(int puntuacion) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(
              '$puntuacion pts',
              style: const TextStyle(
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
      {'valor': 'todos', 'label': 'Todos'},
      {'valor': 'pendiente', 'label': 'Pendientes'},
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

  Widget _buildInfoChip({
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _abrirDetallePublicacion(int publicacionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetallePublicacionPage(publicacionId: publicacionId),
      ),
    );
    _cargarPublicaciones();
  }

  Widget _buildProblemCard(Publicacion pub) {
    String descripcionPreview = (pub.descripcion ?? '').trim();
    if (descripcionPreview.length > 120) {
      descripcionPreview = '${descripcionPreview.substring(0, 120)}...';
    }
    if (descripcionPreview.isEmpty) {
      descripcionPreview = 'Sin descripción';
    }
    final estaResuelto = pub.estado == 'resuelto';
    final estadoLabel = estaResuelto ? 'Resuelto' : 'Pendiente';
    final estadoColor = estaResuelto ? const Color(0xFF2E7D32) : Colors.orange;
    final estadoBackground = estaResuelto
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final esMiPregunta = pub.autorId != null && pub.autorId == currentUserId;
    // Solo se muestra badge si es la pregunta del usuario actual

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _abrirDetallePublicacion(pub.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (esMiPregunta)
                                _buildInfoChip(
                                  label: 'Tu pregunta',
                                  color: const Color(0xFF1565C0),
                                  backgroundColor: const Color(0xFFE3F2FD),
                                ),
                              if (_filtroEstado == 'todos')
                                _buildInfoChip(
                                  label: estadoLabel,
                                  color: estadoColor,
                                  backgroundColor: estadoBackground,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
                                    pub.promedioDificultad?.toStringAsFixed(
                                          1,
                                        ) ??
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(descripcionPreview, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildHomeContent(BuildContext context) {
    final usuarioAsync = ref.watch(usuarioProvider);
    final publicacionesMostrar = _publicacionesFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Braintask',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          usuarioAsync.when(
            data: (usuario) => _buildReputationBadge(usuario.puntuacion),
            loading: () => const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _cargarPublicaciones();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              usuarioAsync.when(
                data: (usuario) => Text(
                  '¡Hola, ${usuario.nombre}! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const Text(
                  'Cargando...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                error: (_, __) => const Text(
                  '¡Hola! 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
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
              else if (publicacionesMostrar.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No hay publicaciones con este filtro.\n¡Sé el primero en publicar un ejercicio!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Column(
                  children: publicacionesMostrar.map((pub) {
                    return _buildProblemCard(pub);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(context),
      PublicarPage(
        onSubmitSuccess: () {
          setState(() {
            _currentIndex = 0;
          });
          _cargarPublicaciones();
        },
      ),
      const PerfilPage(),
      const HelpSupportPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
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

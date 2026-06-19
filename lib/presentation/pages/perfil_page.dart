import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/providers/usuario_provider.dart';
import '../../data/models/usuario_model.dart';
import '../../auth/login_page.dart';
import '../../logic/providers/notificaciones_provider.dart';
import 'help_support_page.dart';

class PerfilPage extends ConsumerStatefulWidget {
  const PerfilPage({super.key});

  @override
  ConsumerState<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends ConsumerState<PerfilPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _cedulaController;
  late TextEditingController _carnetController;

  int? _carreraIdSeleccionado;
  List<dynamic> _carreras = [];
  bool _guardando = false;
  bool _inicializado = false;
  String? _usuarioIdActual;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _cedulaController = TextEditingController();
    _carnetController = TextEditingController();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await Supabase.instance.client
          .from('carreras')
          .select('id, nombre')
          .order('nombre');
      if (mounted) setState(() => _carreras = data);
    } catch (e) {
      debugPrint('Error cargando carreras: $e');
    }
  }

  void _inicializarCampos(UsuarioModel usuario) {
    final haCambiadoUsuario = usuario.id != _usuarioIdActual;
    if (_inicializado && !haCambiadoUsuario) return;

    _nombreController.text = usuario.nombre;
    _apellidoController.text = usuario.apellido;
    _cedulaController.text = usuario.cedula;
    _carnetController.text = usuario.carnet;
    _carreraIdSeleccionado = usuario.carreraId;
    _usuarioIdActual = usuario.id;
    _inicializado = true;
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      await ref
          .read(usuarioProvider.notifier)
          .modificarPerfil(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            cedula: _cedulaController.text.trim(),
            carnet: _carnetController.text.trim(),
            carreraId: _carreraIdSeleccionado,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    ref.invalidate(usuarioProvider);
    ref.invalidate(notificacionesProvider);
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _abrirAyudaSoporte() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpSupportPage()),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _carnetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(usuarioProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: usuarioAsync.when(
        data: (usuario) {
          _inicializarCampos(usuario);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar puntos acumulados
                   // Panel de Estadísticas (Puntos y Reportes)
                    Row(
                      children: [
                        // Tarjeta de Puntos
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Puntos',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '${usuario.puntuacion} pts',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Tarjeta de Reportes (Solo lectura)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.report_problem, color: Colors.redAccent, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reportes',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        // 🚨 Asegúrate de tener este campo en tu UsuarioModel
                                        '${usuario.totalReportes}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),


                    const Text(
                      'Información personal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Cédula'),
                      validator: (v) =>
                          v!.length < 7 ? 'Mínimo 7 dígitos' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _carnetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Carnet'),
                      validator: (v) =>
                          v!.trim().length < 10 ? 'Mínimo 10 dígitos' : null,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Información académica',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _carreraIdSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Carrera Académica',
                      ),
                      items: _carreras.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c['id_carrera'] ?? c['id'],
                          child: Text(c['nombre_carrera'] ?? c['nombre'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _carreraIdSeleccionado = val),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 30),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _abrirAyudaSoporte,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Color(0xFF007BFF),
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ayuda y Soporte',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Preguntas frecuentes, pagos y contacto.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007BFF),
                          foregroundColor: Colors.white,
                        ),
                        child: _guardando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'GUARDAR CAMBIOS',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

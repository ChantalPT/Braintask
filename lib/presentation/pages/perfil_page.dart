import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../logic/providers/usuario_provider.dart';
import '../../data/models/usuario_model.dart';
import '../../auth/login_page.dart';

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
          .select('id, nombre') // Verifica si en BD es id/nombre o id_carrera/nombre_carrera
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
      await ref.read(usuarioProvider.notifier).modificarPerfil(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            cedula: _cedulaController.text.trim(),
            carnet: _carnetController.text.trim(),
            carreraId: _carreraIdSeleccionado,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green),
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
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _cerrarSesion)
        ],
      ),
      body: usuarioAsync.when(
        data: (usuario) {
          _inicializarCampos(usuario);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _cedulaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Cédula'),
                    validator: (v) => v!.length < 7 ? 'Mínimo 7 dígitos' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _carnetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Carnet'),
                    validator: (v) => v!.trim().length < 10 ? 'Mínimo 10 dígitos' : null,
                  ),
                  const SizedBox(height: 25),
                  const Text('Información académica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _carreraIdSeleccionado,
                    decoration: const InputDecoration(labelText: 'Carrera Académica'),
                    items: _carreras.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem<int>(
                        value: c['id_carrera'] ?? c['id'],
                        child: Text(c['nombre_carrera'] ?? c['nombre'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _carreraIdSeleccionado = val),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF)),
                      child: _guardando 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
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
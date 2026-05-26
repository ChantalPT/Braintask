import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  // Añadidos para supabase
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirmarPassword = true;
  bool _cargando = false;

  List<Map<String, dynamic>> _carreras = [];
  int? _carreraIdSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await Supabase.instance.client
          .from('carreras')
          .select('id, nombre')
          .order('nombre');
      setState(() {
        _carreras = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error cargando carreras: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _carnetController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cargando) return;

    setState(() => _cargando = true);
    try {
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user == null) {
        throw Exception('Error al crear usuario en autenticación');
      }

      //Se guardan los datos en la tabla usuario (supabase)
      await Supabase.instance.client.from('usuarios').insert({
        'auth_user_id': res.user!.id,
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'carnet': _carnetController.text.trim(),
        'carrera_id': _carreraIdSeleccionado,
        'correo': _correoController.text.trim(),
        'puntuacion': 0,
        'reputacion': 0,
        'total_calificaciones': 0,
        'reputacion_promedio': 0.0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Usuario registrado correctamente. Ya puedes iniciar sesión.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (error) {
      if (!mounted) return;
      String mensaje = 'Error al registrar. Intenta de nuevo.';

      if (error is PostgrestException) {
        if (error.message.contains('duplicate key')) {
          if (error.message.contains('cedula')) {
            mensaje = 'La cédula ya está registrada.';
          } else if (error.message.contains('carnet')) {
            mensaje = 'El carnet ya está registrado.';
          } else if (error.message.contains('correo')) {
            mensaje = 'El correo ya está en uso.';
          } else {
            mensaje = 'Error de datos duplicados. Revisa tus datos.';
          }
        } else if (error.message.contains('rate limit')) {
          mensaje =
              'Demasiados intentos. Espera un momento e intenta de nuevo.';
        }
      } else if (error is AuthException) {
        if (error.message.contains('rate limit')) {
          mensaje = 'Demasiados intentos de registro. Espera un poco.';
        } else if (error.message.contains('User already registered')) {
          mensaje = 'El correo ya está registrado. Inicia sesión.';
        } else {
          mensaje = error.message;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF007BFF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF007BFF), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Registro', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF007BFF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear cuenta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Regístrate para acceder a la plataforma y utilizar las funcionalidades académicas.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 26),

                // Campo Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: _inputDecoration(
                    label: 'Nombre',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),

                // Campo Apellido
                TextFormField(
                  controller: _apellidoController,
                  decoration: _inputDecoration(
                    label: 'Apellido',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu apellido'
                      : null,
                ),
                const SizedBox(height: 16),

                // Campo Cédula
                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(
                    label: 'Cédula',
                    icon: Icons.badge,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu cédula';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Solo números';
                    }
                    if (value.trim().length < 7) {
                      return 'Mínimo 7 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Carnet
                TextFormField(
                  controller: _carnetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(
                    label: 'Carnet',
                    icon: Icons.credit_card,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu carnet';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Solo números';
                    }
                    if (value.trim().length < 10) {
                      return 'Mínimo 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _carreraIdSeleccionado,
                  decoration: _inputDecoration(
                    label: 'Carrera',
                    icon: Icons.school,
                  ),
                  items: _carreras.map((carrera) {
                    return DropdownMenuItem<int>(
                      value: carrera['id'],
                      child: Text(carrera['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _carreraIdSeleccionado = value),
                  validator: (value) =>
                      value == null ? 'Selecciona una carrera' : null,
                ),
                const SizedBox(height: 16),

                // Campo Correo
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  decoration: _inputDecoration(
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Confirmar Contraseña
                TextFormField(
                  controller: _confirmarPasswordController,
                  obscureText: _ocultarConfirmarPassword,
                  decoration: _inputDecoration(
                    label: 'Confirmar contraseña',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmarPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                        () => _ocultarConfirmarPassword =
                            !_ocultarConfirmarPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Botón Registrarse (con estado de carga)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        color: Color(0xFF007BFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> {
  final _supabase = Supabase.instance.client;
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _puntosController = TextEditingController();

  File? _archivoSeleccionado;
  String? _nombreArchivo;
  bool _esPdf = false;

  List<dynamic> _facultades = [];
  List<dynamic> _materias = [];

  String? _facultadSeleccionada;
  String? _materiaSeleccionada;
  String? _tipoActividad;

  @override
  void initState() {
    super.initState();
    _cargarFacultades();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _puntosController.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _cargarFacultades() async {
    final data = await _supabase
        .from('facultades')
        .select()
        .order('nombre_facultad');
    setState(() => _facultades = data);
  }

  Future<void> _cargarMaterias(String idFacultad) async {
    final data = await _supabase
        .from('materias')
        .select()
        .eq('id_facultad', idFacultad)
        .order('nombre_materias');
    setState(() {
      _materias = data;
      _materiaSeleccionada = null;
    });
  }

  Future<void> _seleccionarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _archivoSeleccionado = File(result.files.single.path!);
        _nombreArchivo = result.files.single.name;
        _esPdf = _nombreArchivo!.toLowerCase().endsWith('.pdf');
      });
    }
  }

  Future<void> _subirPublicacion() async {
    if (_materiaSeleccionada == null) {
      _mostrarError("Debes seleccionar una materia");
      return;
    }

    if (_tituloController.text.isEmpty) {
      _mostrarError("Debes escribir un título");
      return;
    }

    final descripcion = _descripcionController.text.trim();
    if (descripcion.length < 20) {
      _mostrarError("La descripción debe tener al menos 20 caracteres");
      return;
    }

    final puntosTexto = _puntosController.text.trim();
    if (puntosTexto.isEmpty) {
      _mostrarError("Debes asignar una cantidad de puntos");
      return;
    }
    final puntos = int.tryParse(puntosTexto);
    if (puntos == null) {
      _mostrarError("Los puntos deben ser un número válido");
      return;
    }

    if (_archivoSeleccionado == null) {
      _mostrarError("Debes adjuntar un archivo (JPG, PNG o PDF)");
      return;
    }

    const int maxSizeMB = 10;
    final sizeInBytes = _archivoSeleccionado!.lengthSync();
    if (sizeInBytes > maxSizeMB * 1024 * 1024) {
      _mostrarError("El archivo no puede superar los $maxSizeMB MB");
      setState(() => _archivoSeleccionado = null);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final String extension = _esPdf ? 'pdf' : 'jpg';
      final String nombreUnico =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage
          .from('ejercicios')
          .upload(
            nombreUnico,
            _archivoSeleccionado!,
            fileOptions: FileOptions(
              contentType: _esPdf ? 'application/pdf' : 'image/jpeg',
            ),
          );

      final String urlPublica = _supabase.storage
          .from('ejercicios')
          .getPublicUrl(nombreUnico);

      await _supabase.from('publicaciones').insert({
        'titulo': _tituloController.text,
        'descripcion': descripcion,
        'id_materia': int.parse(_materiaSeleccionada!),
        'tipo': _tipoActividad,
        'foto_url': urlPublica,
        'puntuacion': puntos,
        'autor_id': _supabase.auth.currentUser?.id,
      });

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Publicado con éxito!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _mostrarError("Error al subir: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nueva Publicación",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF007BFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Académica",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // esto es para las facultades
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Facultad",
                border: OutlineInputBorder(),
              ),
              value: _facultadSeleccionada,
              items: _facultades
                  .map(
                    (f) => DropdownMenuItem(
                      value: f['id_facultad'].toString(),
                      child: Text(f['nombre_facultad']),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() => _facultadSeleccionada = val);
                if (val != null) _cargarMaterias(val);
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Materia",
                      border: OutlineInputBorder(),
                    ),
                    value: _materiaSeleccionada,
                    items: _materias
                        .map(
                          (m) => DropdownMenuItem(
                            value: m['id_materias'].toString(),
                            child: Text(m['nombre_materias']),
                          ),
                        )
                        .toList(),
                    onChanged: _facultadSeleccionada == null
                        ? null
                        : (val) => setState(() => _materiaSeleccionada = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Actividad",
                      border: OutlineInputBorder(),
                    ),
                    value: _tipoActividad,
                    items: ['Parcial', 'Tarea', 'Quiz', 'Proyecto']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _tipoActividad = val),
                  ),
                ),
                const SizedBox(width: 15),

                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _puntosController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Puntos",
                      hintText: "100",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Detalles del Ejercicio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                hintText: "Título descriptivo",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Añade tu problema específico",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _seleccionarArchivo,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _archivoSeleccionado != null
                    ? (_esPdf
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  size: 60,
                                  color: Colors.red,
                                ),
                                Text(
                                  _nombreArchivo ?? "",
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _archivoSeleccionado!,
                                fit: BoxFit.cover,
                              ),
                            ))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          Text(
                            "Subir Foto o PDF",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _subirPublicacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "SUBIR PUBLICACIÓN",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FiltroSheet extends StatefulWidget {
  final String? initialFacultad;
  final String? initialMateria;
  final String? initialTipo;
  final Function(String?, String?, String?) onApply;
  final VoidCallback onClear;

  const FiltroSheet({
    super.key,
    this.initialFacultad,
    this.initialMateria,
    this.initialTipo,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<FiltroSheet> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _facultades = [];
  List<dynamic> _materias = [];
  String? _filtroFacultadSeleccionada;
  String? _filtroMateriaSeleccionada;
  String? _filtroTipoSeleccionado;

  @override
  void initState() {
    super.initState();
    _filtroFacultadSeleccionada = widget.initialFacultad;
    _filtroMateriaSeleccionada = widget.initialMateria;
    _filtroTipoSeleccionado = widget.initialTipo;
    _cargarFacultades();
    if (_filtroFacultadSeleccionada != null) {
      _cargarMaterias(_filtroFacultadSeleccionada!);
    }
  }

  Future<void> _cargarFacultades() async {
    final data = await _supabase
        .from('facultades')
        .select()
        .order('nombre_facultad');
    if (mounted) {
      setState(() => _facultades = data);
    }
  }

  Future<void> _cargarMaterias(String idFacultad) async {
    final data = await _supabase
        .from('materias')
        .select()
        .eq('id_facultad', idFacultad)
        .order('nombre_materias');
    if (mounted) {
      setState(() {
        _materias = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filtrar por carrera/materia",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Facultad / Carrera",
              border: OutlineInputBorder(),
            ),
            value: _filtroFacultadSeleccionada,
            items: _facultades
                .map(
                  (f) => DropdownMenuItem(
                    value: f['id_facultad'].toString(),
                    child: Text(f['nombre_facultad']),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _filtroFacultadSeleccionada = val;
                _filtroMateriaSeleccionada = null;
              });
              if (val != null) {
                _cargarMaterias(val);
              }
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Materia",
              border: OutlineInputBorder(),
            ),
            value: _filtroMateriaSeleccionada,
            items: _materias
                .map(
                  (m) => DropdownMenuItem(
                    value: m['id_materias'].toString(),
                    child: Text(m['nombre_materias']),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _filtroMateriaSeleccionada = val;
              });
            },
            disabledHint: const Text("Selecciona primero una facultad"),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Tipo de Actividad",
              border: OutlineInputBorder(),
            ),
            value: _filtroTipoSeleccionado,
            items: [
              'Parcial',
              'Tarea',
              'Quiz',
              'Proyecto',
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) {
              setState(() {
                _filtroTipoSeleccionado = val;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Limpiar Filtros'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _filtroFacultadSeleccionada,
                      _filtroMateriaSeleccionada,
                      _filtroTipoSeleccionado,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

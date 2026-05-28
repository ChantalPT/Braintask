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
  List<dynamic> _materias = [];
  String? _filtroMateriaSeleccionada;
  String? _filtroTipoSeleccionado;

  @override
  void initState() {
    super.initState();
    _filtroMateriaSeleccionada = widget.initialMateria;
    _filtroTipoSeleccionado = widget.initialTipo;
    _cargarMaterias();
  }

  Future<void> _cargarMaterias() async {
    final data = await _supabase
        .from('materias')
        .select()
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
            "Filtrar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Materia",
              border: OutlineInputBorder(),
            ),
            initialValue: _filtroMateriaSeleccionada, // ← corregido
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
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Tipo de Actividad",
              border: OutlineInputBorder(),
            ),
            initialValue: _filtroTipoSeleccionado, // ← corregido
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
                      null, // facultad ya no se usa
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

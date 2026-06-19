import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foro_pregunta.dart';
import '../../logic/providers/foro_provider.dart';
import 'detalle_publicacion.dart';

class ForoPage extends ConsumerWidget {
  // 💡 SE QUITÓ LA VARIABLE DE AQUÍ PARA EVITAR ERRORES DE CONSTRUCTOR
  const ForoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preguntasAsync = ref.watch(foroPreguntasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        title: const Text('Foro', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildSearchBar(ref),
          Expanded(
            child: preguntasAsync.when(
              data: (preguntas) {
                if (preguntas.isEmpty) {
                  return const Center(
                    child: Text('No hay preguntas con ese termino.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(foroPreguntasProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: preguntas.length,
                    itemBuilder: (context, index) {
                      final p = preguntas[index];
                      return _buildPreguntaCard(context, p);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  ref.read(foroPreguntasProvider.notifier).search(value);
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar pregunta',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntaCard(BuildContext context, ForoPregunta pregunta) {
    final bool bajoRevision = pregunta.estado == 'en_revision';

    return GestureDetector(
      onTap: bajoRevision 
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta publicación se encuentra suspendida temporalmente bajo revisión.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetallePublicacionPage(publicacionId: pregunta.id),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bajoRevision ? Colors.redAccent : Colors.grey.shade200,
            width: bajoRevision ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bajoRevision)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'CONTENIDO BAJO REVISIÓN POR REPORTES',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publicado por ${pregunta.autorNombre} - ${pregunta.tiempo.day}/${pregunta.tiempo.month}/${pregunta.tiempo.year}',
                          style: TextStyle(
                            color: bajoRevision ? Colors.red.shade700 : Colors.grey.shade600, 
                            fontSize: 12
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pregunta.titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: bajoRevision ? Colors.grey : Colors.black,
                            decoration: bajoRevision ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pregunta.descripcion.length > 80
                              ? '${pregunta.descripcion.substring(0, 80)}...'
                              : pregunta.descripcion,
                          style: TextStyle(
                            color: bajoRevision ? Colors.grey.shade400 : Colors.black87
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pregunta.respuestasCount} respuestas',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${pregunta.puntosBase} pts base',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${pregunta.votos} votos',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
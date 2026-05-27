import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foro_pregunta.dart';
import '../../logic/providers/foro_provider.dart';
import 'detalle_foro_pregunta.dart';

class ForoPage extends ConsumerWidget {
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleForoPreguntaPage(pregunta: pregunta),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publicado por ${pregunta.autorNombre} - ${pregunta.tiempo.day}/${pregunta.tiempo.month}/${pregunta.tiempo.year}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pregunta.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pregunta.descripcion.length > 80
                        ? '${pregunta.descripcion.substring(0, 80)}...'
                        : pregunta.descripcion,
                    style: const TextStyle(color: Colors.black87),
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
    );
  }
}

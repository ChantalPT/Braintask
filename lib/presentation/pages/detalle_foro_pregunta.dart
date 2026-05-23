import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foro_pregunta.dart';
import '../../logic/providers/foro_respuestas_provider.dart';
import '../../logic/providers/foro_provider.dart';

class DetalleForoPreguntaPage extends ConsumerStatefulWidget {
  final ForoPregunta pregunta;

  const DetalleForoPreguntaPage({super.key, required this.pregunta});

  @override
  ConsumerState<DetalleForoPreguntaPage> createState() =>
      _DetalleForoPreguntaPageState();
}

class _DetalleForoPreguntaPageState
    extends ConsumerState<DetalleForoPreguntaPage> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Buscar la pregunta actualizada en el estado del proveedor
    final listaPreguntas = ref.watch(foroPreguntasProvider).value ?? [];
    final currentPregunta = listaPreguntas.firstWhere(
      (p) => p.id == widget.pregunta.id,
      orElse: () => widget.pregunta,
    );

    final respuestasAsync = ref.watch(
      foroRespuestasProvider(currentPregunta.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pregunta', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreguntaCompleta(context, currentPregunta),
                  const Divider(height: 32),
                  const Text(
                    'Respuestas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  respuestasAsync.when(
                    data: (respuestas) {
                      if (respuestas.isEmpty) {
                        return const Center(
                          child: Text('Sé el primero en responder.'),
                        );
                      }
                      return Column(
                        children: respuestas
                            .map((r) => _buildRespuestaCard(context, ref, r))
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ),
          _buildReplyBox(context, currentPregunta),
        ],
      ),
    );
  }

  Widget _buildPreguntaCompleta(
    BuildContext context,
    ForoPregunta preguntaActual,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicado por ${preguntaActual.autorNombre} • ${preguntaActual.tiempo.day}/${preguntaActual.tiempo.month}/${preguntaActual.tiempo.year}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            preguntaActual.titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            preguntaActual.descripcion,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Botones de votar para la pregunta
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up,
                  color: preguntaActual.userVote == 1
                      ? Colors.blue
                      : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await ref
                        .read(foroPreguntasProvider.notifier)
                        .votar(preguntaActual.id, true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al votar: $e')),
                      );
                    }
                  }
                },
              ),
              Text(
                '${preguntaActual.votos}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.thumb_down,
                  color: preguntaActual.userVote == -1
                      ? Colors.red
                      : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await ref
                        .read(foroPreguntasProvider.notifier)
                        .votar(preguntaActual.id, false);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al votar: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRespuestaCard(BuildContext context, WidgetRef ref, respuesta) {
    return Container(
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
          Column(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.thumb_up,
                  color: respuesta.userVote == 1 ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  ref
                      .read(foroRespuestasProvider(widget.pregunta.id).notifier)
                      .votar(respuesta.id, true);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${respuesta.votos}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.thumb_down,
                  color: respuesta.userVote == -1 ? Colors.red : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  ref
                      .read(foroRespuestasProvider(widget.pregunta.id).notifier)
                      .votar(respuesta.id, false);
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${respuesta.autorNombre} • ${respuesta.tiempo.day}/${respuesta.tiempo.month}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  respuesta.contenido,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBox(BuildContext context, ForoPregunta preguntaActual) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: 'Añadir una respuesta...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF007BFF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () async {
                  final text = _replyController.text;
                  if (text.trim().isNotEmpty) {
                    try {
                      await ref
                          .read(
                            foroRespuestasProvider(preguntaActual.id).notifier,
                          )
                          .responder(preguntaActual.id, text);
                      _replyController.clear();
                      if (context.mounted) {
                        FocusScope.of(context).unfocus();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al enviar: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

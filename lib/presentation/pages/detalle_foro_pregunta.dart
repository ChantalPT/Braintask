import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/foro_pregunta.dart';
import '../../data/models/foro_respuesta.dart'; // Importante para el tipo de dato
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
        title: const Text('Ejercicio y Respuestas', style: TextStyle(color: Colors.black)),
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
                  // ENUNCIADO DE LA PREGUNTA
                  _buildPreguntaCompleta(context, currentPregunta),
                  const Divider(height: 32),
                  const Text(
                    'Soluciones Propuestas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // LISTA DE RESPUESTAS CON ESTRELLAS
                  respuestasAsync.when(
                    data: (respuestas) {
                      if (respuestas.isEmpty) {
                        return const Center(
                          child: Text('Sé el primero en subir una solución.'),
                        );
                      }
                      return Column(
                        children: respuestas
                            .map((r) => _buildRespuestaCard(context, ref, r, currentPregunta.votos))
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
          
          // CAJA PARA ESCRIBIR UNA NUEVA RESPUESTA
          _buildReplyBox(context, currentPregunta),
        ],
      ),
    );
  }

  Widget _buildPreguntaCompleta(BuildContext context, ForoPregunta preguntaActual) {
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
          // Botones de votar para el ENUNCIADO (Se mantienen los likes aquí)
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up,
                  color: preguntaActual.userVote == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await ref.read(foroPreguntasProvider.notifier).votar(preguntaActual.id, true);
                  } catch (e) {}
                },
              ),
              Text(
                '${preguntaActual.votos} pts base',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
              ),
              IconButton(
                icon: Icon(
                  Icons.thumb_down,
                  color: preguntaActual.userVote == -1 ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await ref.read(foroPreguntasProvider.notifier).votar(preguntaActual.id, false);
                  } catch (e) {}
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TARJETA DE RESPUESTA MODIFICADA (SISTEMA DE ESTRELLAS)
  Widget _buildRespuestaCard(BuildContext context, WidgetRef ref, ForoRespuesta respuesta, int puntosBase) {
    // Calculamos los puntos ganados basados en el promedio de estrellas
    int puntosReales = 0;
    if (respuesta.totalVotos > 0) {
      puntosReales = (puntosBase * (respuesta.promedioEstrellas / 5)).round();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Autor y Puntos Ganados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${respuesta.autorNombre} • ${respuesta.tiempo.day}/${respuesta.tiempo.month}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: respuesta.totalVotos == 0 ? Colors.grey.shade200 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  respuesta.totalVotos == 0 ? 'Pendiente' : 'Gana $puntosReales pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: respuesta.totalVotos == 0 ? Colors.grey.shade700 : Colors.green.shade800
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // El texto de la respuesta
          Text(
            respuesta.contenido,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          
          const Divider(height: 24),
          
          // Pie: Las 5 Estrellas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                respuesta.totalVotos == 0
                    ? '0 votos'
                    : '${respuesta.promedioEstrellas.toStringAsFixed(1)} ★ (${respuesta.totalVotos} votos)',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  // La estrella se pinta si el usuario ya votó por ese valor, 
                  // o si nadie ha votado, se pinta según el promedio general.
                  final isFilled = (respuesta.userVote > 0 && starValue <= respuesta.userVote) ||
                                   (respuesta.userVote == 0 && starValue <= respuesta.promedioEstrellas.round());
                  
                  return InkWell(
                    onTap: () {
                      ref.read(foroRespuestasProvider(widget.pregunta.id).notifier).calificar(respuesta.id, starValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        isFilled ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 26,
                      ),
                    ),
                  );
                }),
              ),
            ],
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
                    hintText: 'Añadir una solución...',
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
                          .read(foroRespuestasProvider(preguntaActual.id).notifier)
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
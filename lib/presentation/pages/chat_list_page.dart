import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/chat_provider.dart';
import '../../data/models/conversacion_model.dart';
import 'chat_detail_page.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversacionesAsync = ref.watch(conversacionesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: conversacionesAsync.when(
        data: (conversaciones) {
          if (conversaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin conversaciones',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca "Contactar" en un ejercicio\npara iniciar una conversación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(conversacionesProvider.notifier).refresh(),
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: conversaciones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _ConversacionCard(
                  conversacion: conversaciones[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          otroUserId: conversaciones[index].otroUserId,
                          otroNombre: conversaciones[index].otroNombre,
                          otroApellido: conversaciones[index].otroApellido,
                        ),
                      ),
                    ).then((_) =>
                        ref.read(conversacionesProvider.notifier).refresh());
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error al cargar mensajes:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(conversacionesProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversacionCard extends StatelessWidget {
  final ConversacionModel conversacion;
  final VoidCallback onTap;

  const _ConversacionCard({
    required this.conversacion,
    required this.onTap,
  });

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return '';
    final now = DateTime.now();
    final local = fecha.toLocal();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Ayer';
    return '${local.day}/${local.month}';
  }

  @override
  Widget build(BuildContext context) {
    final tieneNoLeidos = conversacion.mensajesNoLeidos > 0;
    final nombre =
        '${conversacion.otroNombre} ${conversacion.otroApellido}'.trim();

    return Material(
      color: tieneNoLeidos ? const Color(0xFFEEF4FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tieneNoLeidos
                  ? const Color(0xFF007BFF).withValues(alpha: 0.25)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFF007BFF).withValues(alpha: 0.12),
                child: const Icon(Icons.person,
                    color: Color(0xFF007BFF), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: tieneNoLeidos
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatFecha(conversacion.ultimaFecha),
                          style: TextStyle(
                            fontSize: 11,
                            color: tieneNoLeidos
                                ? const Color(0xFF007BFF)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (conversacion.ultimoEsMio)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.done,
                                size: 14, color: Colors.grey),
                          ),
                        Expanded(
                          child: Text(
                            conversacion.ultimoMensaje ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: tieneNoLeidos
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: tieneNoLeidos
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tieneNoLeidos)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF007BFF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conversacion.mensajesNoLeidos}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

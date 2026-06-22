import 'package:braintask/presentation/pages/detalle_publicacion.dart';
import 'package:braintask/presentation/pages/chat_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/notificaciones_provider.dart';

class NotificacionesPage extends ConsumerWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          notificacionesAsync.whenOrNull(
                data: (list) {
                  final hayNoLeidas = list.any((n) => !n.leida);
                  if (!hayNoLeidas) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      ref
                          .read(notificacionesProvider.notifier)
                          .marcarTodasComoLeidas();
                    },
                    child: const Text(
                      'Marcar todas',
                      style: TextStyle(color: Color(0xFF007BFF)),
                    ),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificacionesAsync.when(
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aquí aparecerán las notificaciones\ncuando alguien acepte tu solución.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificacionesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: notificaciones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = notificaciones[index];
                return _NotificacionCard(
                  notificacion: notif,
                  onTap: () {
                    // 1. Marcar como leída si no lo está
                    if (!notif.leida) {
                      ref
                          .read(notificacionesProvider.notifier)
                          .marcarComoLeida(notif.id);
                    }

                    // 2. Navegar según el tipo de notificación
                    if (notif.tipo == 'nuevo_mensaje') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatListPage(),
                        ),
                      );
                    } else if (notif.idPublicacion != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetallePublicacionPage(
                            publicacionId: notif.idPublicacion!,
                          ),
                        ),
                      );
                    }
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
                'Error al cargar notificaciones:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(notificacionesProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  final NotificacionModel notificacion;
  final VoidCallback onTap;

  const _NotificacionCard({required this.notificacion, required this.onTap});

  IconData _iconForTipo(String? tipo) {
    switch (tipo) {
      case 'solucion_aceptada':
        return Icons.check_circle;
      case 'nueva_solucion':
        return Icons.assignment;
      case 'nuevo_comentario':
        return Icons.comment;
      case 'pago':
        return Icons.payment;
      case 'nuevo_mensaje':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForTipo(String? tipo) {
    switch (tipo) {
      case 'solucion_aceptada':
        return Colors.green;
      case 'nueva_solucion':
        return Colors.blue;
      case 'nuevo_comentario':
        return Colors.purple;
      case 'pago':
        return Colors.orange;
      case 'nuevo_mensaje':
        return const Color(0xFF007BFF);
      default:
        return const Color(0xFF007BFF);
    }
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return '';
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notificacion.leida;
    final iconColor = _colorForTipo(notificacion.tipo);

    return Material(
      color: isUnread ? const Color(0xFFEEF4FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF007BFF).withValues(alpha: 0.25)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForTipo(notificacion.tipo),
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFecha(notificacion.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF007BFF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

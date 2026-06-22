import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/conversacion_model.dart';
import '../../data/repositories/chat_repository.dart';

// ── Lista de conversaciones con tiempo real ──────────────────────────────────

class ConversacionesNotifier extends AsyncNotifier<List<ConversacionModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<ConversacionModel>> build() async {
    final supabase = Supabase.instance.client;
    final authId = supabase.auth.currentUser?.id;
    if (authId == null) return [];

    final repo = ChatRepository(supabase);
    final miCedula = await repo.getCedula(authId);
    if (miCedula == null) return [];

    _channel = supabase
        .channel('conversaciones:$miCedula')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'destinatario_cedula',
            value: miCedula,
          ),
          callback: (_) async {
            state = AsyncData(await repo.fetchConversaciones(miCedula));
          },
        )
        .subscribe();

    ref.onDispose(() {
      final ch = _channel;
      if (ch != null) supabase.removeChannel(ch);
    });

    return repo.fetchConversaciones(miCedula);
  }

  Future<void> refresh() async {
    final supabase = Supabase.instance.client;
    final authId = supabase.auth.currentUser?.id;
    if (authId == null) return;
    final repo = ChatRepository(supabase);
    final miCedula = await repo.getCedula(authId);
    if (miCedula == null) return;
    state = AsyncData(await repo.fetchConversaciones(miCedula));
  }
}

final conversacionesProvider =
    AsyncNotifierProvider<ConversacionesNotifier, List<ConversacionModel>>(
        ConversacionesNotifier.new);

// ── Total de mensajes no leídos (para badge en nav) ─────────────────────────

final unreadMensajesCountProvider = Provider<int>((ref) {
  final conversaciones = ref.watch(conversacionesProvider);
  return conversaciones.whenOrNull(
        data: (list) =>
            list.fold<int>(0, (sum, c) => sum + c.mensajesNoLeidos),
      ) ??
      0;
});

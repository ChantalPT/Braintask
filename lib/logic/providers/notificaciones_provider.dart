import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a single notification row
class NotificacionModel {
  final int id;
  final String usuarioId;
  final String mensaje;
  final bool leida;
  final DateTime? createdAt;
  final String? tipo;

  NotificacionModel({
    required this.id,
    required this.usuarioId,
    required this.mensaje,
    required this.leida,
    this.createdAt,
    this.tipo,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int,
      usuarioId: json['usuario_id']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      leida: json['leida'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      tipo: json['tipo']?.toString(),
    );
  }

  NotificacionModel copyWith({bool? leida}) {
    return NotificacionModel(
      id: id,
      usuarioId: usuarioId,
      mensaje: mensaje,
      leida: leida ?? this.leida,
      createdAt: createdAt,
      tipo: tipo,
    );
  }
}

/// Notifier that holds the list of notifications and handles real-time updates
class NotificacionesNotifier extends AsyncNotifier<List<NotificacionModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<NotificacionModel>> build() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Subscribe to real-time changes on notificaciones for this user
    _channel = supabase
        .channel('public:notificaciones:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'usuario_id',
            value: userId,
          ),
          callback: (_) async {
            final updated = await _fetchNotificaciones(userId);
            state = AsyncData(updated);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notificaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'usuario_id',
            value: userId,
          ),
          callback: (_) async {
            final updated = await _fetchNotificaciones(userId);
            state = AsyncData(updated);
          },
        )
        .subscribe();

    ref.onDispose(() {
      final channel = _channel;
      if (channel != null) {
        supabase.removeChannel(channel);
      }
    });

    return _fetchNotificaciones(userId);
  }

  Future<List<NotificacionModel>> _fetchNotificaciones(String userId) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('notificaciones')
        .select()
        .eq('usuario_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarComoLeida(int id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('notificaciones').update({'leida': true}).eq('id', id);

    // Update local state immediately
    state = state.whenData(
      (list) =>
          list.map((n) => n.id == id ? n.copyWith(leida: true) : n).toList(),
    );
  }

  Future<void> marcarTodasComoLeidas() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('notificaciones')
        .update({'leida': true})
        .eq('usuario_id', userId)
        .eq('leida', false);

    state = state.whenData(
      (list) => list.map((n) => n.copyWith(leida: true)).toList(),
    );
  }

  Future<void> refresh() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = AsyncData(await _fetchNotificaciones(userId));
  }
}

final notificacionesProvider =
    AsyncNotifierProvider<NotificacionesNotifier, List<NotificacionModel>>(
      NotificacionesNotifier.new,
    );

/// Derived provider: count of unread notifications
final unreadNotificacionesCountProvider = Provider<int>((ref) {
  final notificaciones = ref.watch(notificacionesProvider);
  return notificaciones.whenOrNull(
        data: (list) => list.where((n) => !n.leida).length,
      ) ??
      0;
});

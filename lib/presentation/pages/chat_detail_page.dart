import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/mensaje_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../logic/providers/chat_provider.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String otroUserId;
  final String otroNombre;
  final String otroApellido;

  const ChatDetailPage({
    super.key,
    required this.otroUserId,
    required this.otroNombre,
    required this.otroApellido,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _supabase = Supabase.instance.client;
  late final ChatRepository _repo;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MensajeModel> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;

  int? _miCedula;
  int? _otraCedula;
  String _miNombre = '';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository(_supabase);
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    final ch = _channel;
    if (ch != null) _supabase.removeChannel(ch);
    super.dispose();
  }

  Future<void> _init() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return;

    // Resolver cédulas y nombre propio
    final myCedulaFuture = _repo.getCedula(authId);
    final otraCedulaFuture = _repo.getCedula(widget.otroUserId);
    final userDataFuture = _supabase
        .from('usuarios')
        .select('nombre, apellido')
        .eq('auth_user_id', authId)
        .maybeSingle();

    _miCedula = await myCedulaFuture;
    _otraCedula = await otraCedulaFuture;
    final userData = await userDataFuture;
    _miNombre = userData != null
        ? '${userData['nombre']} ${userData['apellido']}'
        : 'Un usuario';

    if (_miCedula == null || _otraCedula == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    await _cargarMensajes();
    _suscribir();
  }

  Future<void> _cargarMensajes() async {
    if (_miCedula == null || _otraCedula == null) return;
    try {
      final lista = await _repo.fetchMensajes(_miCedula!, _otraCedula!);
      await _repo.marcarLeidos(_otraCedula!, _miCedula!);
      if (mounted) {
        setState(() {
          _mensajes = lista;
          _cargando = false;
        });
        _scrollAlFinal();
        ref.read(conversacionesProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _suscribir() {
    if (_miCedula == null || _otraCedula == null) return;
    _channel = _supabase
        .channel('chat_detail:${_miCedula}_$_otraCedula')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (_) async {
            if (!mounted) return;
            final lista =
                await _repo.fetchMensajes(_miCedula!, _otraCedula!);
            await _repo.marcarLeidos(_otraCedula!, _miCedula!);
            if (mounted) {
              setState(() => _mensajes = lista);
              _scrollAlFinal();
              ref.read(conversacionesProvider.notifier).refresh();
            }
          },
        )
        .subscribe();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _miCedula == null || _otraCedula == null || _enviando) {
      return;
    }

    setState(() => _enviando = true);
    _controller.clear();
    try {
      await _repo.enviarMensaje(
        remitenteCedula: _miCedula!,
        destinatarioCedula: _otraCedula!,
        contenido: texto,
        emisorNombre: _miNombre,
      );
      final lista = await _repo.fetchMensajes(_miCedula!, _otraCedula!);
      if (mounted) {
        setState(() => _mensajes = lista);
        _scrollAlFinal();
        ref.read(conversacionesProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto =
        '${widget.otroNombre} ${widget.otroApellido}'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  const Color(0xFF007BFF).withValues(alpha: 0.15),
              child: const Icon(Icons.person,
                  size: 20, color: Color(0xFF007BFF)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nombreCompleto,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 60,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Inicia la conversación',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, i) =>
                            _buildBurbuja(_mensajes[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBurbuja(MensajeModel msg) {
    final esMio = msg.remitenteCedula == _miCedula;
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: esMio ? const Color(0xFF007BFF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esMio ? 16 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.contenido,
              style: TextStyle(
                color: esMio ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatHora(msg.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: esMio
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _enviar(),
              ),
            ),
            const SizedBox(width: 8),
            _enviando
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : Material(
                    color: const Color(0xFF007BFF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _enviar,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.send,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatHora(DateTime? fecha) {
    if (fecha == null) return '';
    final local = fecha.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inDays == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Ayer';
    return '${local.day}/${local.month}';
  }
}

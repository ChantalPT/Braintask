import 'dart:async';

import 'package:braintask/auth/reset_password_page.dart';
import 'package:braintask/presentation/pages/pantalla_carga.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wxswmywnphpsrbzpwojv.supabase.co',
    anonKey: 'sb_publishable_take9BmJ8fcWjshpIoMjZQ_MY0JMkLZ',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    if (_esUrlWebRecuperacion(Uri.base)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirPantallaRestablecer();
      });
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event != AuthChangeEvent.passwordRecovery) return;

      _abrirPantallaRestablecer();
    });
    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!_esEnlaceRecuperacion(uri)) return;
      Future.delayed(
        const Duration(milliseconds: 500),
        _abrirPantallaRestablecer,
      );
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  bool _esEnlaceRecuperacion(Uri uri) {
    return uri.scheme == 'braintask' && uri.host == 'reset-password';
  }

  bool _esUrlWebRecuperacion(Uri uri) {
    if (!kIsWeb) return false;

    final url = uri.toString();
    return url.contains('type=recovery') ||
        url.contains('type%3Drecovery') ||
        url.contains('PASSWORD_RECOVERY');
  }

  void _abrirPantallaRestablecer() {
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Braintask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      //home: HomePage(),
      home: const PantallaCarga(),
    );
  }
}

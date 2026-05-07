import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart'; // 1. AGREGA ESTA LÍNEA (Importante)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Conexión con tus llaves
  await Supabase.initialize(
    url: 'https://wxswmywnphpsrbzpwojv.supabase.co', 
    anonKey: 'sb_publishable_take9BmJ8fcWjshpIoMjZQ_MY0JMkLZ', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braintask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Cambié a azul para que combine
        useMaterial3: true,
      ),
      // 2. CAMBIA ESTO: De MyHomePage() a HomePage()
      home: const HomePage(), 
    );
  }
}
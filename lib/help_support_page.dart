import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Ayuda y Soporte'),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '¿Cómo podemos ayudarte?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Encuentra respuestas rápidas o contacta al equipo de soporte.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              _HelpOption(
                icon: CupertinoIcons.question_circle,
                title: 'Preguntas frecuentes',
                subtitle: 'Consulta dudas comunes sobre la plataforma.',
              ),

              _HelpOption(
                icon: CupertinoIcons.creditcard,
                title: 'Problemas con pagos',
                subtitle: 'Reporta inconvenientes con pagos o recompensas.',
              ),

              _HelpOption(
                icon: CupertinoIcons.exclamationmark_triangle,
                title: 'Reportar un problema',
                subtitle: 'Informa errores o fallas dentro de la app.',
              ),

              _HelpOption(
                icon: CupertinoIcons.chat_bubble_2,
                title: 'Contactar soporte',
                subtitle: 'Comunícate con el equipo administrador.',
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Información de contacto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      '📧 soporte@braintask.com',
                      style: TextStyle(fontSize: 13),
                    ),

                    SizedBox(height: 8),

                    Text('📞 +58 412-0000000', style: TextStyle(fontSize: 13)),

                    SizedBox(height: 8),

                    Text(
                      '🕒 Lunes a Viernes - 8:00 AM a 5:00 PM',
                      style: TextStyle(fontSize: 13),
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

class _HelpOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007BFF), size: 30),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Icon(
            CupertinoIcons.chevron_right,
            color: Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
  }
}

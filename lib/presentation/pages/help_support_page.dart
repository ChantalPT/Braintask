import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  void _openDetailPage(BuildContext context, String title, List<String> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpDetailPage(title: title, items: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: Colors.white, decoration: TextDecoration.none),
        ),
        backgroundColor: const Color(0xFF007BFF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            '¿Cómo podemos ayudarte?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encuentra respuestas rápidas o contacta al equipo de soporte.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),

          _HelpCard(
            icon: Icons.help_outline,
            title: 'Preguntas frecuentes',
            subtitle: 'Consulta dudas comunes sobre la plataforma.',
            onTap: () => _openDetailPage(context, 'Preguntas frecuentes', [
              '¿Cómo publico una pregunta?',
              'Presiona Publicar y completa los datos del ejercicio.',
              '¿Dónde veo mis publicaciones?',
              'Puedes revisarlas desde Foros o Mis Preguntas.',
            ]),
          ),

          _HelpCard(
            icon: Icons.payment,
            title: 'Problemas con pagos',
            subtitle: 'Reporta inconvenientes con pagos o recompensas.',
            onTap: () => _openDetailPage(context, 'Problemas con pagos', [
              'Verifica tu conexión.',
              'Confirma los datos de la transacción.',
              'Guarda el comprobante o referencia del pago.',
              'Si el problema continúa, contacta soporte.',
            ]),
          ),

          _HelpCard(
            icon: Icons.report_problem_outlined,
            title: 'Reportar un problema',
            subtitle: 'Informa errores o fallas dentro de la app.',
            onTap: () => _openDetailPage(context, 'Reportar un problema', [
              'Describe claramente el error.',
              'Indica en qué pantalla ocurrió.',
              'Agrega capturas si es posible.',
              'El equipo revisará el caso.',
            ]),
          ),

          _HelpCard(
            icon: Icons.support_agent,
            title: 'Contactar soporte',
            subtitle: 'Comunícate con el equipo administrador.',
            onTap: () => _openDetailPage(context, 'Contactar soporte', [
              'Correo: soporte@braintask.com',
              'Teléfono: +58 412-0000000',
              'Horario: Lunes a Viernes - 8:00 AM a 5:00 PM',
            ]),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de contacto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '📧 soporte@braintask.com',
                  style: TextStyle(color: Colors.black, decoration: TextDecoration.none),
                ),
                SizedBox(height: 8),
                Text(
                  '📞 +58 412-0000000',
                  style: TextStyle(color: Colors.black, decoration: TextDecoration.none),
                ),
                SizedBox(height: 8),
                Text(
                  '🕒 Lunes a Viernes - 8:00 AM a 5:00 PM',
                  style: TextStyle(color: Colors.black, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, color: const Color(0xFF007BFF), size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.none,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class HelpDetailPage extends StatelessWidget {
  final String title;
  final List<String> items;

  const HelpDetailPage({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, decoration: TextDecoration.none),
        ),
        backgroundColor: const Color(0xFF007BFF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda y Soporte"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "¿Necesitas ayuda?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text("Preguntas Frecuentes"),
                subtitle: Text(
                  "Encuentra respuestas rápidas a dudas comunes.",
                ),
              ),
            ),

            SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(Icons.payment),
                title: Text("Problemas con pagos"),
                subtitle: Text(
                  "Reporta inconvenientes relacionados con pagos.",
                ),
              ),
            ),

            SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(Icons.report_problem_outlined),
                title: Text("Reportar un problema"),
                subtitle: Text(
                  "Informa errores o fallas dentro de la plataforma.",
                ),
              ),
            ),

            SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(Icons.support_agent),
                title: Text("Contactar soporte"),
                subtitle: Text(
                  "Comunícate con el equipo de soporte.",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
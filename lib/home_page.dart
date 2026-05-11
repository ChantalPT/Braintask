import 'package:flutter/material.dart';
import 'publicaciones.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
   State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Braintask',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildReputationBadge(),
          const SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Esto lo tenemos constante y se va a tener que cambiar consultanodo a la BDD para que sea el nombre del usuario
            const Text(
              '¡Hola, Ale! 👋', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // el buscador que lo tenemos que editar 
            _buildSearchBar(), 

            const SizedBox(height: 25),

            // Pasamos el context para que funcione la navegación al tocarlo
            _buildActionBanner(context),

            const SizedBox(height: 25),

            const Text(
              'Explorar materias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCategoryList(),

            const SizedBox(height: 25),

            // estos estan de manera constante para que se muestren los ejercicios pero luego cambairlo 
            const Text(
              'Problemas publicados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProblemCard('Cálculo: Derivada parcial', 'Hace 10 min', 42),
            _buildProblemCard('Programación: Error en C++', 'Hace 25 min', 15),
          ],
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index){
          if(index == 2){ // El índice 2 es el botón de "Publicar"
            Navigator.push(context, 
              MaterialPageRoute(builder: (context)=> const PublicarPage()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Foros'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF007BFF)),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '¿Qué materia buscas hoy?',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars, color: Colors.orange, size: 16),
            SizedBox(width: 4),
            // aqui esta el 125 pegado pero se tiene que ir actualizando 
            Text('125 pts', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Agregamos BuildContext para que el banner pueda navegar al ser tocado
  Widget _buildActionBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublicarPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF007BFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Text('¿Tienes una duda?', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Toca aquí para publicar tu ejercicio', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    // esto tiene que llamar a los filtros. 
    final categories = ['Todos', 'Matemáticas', 'Física', 'Química'];
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: index == 0 ? const Color(0xFF007BFF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(categories[index], 
                style: TextStyle(color: index == 0 ? Colors.white : Colors.black87, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProblemCard(String title, String time, int votes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, color: Color(0xFF007BFF)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.arrow_upward, size: 20, color: Colors.orange),
              Text('$votes', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
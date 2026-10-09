import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

// Importe as suas telas aqui
import 'profile_screen.dart';
import 'bolhas_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Define qual aba começa aberta (Ex: 2 é a 'Home' na sua lista)
  int _currentIndex = 2; 

  // Lista com as páginas exatas na mesma ordem dos itens da sua NavBar
  final List<Widget> _paginas = [
    const ProfileScreen(),     // Índice 0 - Minha conta
    const BubblesScreen(),      // Índice 1 - Bolhas
    const HomeScreen(),        // Índice 2 - Home
    const SearchScreen(),      // Índice 3 - Pesquisa
    const ChatScreen(),        // Índice 4 - Chat
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Exibe a tela correspondente ao índice atual
      body: _paginas[_currentIndex], 
      
      // Insere a sua BottomNavBar customizada
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Atualiza o índice para mudar a página
          });
        },
      ),
    );
  }
}

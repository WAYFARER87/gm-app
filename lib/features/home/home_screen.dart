import 'package:flutter/material.dart';
import '../news/news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _primary = Color(0xFF182857);
  static const List<Widget> _pages = [
    NewsScreen(),
    Center(child: Text('События')),
    Center(child: Text('Афиша')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,                 // компактная шапка
        automaticallyImplyLeading: false,  // без пустой «назад»-кнопки
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo_light_mobile.png',
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,       // белый фон
        selectedItemColor: _primary,          // активные — синие
        unselectedItemColor: Colors.grey,     // неактивные — серые
        type: BottomNavigationBarType.fixed,  // все подписи видны
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'События'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Афиша'),
        ],
      ),
    );
  }
}

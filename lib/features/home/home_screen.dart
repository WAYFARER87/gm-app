import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../mclub/mclub_screen.dart';
import '../uae_unlocked/uae_unlocked_screen.dart';
import '../radio/radio_screen.dart';
import '../news/news_screen.dart';
import '../auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showNearbyOnly = false});

  final bool showNearbyOnly;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _primary = Color(0xFF182857);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MClubScreen(showNearbyOnly: widget.showNearbyOnly),
      const UAEUnlockedScreen(),
      const RadioScreen(),
      const NewsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,                 // компактная шапка
        automaticallyImplyLeading: false,  // без пустой «назад»-кнопки
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: _primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        title: SvgPicture.asset(
          'assets/images/mclub_logo.svg',
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
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'М-Клуб'),
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: 'Открой ОАЭ!'),
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Радио'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
        ],
      ),
    );
  }
}

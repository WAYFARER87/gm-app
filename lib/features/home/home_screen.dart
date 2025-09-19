import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/rates_api_service.dart';
import '../afisha/afisha_screen.dart';
import '../cinema/cinema_screen.dart';
import '../events/events_screen.dart';
import '../news/news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final RatesApiService _ratesApi = RatesApiService();
  late final Future<List<CurrencyRate>> _ratesFuture;

  static const _primary = Color(0xFF182857);
  static const List<Widget> _pages = [
    NewsScreen(),
    EventsScreen(),
    AfishaScreen(),
    CinemaScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ratesFuture = _loadRates();
  }

  Future<List<CurrencyRate>> _loadRates() async {
    try {
      final response = await _ratesApi.fetchRates();
      return response.rates;
    } catch (err) {
      debugPrint('Failed to load currency rates: $err');
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52, // компактная шапка
        automaticallyImplyLeading: false, // без пустой «назад»-кнопки
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/images/logo_light_mobile.png',
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FutureBuilder<List<CurrencyRate>>(
                future: _ratesFuture,
                builder: (context, snapshot) {
                  final rates = snapshot.data ?? const [];
                  if (rates.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _RatesTicker(rates: rates),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // белый фон
        selectedItemColor: _primary, // активные — синие
        unselectedItemColor: Colors.grey, // неактивные — серые
        type: BottomNavigationBarType.fixed, // все подписи видны
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'События'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Афиша'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Кино'),
        ],
      ),
    );
  }
}

class _RatesTicker extends StatelessWidget {
  const _RatesTicker({required this.rates});

  final List<CurrencyRate> rates;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: const Color(0xFF4F4F4F),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 12,
          color: Color(0xFF4F4F4F),
          fontWeight: FontWeight.w600,
        );

    final children = <Widget>[];
    for (var i = 0; i < rates.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: 8));
      }
      children.add(_CurrencyRateView(
        rate: rates[i],
        textStyle: textStyle,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _CurrencyRateView extends StatelessWidget {
  const _CurrencyRateView({required this.rate, required this.textStyle});

  final CurrencyRate rate;
  final TextStyle textStyle;

  static final NumberFormat _numberFormat = NumberFormat('###0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final formattedValue = _numberFormat.format(rate.value);
    final currencySymbol = _currencySymbol(rate.code);
    final showSpace = currencySymbol == rate.code;
    final iconData = rate.hasPositiveTrend
        ? Icons.arrow_drop_up
        : (rate.hasNegativeTrend ? Icons.arrow_drop_down : null);
    final iconColor = rate.hasPositiveTrend
        ? const Color(0xFF1AAE6F)
        : (rate.hasNegativeTrend ? const Color(0xFFD84E4E) : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          showSpace
              ? '$currencySymbol $formattedValue'
              : '$currencySymbol$formattedValue',
          style: textStyle,
        ),
        if (iconData != null)
          Icon(
            iconData,
            size: 16,
            color: iconColor,
          ),
      ],
    );
  }

  static String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CNY':
      case 'JPY':
        return '¥';
      default:
        return code.toUpperCase();
    }
  }
}

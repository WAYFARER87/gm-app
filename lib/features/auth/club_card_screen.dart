import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import 'user_profile.dart';
import 'club_card.dart';

class ClubCardScreen extends StatefulWidget {
  const ClubCardScreen({super.key});

  @override
  State<ClubCardScreen> createState() => _ClubCardScreenState();
}

class _ClubCardScreenState extends State<ClubCardScreen> {
  final _api = ApiService();
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Не удалось загрузить профиль');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    } else if (_profile != null) {
      final p = _profile!;
      body = Center(
        child: ClubCard(
          cardNum: p.cardNum,
          expireDate: p.expireDate,
          firstName: p.name,
          lastName: p.lastname,
        ),
      );
    } else {
      body = const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Клубная карта')),
      body: body,
    );
  }
}


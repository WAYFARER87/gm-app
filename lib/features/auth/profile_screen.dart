import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/auth_gate.dart';
import 'user_profile.dart';
import 'club_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _api.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _lastNameCtrl.text = profile.lastname;
        _phoneCtrl.text = profile.phone;
        _emailCtrl.text = profile.email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить профиль: $e')),
        );
        setState(() => _error = 'Не удалось загрузить профиль');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final upd = await _api.updateProfile(
        name: _nameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      if (upd != null) {
        setState(() {
          _profile = upd;
          _nameCtrl.text = upd.name;
          _lastNameCtrl.text = upd.lastname;
          _phoneCtrl.text = upd.phone;
          _emailCtrl.text = upd.email;
          _isEditing = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    // Обновляем состояние авторизации и возвращаемся к корневому экрану,
    // где [AuthGate] покажет экран входа.
    AuthGate.of(context)?.refreshAuthState();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить профиль'),
        content:
            const Text('Вы уверены, что хотите удалить профиль? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _api.deleteProfile();
      await _logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      final p = _profile;
      if (p != null) {
        _nameCtrl.text = p.name;
        _lastNameCtrl.text = p.lastname;
        _phoneCtrl.text = p.phone;
        _emailCtrl.text = p.email;
      }
    });
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Имя'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Фамилия'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Введите фамилию' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Телефон'),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildViewProfile() {
    final profile = _profile;
    if (profile == null) return const SizedBox();

    Widget buildTile(String label, String value, IconData icon) {
      return ListTile(
        leading: Icon(icon),
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }

    final theme = Theme.of(context);
    final items = [
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ProfileHeader(profile: profile),
          ),
          const Divider(),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Личная информация',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTile('Имя', profile.name, Icons.person),
                buildTile('Фамилия', profile.lastname, Icons.person),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Контакты',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTile('Телефон', profile.phone, Icons.phone),
                buildTile('Email', profile.email, Icons.email),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF182857),
              side: const BorderSide(color: Color(0xFF182857)),
            ),
            child: const Text('Изменить профиль'),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isDeleting ? null : _deleteProfile,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Удалить профиль'),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ),
      ),
    ];

    return ListTileTheme(
      tileColor: Colors.transparent,
      selectedColor: theme.colorScheme.primary,
      iconColor: theme.iconTheme.color,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }


  Widget _buildProfileTab() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _isEditing
          ? KeyedSubtree(key: const ValueKey('edit'), child: _buildEditForm())
          : KeyedSubtree(key: const ValueKey('view'), child: _buildViewProfile()),
    );
  }

  Widget _buildCardTab() {
    final profile = _profile;
    if (profile == null) {
      return const SizedBox();
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: profile.cardNum));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Номер карты скопирован')),
          );
        },
        child: ClubCard(
          cardNum: profile.cardNum,
          expireDate: profile.expireDate,
          firstName: profile.name,
          lastName: profile.lastname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: _isEditing
              ? [
                  TextButton(
                    onPressed: _isSaving ? null : _cancelEdit,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF182857)),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF182857)),
                    child: const Text('Сохранить'),
                  ),
                ]
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: const TabBar(
              isScrollable: true,
              labelColor: Color(0xFF182857),
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Клубная карта'),
                Tab(text: 'Профиль'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildCardTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                profile.avatarUrl.isNotEmpty ? NetworkImage(profile.avatarUrl) : null,
            child: profile.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            '${profile.name} ${profile.lastname}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

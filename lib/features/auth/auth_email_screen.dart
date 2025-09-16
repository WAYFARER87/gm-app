// lib/features/auth/auth_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../core/services/api_service.dart';
import '../../core/widgets/auth_gate.dart';
import '../home/home_screen.dart'; // проверь путь под свой проект
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/location_permission_dialog.dart';

/// Простая локализация без flutter_gen (ru/en)
class _L {
  final bool ru;
  _L(this.ru);

  static _L of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return _L(code == 'ru');
  }

  String get emailLabel => 'Email';
  String get emailHint => 'you@example.com';
  String get nextButton => ru ? 'Далее' : 'Next';

  String get headingSignInOrRegister =>
      ru ? 'Войти или зарегистрироваться' : 'Sign in or register';

  String get skip => ru ? 'Пропустить' : 'Skip';

  String get agreeTerms => ru
      ? 'Регистрируясь, я соглашаюсь с условиями'
      : 'By registering, I agree to the terms';
  String get privacyPolicy =>
      ru ? 'Политика конфиденциальности' : 'Privacy Policy';

  String get codeTitle => ru ? 'Подтверждение' : 'Confirmation';
  String codeSentTo(String email) => ru
      ? 'Мы отправили 6-значный код на вашу почту $email.\nПожалуйста, введите его ниже, чтобы войти.'
      : 'We sent a 6-digit code to your email $email.\nPlease enter it below to sign in.';
  String get signInButton => ru ? 'Войти' : 'Sign in';

  String get checkSpam => ru
      ? 'Не получили письмо? Проверьте папку «Спам».'
      : 'Didn\'t get the email? Check your spam folder.';

  String get resendCode => ru ? 'Отправить код ещё раз' : 'Send code again';
  String resendCodeWithSeconds(int s) =>
      ru ? 'Отправить код ещё раз ($s)' : 'Send code again ($s)';

  String get errorEnterEmail => ru ? 'Введите email' : 'Enter your email';
  String get errorInvalidEmail => ru ? 'Некорректный email' : 'Invalid email';
  String errorEnterCodeFull(int n) =>
      ru ? 'Введите код полностью — $n цифр' : 'Enter full $n‑digit code';
  String get errorDigitsOnly => ru
      ? 'Код должен содержать только цифры'
      : 'Code must contain digits only';
  String get errorTokenMissing => ru ? 'Токен не получен' : 'Token missing';
  String get errorSendCode =>
      ru ? 'Не удалось отправить код' : 'Failed to send code';
  String get errorVerifyCode =>
      ru ? 'Не удалось подтвердить код' : 'Failed to verify code';
  String get errorNoConnection => ru
      ? 'Не удалось связаться с сервером, проверьте подключение к интернету'
      : 'Could not reach the server, check your internet connection';
  String get errorInvalidCode =>
      ru ? 'Неверный код. Попробуйте ещё раз.' : 'Invalid code. Try again.';
  String get codeResent => ru ? 'Код повторно отправлен' : 'Code sent again';
}

class AuthEmailScreen extends StatefulWidget {
  const AuthEmailScreen({super.key});

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _agreed = false; // галочка

  static const _primary = Color(0xFF182857);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(BuildContext context, String? v) {
    final t = _L.of(context);
    final s = (v ?? '').trim();
    if (s.isEmpty) return t.errorEnterEmail;
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!re.hasMatch(s)) return t.errorInvalidEmail;
    return null;
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) return; // без галочки не пускаем
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    try {
      await ApiService().requestCode(email);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => _AuthCodeScreen(email: email)));
    } on DioException catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.errorNoConnection)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.errorSendCode}: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t.errorSendCode}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse('https://mclub.ae/en/pages/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _skip() {
    // Открываем приложение без токена (обнуляем стек)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _L.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFECEFF1)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/mclub_logo.svg',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    t.headingSignInOrRegister,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Поле email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _primary.withOpacity(0.8)),
                  cursorColor: _primary.withOpacity(0.8),
                  decoration: InputDecoration(
                    labelText: t.emailLabel,
                    hintText: t.emailHint,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: BorderSide(
                        color: _primary.withOpacity(0.7),
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (v) => _validateEmail(context, v),
                  autofillHints: const [AutofillHints.email],
                ),

                // Кнопка "Далее"
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (!_loading && _agreed) ? _sendCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.nextButton),
                  ),
                ),

                // Галочка и Privacy — ниже кнопки, по центру
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                      Flexible(
                        child: Text(t.agreeTerms, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: InkWell(
                    onTap: _openPrivacy,
                    child: Text(
                      t.privacyPolicy,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===== Экран ввода кода: прозрачный TextField над ячейками (поддержка нативной вставки)
class _AuthCodeScreen extends StatefulWidget {
  final String email;
  const _AuthCodeScreen({required this.email});

  @override
  State<_AuthCodeScreen> createState() => _AuthCodeScreenState();
}

class _AuthCodeScreenState extends State<_AuthCodeScreen> {
  static const int CODE_LENGTH = 6;
  static const int RESEND_SECONDS = 60;

  final _overlayCtrl = TextEditingController();
  final _overlayNode = FocusNode();

  String _code = ''; // текущий код (0..6 цифр)
  bool _loading = false;
  int _secondsLeft = RESEND_SECONDS;
  Timer? _timer;
  bool _invalid = false;

  static const _primary = Color(0xFF182857);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overlayNode.requestFocus();
    });
    _overlayCtrl.addListener(_onOverlayChanged);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _overlayCtrl.removeListener(_onOverlayChanged);
    _overlayCtrl.dispose();
    _overlayNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = RESEND_SECONDS);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onOverlayChanged() {
    // Берём только цифры и ограничиваем длину
    var digits = _overlayCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > CODE_LENGTH) digits = digits.substring(0, CODE_LENGTH);

    // Обновляем контроллер, чтобы курсор был в конце и текст был корректный
    if (_overlayCtrl.text != digits) {
      _overlayCtrl.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() {
      _code = digits;
      if (_invalid) _invalid = false;
    });
  }

  Future<void> _verify() async {
    if (_code.length != CODE_LENGTH) {
      final t = _L.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorEnterCodeFull(CODE_LENGTH))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await ApiService().verifyCode(widget.email, _code);
      if (!ok) throw _L.of(context).errorTokenMissing;
      if (!mounted) return;
      // После успешной верификации обновляем состояние авторизации
      // и возвращаемся к корневому экрану, где [AuthGate] покажет приложение.
      AuthGate.of(context)?.refreshAuthState();
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('location_permission_granted')) {
        await showDialog(
          context: context,
          builder: (_) => const LocationPermissionDialog(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      if (e.response?.statusCode == 400) {
        setState(() => _invalid = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.errorInvalidCode)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.errorVerifyCode}: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t.errorVerifyCode}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    try {
      await ApiService().requestCode(widget.email);
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.codeResent)));
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      final t = _L.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t.errorSendCode}: $e')));
    }
  }

  // Ячейка отображения
  Widget _buildBox(int index) {
    final ch = index < _code.length ? _code[index] : '';
    final borderColor = _invalid ? Colors.red : Colors.grey.shade300;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        ch,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _L.of(context);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.codeTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFECEFF1)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              SvgPicture.asset('assets/images/mclub_logo.svg', height: 80),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  t.codeSentTo(widget.email),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Стек: видимые ячейки + прозрачный TextField сверху
              Stack(
                children: [
                  // Ряд ячеек
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(CODE_LENGTH, _buildBox),
                  ),
                  // Прозрачное поле поверх (полностью перекрывает ряд ячеек)
                  Positioned.fill(
                    child: TextField(
                      controller: _overlayCtrl,
                      focusNode: _overlayNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      enableInteractiveSelection:
                          true, // нужно для контекстного меню
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      cursorColor: Colors.transparent, // не виден курсор
                      style: const TextStyle(
                        color: Colors.transparent, // и текст не виден
                        fontSize: 1, // чтобы не прыгала высота
                      ),
                      decoration: const InputDecoration(
                        // полностью плоско и без отступов/рамок
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Не даём платформе сама закрывать клавиатуру
                      onEditingComplete: () {},
                      onSubmitted: (_) {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Center(child: Text(t.checkSpam, textAlign: TextAlign.center)),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.signInButton),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _secondsLeft == 0 ? _resend : null,
                style: TextButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  _secondsLeft == 0
                      ? t.resendCode
                      : t.resendCodeWithSeconds(_secondsLeft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

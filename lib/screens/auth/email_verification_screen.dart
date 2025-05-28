import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/translation_service.dart';
import '../../layout/main_layout.dart';
import '../auth/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String userId;

  const EmailVerificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late User _user;
  Timer? _timer;
  bool _isEmailVerified = false;
  bool _isLoading = false;
  bool _canResend = true;
  Timer? _resendTimer;
  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _isEmailVerified = _user.emailVerified;

    if (!_isEmailVerified) {
      _sendVerificationEmail();

      _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _user.reload();
        _user = FirebaseAuth.instance.currentUser!;
        if (_user.emailVerified) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isEmailVerified = true;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainLayout(userId: widget.userId)),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _canResend = false;
      _resendCooldown = 30;
    });

    try {
      await _user.sendEmailVerification();

      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown == 0) {
          timer.cancel();
          setState(() {
            _canResend = true;
          });
        } else {
          setState(() {
            _resendCooldown--;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.t('email_send_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    // При нажатии «назад» возвращаемся на экран логина
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return false; // отменяем стандартный выход
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onBackground;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.t('email_verification')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _isEmailVerified
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                      const SizedBox(height: 24),
                      Text(
                        TranslationService.t('email_verified_success'),
                        style: TextStyle(fontSize: 18, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => MainLayout(userId: widget.userId)),
                          );
                        },
                        child: Text(TranslationService.t('continue')),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TranslationService.t('email_verification_sent'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        TranslationService.t('check_inbox_spam'),
                        style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        TranslationService.t('did_not_receive_code'),
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _canResend ? _sendVerificationEmail : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _canResend
                                  ? Text(TranslationService.t('resend_email'))
                                  : Text('${TranslationService.t('resend_email_in')} $_resendCooldown s'),
                            ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

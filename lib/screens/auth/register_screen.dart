import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../layout/main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;
  final _auth = AuthService();

  InputDecoration _glassInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainLayout(userId: user.uid)),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = TranslationService.t('registration_error');
      switch (e.code) {
        case 'weak-password':
          message = TranslationService.t('weak_password');
          break;
        case 'email-already-in-use':
          message = TranslationService.t('email_in_use');
          break;
        case 'invalid-email':
          message = TranslationService.t('invalid_email_format');
          break;
        default:
          message = '${TranslationService.t('unknown_error')}: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${TranslationService.t('registration_error')}: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('register')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: _glassInputDecoration(TranslationService.t('username')),
                validator: (value) =>
                    (value == null || value.isEmpty) ? TranslationService.t('enter_username') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: _glassInputDecoration(TranslationService.t('first_name')),
                validator: (value) =>
                    (value == null || value.isEmpty) ? TranslationService.t('enter_first_name') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: _glassInputDecoration(TranslationService.t('last_name')),
                validator: (value) =>
                    (value == null || value.isEmpty) ? TranslationService.t('enter_last_name') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _glassInputDecoration(TranslationService.t('email')),
                validator: (value) =>
                    (value == null || value.isEmpty) ? TranslationService.t('enter_email') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _glassInputDecoration(TranslationService.t('password')),
                validator: (value) => (value == null || value.length < 6)
                    ? TranslationService.t('weak_password')
                    : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(TranslationService.t('register')),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}

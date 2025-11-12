import 'package:flutter/material.dart';
import '../theme.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onLogin;
  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLoginView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'StudySync',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your AI-powered study partner.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoginView
                      ? LoginForm(onLogin: widget.onLogin)
                      : RegisterForm(onLogin: widget.onLogin),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isLoginView = !isLoginView),
                  child: Text(
                    isLoginView ? "Don't have an account? Register" : "Already have an account? Login",
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600,
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

class LoginForm extends StatelessWidget {
  final VoidCallback onLogin;
  const LoginForm({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Login',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 16),
          const Text('Student ID or Email', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '22L-6573@lhr.nu.edu.pk',
            ),
          ),
          const SizedBox(height: 12),
          const Text('Password', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: '••••••••',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onLogin,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterForm extends StatelessWidget {
  final VoidCallback onLogin;
  const RegisterForm({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 16),
          const Text('Full Name', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            decoration: InputDecoration(hintText: 'e.g., Mahad Farhan Khan'),
          ),
          const SizedBox(height: 12),
          const Text('Student ID', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            decoration: InputDecoration(hintText: 'e.g., 22L-6589'),
          ),
          const SizedBox(height: 12),
          const Text('Email', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'e.g., 22L-6589@lhr.nu.edu.pk'),
          ),
          const SizedBox(height: 12),
          const Text('Password', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: '••••••••'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onLogin,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Register', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}



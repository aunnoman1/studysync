import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onGuest;
  final bool initialIsLogin;
  const AuthPage({
    super.key,
    required this.onLogin,
    required this.onGuest,
    this.initialIsLogin = true,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  late bool _isLogin = widget.initialIsLogin;
  bool _loading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));
    _entranceController.forward();

    // Auto-close this page when a Supabase session appears (login completed elsewhere)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null && mounted) {
        widget.onLogin();
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'username': _usernameController.text.trim()},
        );
      }

      final user = supabase.auth.currentUser;
      if (user != null) {
        final metaUsername = user.userMetadata?['username']?.toString();
        final usernameToSave = (metaUsername != null && metaUsername.isNotEmpty)
            ? metaUsername
            : user.email?.split('@').first ?? 'Guest';
        try {
          await supabase.from('profiles').upsert({
            'user_id': user.id,
            'username': usernameToSave,
          });
        } catch (_) {
          // Ignore profile upsert errors to not block login
        }
      }

      widget.onLogin();
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : AppTheme.surface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to StudySync')),
      body: Center(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: AppTheme.cardDecoration(isDark: isDark),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedCrossFade(
                          firstChild: Text(
                            'Welcome back',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          secondChild: Text(
                            'Create your account',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          crossFadeState: _isLogin
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: AppTheme.duration,
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              border: Border.all(color: const Color(0xFFFECACA)),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter a username'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Min 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _AnimatedButton(
                          loading: _loading,
                          onPressed: _loading ? null : _submit,
                          label: _isLogin ? 'Sign In' : 'Sign Up',
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? "Don't have an account? Sign Up"
                                : "Have an account? Sign In",
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  widget.onGuest();
                                  if (mounted) {
                                    Navigator.of(context).maybePop();
                                  }
                                },
                          child: const Text('Continue without account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Button with animated scale feedback ──
class _AnimatedButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  const _AnimatedButton({required this.loading, required this.onPressed, required this.label});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.blue, AppTheme.blueHover],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

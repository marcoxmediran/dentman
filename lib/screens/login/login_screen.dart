import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'mock@email.com');
  final _passwordController = TextEditingController(text: 'mock123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    final success = await ref
        .read(authProvider.notifier)
        .login(email, password);
    if (!success) {
      final error = ref.read(authProvider).errorMessage;
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final useMock = ref.watch(useMockDatabaseProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withAlpha(204), // using withAlpha to avoid deprecation warnings
              AppTheme.backgroundWhite,
            ],
            stops: const [0.0, 0.4, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header/Logo
                  const Icon(
                    Icons.medical_services_rounded,
                    size: 80,
                    color: AppTheme.secondaryGold,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DentMan',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Clinic Management System',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Login Card
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Staff Sign In',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Clinic Email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter email';
                                  }
                                  return null;
                                },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mock Database configuration / guidelines info helper
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withAlpha(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Developer Mock Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            Switch(
                              value: useMock,
                              onChanged: (val) {
                                ref
                                    .read(useMockDatabaseProvider.notifier)
                                    .toggle(val);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val
                                          ? 'Switched to offline Mock Database.'
                                          : 'Switched to live Firebase database connection.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              activeThumbColor: AppTheme.secondaryGold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          useMock
                              ? 'Currently using demo data. Click Switch to run with live Firestore (needs project config).'
                              : 'Connecting to live Firestore. Ensure Firebase is configured.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (useMock) ...[
                          const Divider(),
                          const Text(
                            'Demo Credentials:\nEmail: mock@email.com\nPassword: mock123',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

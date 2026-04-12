import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _usePhone = false;
  bool _createAccountMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F0F172A),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.wallet2,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SubDetox',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Secure financial command center',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _AuthModeToggle(
                        usePhone: _usePhone,
                        onChanged: (value) => setState(() => _usePhone = value),
                      ),
                      const SizedBox(height: 18),
                      if (_usePhone)
                        _PhoneAuthForm(
                          phoneController: _phoneController,
                          otpController: _otpController,
                          otpRequested: authProvider.otpRequested,
                          isBusy: authProvider.isBusy,
                          onRequestOtp: () async {
                            await authProvider.requestPhoneOtp(
                              _phoneController.text.trim(),
                            );
                          },
                          onVerifyOtp: () async {
                            await authProvider.verifyPhoneOtp(
                              _otpController.text.trim(),
                            );
                          },
                        )
                      else
                        _EmailAuthForm(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          createAccountMode: _createAccountMode,
                          isBusy: authProvider.isBusy,
                          onToggleMode: () {
                            setState(() => _createAccountMode = !_createAccountMode);
                          },
                          onSubmit: () async {
                            final email = _emailController.text.trim();
                            final password = _passwordController.text;

                            if (_createAccountMode) {
                              await authProvider.registerWithEmailPassword(
                                email: email,
                                password: password,
                              );
                            } else {
                              await authProvider.signInWithEmailPassword(
                                email: email,
                                password: password,
                              );
                            }
                          },
                        ),
                      if (authProvider.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
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

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.usePhone,
    required this.onChanged,
  });

  final bool usePhone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleButton(
            selected: !usePhone,
            label: 'Email',
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            selected: usePhone,
            label: 'Phone OTP',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x190F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
          ),
        ),
      ),
    );
  }
}

class _EmailAuthForm extends StatelessWidget {
  const _EmailAuthForm({
    required this.emailController,
    required this.passwordController,
    required this.createAccountMode,
    required this.isBusy,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool createAccountMode;
  final bool isBusy;
  final VoidCallback onToggleMode;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InputLabel('Email'),
        _AuthTextField(
          controller: emailController,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        const _InputLabel('Password'),
        _AuthTextField(
          controller: passwordController,
          hint: 'Minimum 6 characters',
          obscureText: true,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            icon: Icon(createAccountMode ? LucideIcons.userPlus : LucideIcons.logIn),
            label: Text(createAccountMode ? 'Create account' : 'Sign in'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: isBusy ? null : onToggleMode,
            child: Text(
              createAccountMode
                  ? 'Already have an account? Sign in'
                  : 'New here? Create account',
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneAuthForm extends StatelessWidget {
  const _PhoneAuthForm({
    required this.phoneController,
    required this.otpController,
    required this.otpRequested,
    required this.isBusy,
    required this.onRequestOtp,
    required this.onVerifyOtp,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpRequested;
  final bool isBusy;
  final Future<void> Function() onRequestOtp;
  final Future<void> Function() onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InputLabel('Phone number'),
        _AuthTextField(
          controller: phoneController,
          hint: '+91XXXXXXXXXX',
          keyboardType: TextInputType.phone,
        ),
        if (otpRequested) ...[
          const SizedBox(height: 10),
          const _InputLabel('OTP code'),
          _AuthTextField(
            controller: otpController,
            hint: 'Enter 6-digit code',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : (otpRequested ? onVerifyOtp : onRequestOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            icon: Icon(otpRequested ? LucideIcons.badgeCheck : LucideIcons.smartphone),
            label: Text(otpRequested ? 'Verify OTP' : 'Send OTP'),
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF1E293B),
            ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

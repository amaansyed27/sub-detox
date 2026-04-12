import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _normalizePhoneNumber(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }

    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? cleaned : '+$digits';
    }

    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return cleaned;
    }
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.startsWith('91') && digits.length > 10) {
      return '+$digits';
    }
    return '+$digits';
  }

  String _maskPhoneNumber(String? phoneNumber) {
    final value = (phoneNumber ?? '').trim();
    if (value.isEmpty) {
      return '';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return value;
    }

    final countryLength = digits.length > 10 ? digits.length - 10 : 0;
    final local = digits.substring(countryLength);
    if (local.length <= 4) {
      return '+$digits';
    }

    final countryPrefix =
        countryLength > 0 ? '+${digits.substring(0, countryLength)} ' : '';
    final hidden = List.filled(local.length - 4, '•').join();
    final visible = local.substring(local.length - 4);
    return '$countryPrefix$hidden$visible';
  }

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
    final isBusy = authProvider.isBusy;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF071225),
                  Color(0xFF0D2A4A),
                  Color(0xFF124E66)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned(
            right: -70,
            top: 60,
            child: _GlowOrb(size: 190, color: Color(0x5538BDF8)),
          ),
          const Positioned(
            left: -90,
            top: 180,
            child: _GlowOrb(size: 220, color: Color(0x334ADE80)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(LucideIcons.wallet2,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'SubDetox',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 28,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Take back control of recurring payments.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to detect subscriptions, stop hidden charges, and keep savings on track.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFD7E6F8),
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FeatureChip(label: 'Secure Auth'),
                          _FeatureChip(label: 'Smart Detection'),
                          _FeatureChip(label: 'One-tap Revoke'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F8FC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AuthModeToggle(
                            usePhone: _usePhone,
                            onChanged: (value) =>
                                setState(() => _usePhone = value),
                          ),
                          const SizedBox(height: 18),
                          if (_usePhone)
                            _PhoneAuthForm(
                              phoneController: _phoneController,
                              otpController: _otpController,
                              otpRequested: authProvider.otpRequested,
                              isBusy: isBusy,
                              hasOtpCooldown: authProvider.hasOtpCooldown,
                              canResendOtp: authProvider.canResendOtp,
                              otpCooldownLabel: authProvider.otpCooldownLabel,
                              maskedPhoneNumber: _maskPhoneNumber(
                                authProvider.lastPhoneNumber ??
                                    _normalizePhoneNumber(
                                      _phoneController.text,
                                    ),
                              ),
                              onRequestOtp: () async {
                                await authProvider.requestPhoneOtp(
                                  _normalizePhoneNumber(
                                    _phoneController.text,
                                  ),
                                );
                              },
                              onResendOtp: () async {
                                await authProvider.resendPhoneOtp();
                              },
                              onVerifyOtp: () async {
                                await authProvider.verifyPhoneOtp(
                                  _otpController.text.replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  ),
                                );
                              },
                            )
                          else
                            _EmailAuthForm(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              createAccountMode: _createAccountMode,
                              isBusy: isBusy,
                              onToggleMode: () {
                                setState(() =>
                                    _createAccountMode = !_createAccountMode);
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
                              onGoogleSignIn: () async {
                                await authProvider.signInWithGoogle();
                              },
                            ),
                          if (authProvider.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: authProvider.errorMessage!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontSize: 12,
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
        color: const Color(0xFFE7ECF5),
        borderRadius: BorderRadius.circular(14),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0x00000000),
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
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
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
    required this.onGoogleSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool createAccountMode;
  final bool isBusy;
  final VoidCallback onToggleMode;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          createAccountMode ? 'Create your account' : 'Welcome back',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          createAccountMode
              ? 'Set up your secure account to start monitoring recurring charges.'
              : 'Sign in to continue managing subscriptions and mandates.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        const _InputLabel('Email'),
        _AuthTextField(
          controller: emailController,
          hint: 'you@example.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        const _InputLabel('Password'),
        _AuthTextField(
          controller: passwordController,
          hint: 'Minimum 6 characters',
          prefixIcon: LucideIcons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B1B34),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: Icon(
                createAccountMode ? LucideIcons.userPlus : LucideIcons.logIn),
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
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFD6DEE9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'or',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFD6DEE9))),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isBusy ? null : onGoogleSignIn,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0xFFC5D2E4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFEAF1FF),
                  ),
                  child: Text(
                    'G',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Continue with Google'),
              ],
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
    required this.hasOtpCooldown,
    required this.canResendOtp,
    required this.otpCooldownLabel,
    required this.maskedPhoneNumber,
    required this.onRequestOtp,
    required this.onResendOtp,
    required this.onVerifyOtp,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool otpRequested;
  final bool isBusy;
  final bool hasOtpCooldown;
  final bool canResendOtp;
  final String otpCooldownLabel;
  final String maskedPhoneNumber;
  final Future<void> Function() onRequestOtp;
  final Future<void> Function() onResendOtp;
  final Future<void> Function() onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    final otpDestination = maskedPhoneNumber.isEmpty
        ? 'your registered mobile number'
        : maskedPhoneNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone verification',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Use your mobile number to receive a one-time verification code.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7DBFF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  otpRequested
                      ? 'Step 2 of 2: Enter the 6-digit OTP sent to $otpDestination.'
                      : 'Step 1 of 2: Enter your registered mobile number to receive OTP.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _InputLabel('Phone number'),
        Row(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD3DEEC)),
              ),
              alignment: Alignment.center,
              child: Text(
                '+91',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AuthTextField(
                controller: phoneController,
                hint: 'Enter 10-digit mobile number',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ),
          ],
        ),
        if (hasOtpCooldown && !otpRequested) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                LucideIcons.clock3,
                size: 15,
                color: Color(0xFF334155),
              ),
              const SizedBox(width: 6),
              Text(
                'You can request a new OTP in $otpCooldownLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        if (otpRequested) ...[
          const SizedBox(height: 10),
          const _InputLabel('OTP code'),
          _AuthTextField(
            controller: otpController,
            hint: 'Enter 6-digit code',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            letterSpacing: 8,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  canResendOtp
                      ? 'You can request a new OTP now.'
                      : 'Resend available in $otpCooldownLabel',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: isBusy || !canResendOtp ? null : onResendOtp,
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: otpRequested ? otpController : phoneController,
          builder: (context, _, __) {
            final phoneDigits =
                phoneController.text.replaceAll(RegExp(r'\D'), '');
            final otpDigits = otpController.text.replaceAll(RegExp(r'\D'), '');
            final canSendOtp = phoneDigits.length == 10 && !hasOtpCooldown;
            final canVerifyOtp = otpDigits.length == 6;
            final enabled =
                !isBusy && (otpRequested ? canVerifyOtp : canSendOtp);

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enabled
                    ? (otpRequested ? onVerifyOtp : onRequestOtp)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1B34),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: Icon(
                  otpRequested
                      ? LucideIcons.badgeCheck
                      : LucideIcons.smartphone,
                ),
                label: Text(otpRequested ? 'Verify OTP' : 'Send OTP'),
              ),
            );
          },
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
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextAlign textAlign;
  final double? letterSpacing;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            letterSpacing: letterSpacing,
          ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength == null ? null : '',
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD3DEEC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.4),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.alertTriangle,
                color: Color(0xFFB91C1C), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

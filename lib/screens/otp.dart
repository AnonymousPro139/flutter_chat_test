import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/riverpod/index.dart';

class OtpScreen extends ConsumerStatefulWidget {
  /// Pass this from the previous screen (after calling verifyPhoneNumber).
  final String verificationId;

  /// For resend you typically also need the phone number again.
  final String phoneNumber;

  /// If you get forceResendingToken from verifyPhoneNumber, pass it here.
  final int? forceResendingToken;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.forceResendingToken,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  String? _errorText;

  Timer? _timer;
  int _secondsLeft = 60;

  // When resending, Firebase returns a new verificationId.
  late String _verificationId;
  int? _forceResendingToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _forceResendingToken = widget.forceResendingToken;
    _startTimer();
    // Auto-focus first box.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  bool get _isOtpComplete =>
      _controllers.every((c) => c.text.trim().isNotEmpty) &&
      _otpCode.length == 6;

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _onChanged(int index, String value) {
    setState(() {
      _errorText = null;
    });

    // Paste handling: if user pastes 6 digits into one field, spread it.
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 1) {
      final chars = digitsOnly.split('');
      for (int i = 0; i < _otpLength; i++) {
        if (i < chars.length) _controllers[i].text = chars[i];
      }
      // Put cursor at end.
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
      _focusNodes.last.requestFocus();
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  KeyEventResult _onKey(int index, FocusNode node, KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        setState(() => _errorText = null);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) {
      setState(() => _errorText = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      ref.read(authControllerProvider.notifier).checkLogin();
      // ✅ Success: navigate wherever you want
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // Common cases:
      // - invalid-verification-code
      // - session-expired
      setState(() {
        _errorText = e.message ?? 'Verification failed. Please try again.';
      });
      _clearOtp();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0) return;

    setState(() {
      _errorText = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // If auto verification happens:
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.of(context).pop(true);
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _errorText = e.message ?? 'Failed to resend code.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _forceResendingToken = resendToken;
        });
        _clearOtp();
        _startTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Keep current verification id as fallback.
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final page = SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              'Enter verification code',
              style:
                  (isIOS
                          ? CupertinoTheme.of(
                              context,
                            ).textTheme.navLargeTitleTextStyle
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a 6-digit code to\n${widget.phoneNumber}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),

            _OtpRow(
              controllers: _controllers,
              focusNodes: _focusNodes,
              onChanged: _onChanged,
              onKey: _onKey,
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  _secondsLeft > 0
                      ? 'Resend in $_secondsLeft s'
                      : 'Didn’t receive code?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _secondsLeft == 0 ? _resendCode : null,
                  child: const Text('Resend'),
                ),
              ],
            ),

            const Spacer(),

            Center(
              child: TextButton(
                onPressed: _isVerifying
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Change phone number'),
              ),
            ),
          ],
        ),
      ),
    );

    return isIOS
        ? CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(middle: Text('OTP')),
            child: page,
          )
        : Scaffold(
            appBar: AppBar(title: const Text('OTP')),
            body: page,
          );
  }
}

class _OtpRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final KeyEventResult Function(int index, FocusNode node, KeyDownEvent event)
  onKey;

  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        return SizedBox(
          width: 46,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            // onKeyEvent: (event) => onKey(index, focusNodes[index], event),
            onKeyEvent: (event) => {
              // Only trigger on key down, not key up
              if (event is KeyDownEvent)
                {onKey(index, focusNodes[index], event)},
              //  KeyEventResult.ignored;
            },
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => onChanged(index, v),
            ),
          ),
        );
      }),
    );
  }
}

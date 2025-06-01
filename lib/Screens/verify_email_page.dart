import 'dart:async';
import 'package:blorbmart2/Screens/home_page.dart';
import 'package:blorbmart2/Screens/Login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

class VerifyEmailPage extends StatefulWidget {
  final User user;
  const VerifyEmailPage({super.key, required this.user});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isResending = false;
  bool _isVerified = false;
  bool _isChecking = false;
  bool _showVerifiedMessage = false;
  Timer? _verificationCheckTimer;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationProcess();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _startEmailVerificationProcess() async {
    // Initial check
    await _checkEmailVerified();

    // Send verification email if not already verified
    if (!_isVerified && mounted) {
      await _sendVerificationEmail();
    }

    // Start periodic checking
    _startVerificationCheckTimer();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();
      _showSuccessToast(
        'Verification email sent to ${widget.user.email}',
        description: 'Please check your inbox and verify your email address.',
      );
    } catch (e) {
      if (mounted) {
        _showErrorToast(
          'Failed to send verification email',
          description: 'Please try again later.',
        );
      }
    }
  }

  void _startVerificationCheckTimer() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isVerified) return;

    setState(() => _isChecking = true);

    try {
      // Reload user to get latest verification status
      await widget.user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.emailVerified) {
        _verificationCheckTimer?.cancel();
        setState(() {
          _isVerified = true;
          _isChecking = false;
        });

        // Show verification success message
        if (mounted) {
          setState(() => _showVerifiedMessage = true);
          _showSuccessToast(
            'Email verified successfully!',
            description: 'Your email has been successfully verified.',
          );
        }

        // Navigate to home after a brief delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToHome();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast(
          'Verification check failed',
          description: 'Unable to verify your email status. Please try again.',
        );
      }
    } finally {
      if (mounted && !_isVerified) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await widget.user.sendEmailVerification();
      _showSuccessToast(
        'Verification email resent',
        description: 'Please check your inbox for the verification link.',
      );
    } catch (e) {
      _showErrorToast(
        'Failed to resend verification email',
        description: 'Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomePage(onTabChange: (int) {}),
        transitionsBuilder:
            (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder:
            (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showErrorToast(String title, {String? description}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(title),
      description: description != null ? Text(description) : null,
      autoCloseDuration: const Duration(seconds: 5),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.error_outline),
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: false,
      pauseOnHover: true,
    );
  }

  void _showSuccessToast(String title, {String? description}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(title),
      description: description != null ? Text(description) : null,
      autoCloseDuration: const Duration(seconds: 5),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.check_circle_outline),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: false,
      pauseOnHover: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _showVerifiedMessage
                        ? const Icon(
                          Icons.verified,
                          key: ValueKey('verified-icon'),
                          size: 80,
                          color: Colors.green,
                        )
                        : Icon(
                          key: ValueKey('unverified-icon'),
                          _isChecking ? Icons.refresh : Icons.mark_email_unread,
                          size: 80,
                          color: _isChecking ? Colors.orange : Colors.orange,
                        ),
              ),
              const SizedBox(height: 24),
              Text(
                _showVerifiedMessage ? 'Email Verified!' : 'Verify Your Email',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _showVerifiedMessage
                        ? Text(
                          key: ValueKey('verified-text'),
                          'Thank you for verifying your email!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        )
                        : Text(
                          key: ValueKey('unverified-text'),
                          _isChecking
                              ? 'Checking verification status...'
                              : 'A verification link has been sent to:\n${widget.user.email}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
              ),
              const SizedBox(height: 32),
              if (!_isVerified && !_isChecking) ...[
                ElevatedButton(
                  onPressed: _isResending ? null : _resendVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isResending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'Resend Email',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              if (_isChecking) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.orange),
              ],
              if (_showVerifiedMessage) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to App',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

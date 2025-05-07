import 'dart:async';

import 'package:blorbmart2/Screens/home_page.dart';
import 'package:blorbmart2/Screens/Login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (!_isVerified) {
      await widget.user.sendEmailVerification();
      _showSuccessToast('Verification email sent to ${widget.user.email}');
    }

    // Start periodic checking
    _startVerificationCheckTimer();
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
        setState(() => _isVerified = true);

        // Show verification success message
        setState(() => _showVerifiedMessage = true);
        _showSuccessToast('Email verified successfully!');

        // Navigate to home after a brief delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToHome();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Error checking verification status');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await widget.user.sendEmailVerification();
      _showSuccessToast('Verification email resent successfully');
    } catch (e) {
      _showErrorToast('Failed to resend verification email');
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
        pageBuilder: (_, __, ___) => const HomePage(),
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

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
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

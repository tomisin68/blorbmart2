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
  // ignore: unused_field
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
    widget.user.sendEmailVerification();
  }

  Future<void> _checkEmailVerified() async {
    await widget.user.reload();
    if (widget.user.emailVerified && mounted) {
      setState(() {
        _isVerified = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
              Icon(
                _isVerified ? Icons.verified : Icons.mark_email_unread,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                _isVerified ? 'Email Verified!' : 'Verify Your Email',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isVerified
                    ? 'Your email has been successfully verified.'
                    : 'A verification link has been sent to ${widget.user.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              if (!_isVerified) ...[
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              if (_isVerified) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
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

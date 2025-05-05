import 'package:blorbmart2/Screens/Signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFirstTimeUser = true;
  bool _isLoading = true;

  // High-quality marketplace image URL (optimized for fast loading)
  static const String backgroundImageUrl =
      'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80';

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;

    if (!_isFirstTimeUser && mounted) {
      // Using Navigator in a post-frame callback to ensure safe context usage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignupPage()),
          );
        }
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirstTimeUser || _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2463)),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // Optimized Network Image with cache and error handling
            Positioned.fill(
              child: Image.network(
                backgroundImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF0A2463).withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0A2463),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF0A2463));
                },
              ),
            ),

            // Gradient Overlay for better text visibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() => _currentPage = page);
                      },
                      children: [
                        _buildOnboardingPage(
                          title: "Welcome to Blorbmart",
                          description:
                              "Discover millions of products at unbeatable prices with lightning fast delivery.",
                        ),
                        _buildOnboardingPage(
                          title: "Shop with Confidence",
                          description:
                              "Secure payments and buyer protection on every order you place with us.",
                        ),
                        _buildOnboardingPage(
                          title: "Start Your Journey",
                          description:
                              "Join over 10 million happy customers shopping on Blorbmart today!",
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Page Indicator with colors
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color:
                                _currentPage == index
                                    ? _getIndicatorColor(index)
                                    : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2463),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        onPressed: _completeOnboarding,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIndicatorColor(int index) {
    const List<Color> colors = [
      Color(0xFF0A2463), // Primary blue
      Color(0xFF3E92CC), // Light blue
      Color(0xFFD8315B), // Pink/red
    ];
    return colors[index % colors.length];
  }

  Widget _buildOnboardingPage({
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
              height: 1.3,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w500, // Slightly bolder for better visibility
              color: Colors.white.withOpacity(0.95), // Increased opacity
              fontFamily: 'Poppins',
              height: 1.6,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

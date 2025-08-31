import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _loaderController;

  @override
  void initState() {
    super.initState();

    // Initialize main animations with faster duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Reduced from 3 seconds
    );

    // Initialize loader animation with faster duration
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Reduced from 2 seconds
    );



    _controller.forward();
    _loaderController.repeat();

    // Check authentication state after splash screen - reduced delay
    Timer(const Duration(milliseconds: 1500), () { // Reduced from 3 seconds
      if (!mounted) return;
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, go to home screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder:
              (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500), // Reduced from 800
        ),
      );
    } else {
      // User is not logged in, go to login screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SignInScreen(),
          transitionsBuilder:
              (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 500), // Reduced from 800
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF4A6CD1), Color(0xFFD4AF37)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Welcome Logo - Optimized for faster loading
              Lottie.asset(
                'assets/Welcome Page Logo.json',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                frameRate: FrameRate(60), // Ensure smooth 60fps
                repeat: true,
                animate: true,
              ),
              // Main Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShineText(
                    text: 'CurrenSee Pro',
                    textStyle: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 8,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AnimatedTypewriterText(
                    text: "World's Smartest Currency Converter",
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFD4AF37),
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureChip(
                        Icons.currency_exchange,
                        "Real-time Rates",
                        0,
                      ),
                      _buildFeatureChip(Icons.trending_up, "Market Trends", 1),
                      _buildFeatureChip(Icons.lock_clock, "Historical Data", 2),
                      _buildFeatureChip(Icons.g_translate, "Multi-Currency", 3),
                    ],
                  ),
                ],
              ),
              // Loader at the bottom - Optimized for faster loading
              Lottie.asset(
                'assets/Currency Loader.json',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                frameRate: FrameRate(60), // Ensure smooth 60fps
                repeat: true,
                animate: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text, int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.1; // Reduced delay from 0.2 to 0.1
        final animationValue = _controller.value;
        final chipAnimation =
            animationValue > delay
                ? (animationValue - delay) / (1 - delay)
                : 0.0;

        return Transform.scale(
          scale: chipAnimation,
          child: Opacity(
            opacity: chipAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced text widget with shine effect - Optimized
class ShineText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const ShineText({super.key, required this.text, required this.textStyle});

  @override
  State<ShineText> createState() => _ShineTextState();
}

class _ShineTextState extends State<ShineText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Reduced from 4 seconds
    )..repeat(reverse: true);

    _alignAnimation = Tween<Alignment>(
      begin: Alignment(-1.5, 0),
      end: Alignment(1.5, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
                const Color(0xFFD4AF37),
                Colors.white,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              begin: _alignAnimation.value,
              end: _alignAnimation.value + const Alignment(0.3, 0),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.textStyle),
        );
      },
    );
  }
}

// Enhanced animated typewriter text effect - Optimized
class AnimatedTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const AnimatedTypewriterText({
    super.key,
    required this.text,
    required this.textStyle,
  });

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Reduced from 2000
    );

    _typingAnimation = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start typing animation after a shorter delay
    Future.delayed(const Duration(milliseconds: 200), () { // Reduced from 500
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final text = widget.text.substring(0, _typingAnimation.value);
        return Text(text, style: widget.textStyle, textAlign: TextAlign.center);
      },
    );
  }
}

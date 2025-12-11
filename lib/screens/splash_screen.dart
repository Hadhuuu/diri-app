import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import '../main.dart'; // Akses AuthCheckWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Tunggu animasi logo selesai (3 detik)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Langsung ke Pengecekan Status Login (AuthCheckWrapper)
      // Kita tidak cek onboarding di sini lagi.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthCheckWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, 
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 120, style: LogoStyle.soul, withText: false),
                const SizedBox(height: 24),
                Text('DIRI', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 8, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text("Ruang amanmu.", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white54, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
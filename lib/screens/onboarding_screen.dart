import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../main.dart'; // Untuk akses AuthCheckWrapper

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Ruang Amanmu",
      "desc": "Tempat paling jujur untuk bercerita tanpa takut dihakimi. Tulis, rekam, dan simpan kenanganmu.",
      "icon": Icons.book_rounded,
      "color": AppColors.primary,
    },
    {
      "title": "Pahami Dirimu",
      "desc": "Lacak pola emosimu setiap hari. Sadari apa yang membuatmu bahagia, sedih, atau bersemangat.",
      "icon": Icons.incomplete_circle_rounded, // Icon Chart unik
      "color": Colors.orange,
    },
    {
      "title": "Pesan Masa Depan",
      "desc": "Kirim surat untuk dirimu di masa depan. Sebuah harapan, pengingat, atau sekadar sapaan hangat.",
      "icon": Icons.mail_lock_rounded,
      "color": Colors.purpleAccent,
    },
  ];

  void _finishOnboarding() async {
    // Simpan tanda bahwa user sudah pernah lihat onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      // Kembali ke Penjaga Pintu.
      // Karena sekarang 'has_seen_onboarding' sudah TRUE, 
      // AuthCheckWrapper akan otomatis meloloskan kita ke Home (atau LockScreen).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthCheckWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // BACKGROUND PATTERN (Opsional, biar gak sepi)
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow( // blurRadius goes HERE
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 100, // This is correct
                    offset: Offset(0, 4),
                  ),
                ],
              )
            ),
          ),

          // KONTEN UTAMA
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ICON ANIMASI (Pake Container Glow)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (page['color'] as Color).withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: (page['color'] as Color).withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(
                        page['icon'],
                        size: 80,
                        color: page['color'],
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // TEKS JUDUL
                    Text(
                      page['title'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // TEKS DESKRIPSI
                    Text(
                      page['desc'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        height: 1.6,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // TOMBOL & INDIKATOR DI BAWAH
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // INDIKATOR TITIK (Dots)
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8, // Panjang kalau aktif
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? _pages[_currentPage]['color'] 
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // TOMBOL NEXT / MULAI
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding(); // Selesai
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage]['color'], // Warna berubah sesuai slide
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    elevation: 8,
                    shadowColor: (_pages[_currentPage]['color'] as Color).withOpacity(0.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentPage == _pages.length - 1 ? "Mulai" : "Lanjut",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      if (_currentPage != _pages.length - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ],
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
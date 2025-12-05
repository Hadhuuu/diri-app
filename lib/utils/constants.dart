import 'package:flutter/material.dart';

class AppColors {
  // --- DARK MODE PALETTE ---
  
  // Background Utama (Sangat Gelap, hampir hitam tapi ada nuansa biru/abu dikit biar warm)
  static const Color background = Color(0xFF121212); 
  
  // Warna Permukaan (Card, Dialog, BottomSheet) - Sedikit lebih terang dari bg
  static const Color surface = Color(0xFF1E1E1E);
  
  // Warna Utama (Primary) - Ganti Coklat jadi Teal Pastel/Emas Lembut
  // Pilihan saya: Teal Muted (Sangat menenangkan)
  static const Color primary = Color(0xFF80CBC4); // Teal lembut
  
  // Warna Aksen/Secondary
  static const Color accent = Color(0xFF4DB6AC); 
  
  // Teks
  static const Color textPrimary = Color(0xFFEEEEEE); // Putih tulang (baca enak)
  static const Color textSecondary = Color(0xFFB0BEC5); // Abu muda
  
  // Error/Warning (Merah lembut)
  static const Color error = Color(0xFFE57373);

  // List Mood Colors (Untuk nanti)
  static const Color moodHappy = Color(0xFFFFD54F);
  static const Color moodSad = Color(0xFF64B5F6);
  static const Color moodAngry = Color(0xFFE57373);
  static const Color moodAnxious = Color(0xFFA1887F);
}

class AppUrls {
  static const String baseUrl = 'https://diri-backend-production.up.railway.app/api'; 
}
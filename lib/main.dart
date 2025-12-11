import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/letter_provider.dart';
import 'providers/theme_provider.dart'; 
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart'; 
import 'utils/constants.dart';
import 'services/biometric_service.dart'; 
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';
import 'services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async { // Ubah jadi async
  WidgetsFlutterBinding.ensureInitialized(); // Wajib ada
  
  // Init Database Lokal
  await LocalStorageService.init(); 

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, 
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => LetterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // <-- DAFTARKAN INI
      ],
      child: Consumer<ThemeProvider>( // <-- BUNGKUS MATERIAL APP DENGAN CONSUMER
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'DIRI',
            debugShowCheckedModeBanner: false,
            
            // --- LOGIKA TEMA (Light vs Dark) ---
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            
            // TEMA TERANG (Morning Breeze)
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Putih Tulang
              primaryColor: AppColors.primary,
              useMaterial3: true,
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                surface: Colors.white,
                background: Color(0xFFF5F5F5),
                onSurface: Color(0xFF424242), // Teks Gelap
              ),
              textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                foregroundColor: Color(0xFF424242), // Icon Gelap
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
            ),

            // TEMA GELAP (Midnight Sanctuary) - Default kita kemarin
            darkTheme: ThemeData(
              brightness: Brightness.dark, 
              scaffoldBackgroundColor: AppColors.background,
              primaryColor: AppColors.primary,
              useMaterial3: true,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.surface,
                background: AppColors.background,
                onSurface: AppColors.textPrimary,
              ),
              textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                foregroundColor: AppColors.textPrimary,
              ),
              cardTheme: CardThemeData(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
            ),
            
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return const SplashScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  bool _isLoading = true;
  bool _isBiometricEnabled = false;
  bool _hasSeenOnboarding = false; // Variable baru

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    // 1. Cek Biometrik
    final bioEnabled = await BiometricService().isBiometricEnabled();
    
    // 2. Cek Onboarding (SharedPrefs)
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('has_seen_onboarding') ?? false;

    if (mounted) {
      setState(() {
        _isBiometricEnabled = bioEnabled;
        _hasSeenOnboarding = onboardingSeen;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    
    final auth = Provider.of<AuthProvider>(context);
    
    // 1. Belum Login? -> Login Screen
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // 2. Sudah Login, tapi BELUM pernah lihat onboarding? -> Onboarding Screen
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // 3. Sudah Login & Sudah Onboarding, tapi Biometrik Aktif? -> Lock Screen
    if (_isBiometricEnabled) {
      return const LockScreen();
    }

    // 4. Lolos Semua -> Masuk Home
    return const MainWrapper();
  }
}
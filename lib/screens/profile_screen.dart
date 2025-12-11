import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart'; 
import '../providers/journal_provider.dart'; // Import buat cek offline
import '../utils/constants.dart';
import 'edit_profile_screen.dart'; 
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricActive = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  void _loadBiometricStatus() async {
    final status = await _biometricService.isBiometricEnabled();
    setState(() => _isBiometricActive = status);
  }

  void _toggleBiometric(bool value) async {
    if (value) {
      final success = await _biometricService.authenticate();
      if (!success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verifikasi gagal.")));
        return; 
      }
    }
    await _biometricService.setBiometricEnabled(value);
    setState(() => _isBiometricActive = value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final user = auth.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final bgColor = theme.cardTheme.color;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60), 
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: AppColors.primary, width: 2),
                image: user?.avatarUrl != null 
                  ? DecorationImage(image: NetworkImage(user!.avatarUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: user?.avatarUrl == null 
                ? Center(child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "D", style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary)))
                : null,
            ),
            const SizedBox(height: 24),
            Text(user?.name ?? "Pengguna", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: textColor)),
            Text(user?.email ?? "email@diri.id", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 40),

            Container(
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text("Mode Malam", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: textColor)),
                    secondary: _buildIconBox(Icons.dark_mode_rounded, isDark),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                  _buildDivider(isDark),
                  
                  // --- SATPAM OFFLINE EDIT PROFIL ---
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded, 
                    title: "Edit Profil",
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () {
                      final isOffline = Provider.of<JournalProvider>(context, listen: false).isOffline;
                      if (isOffline) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Butuh internet untuk edit profil 🙏")));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    },
                  ),
                  
                  _buildDivider(isDark),
                  SwitchListTile(
                    title: Text("Kunci Aplikasi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: textColor)),
                    subtitle: Text("Butuh sidik jari saat dibuka", style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                    secondary: _buildIconBox(Icons.fingerprint_rounded, isDark),
                    value: _isBiometricActive,
                    activeColor: AppColors.primary,
                    onChanged: _toggleBiometric, 
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)),
              child: _buildMenuItem(icon: Icons.logout_rounded, title: "Keluar Aplikasi", textColor: AppColors.error, iconColor: AppColors.error, isDark: isDark, 
                onTap: () async => await Provider.of<AuthProvider>(context, listen: false).logout()),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, bool isDark) { return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isDark ? Colors.white : Colors.grey, size: 20)); }
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, Color? textColor, Color? iconColor, required bool isDark}) { return ListTile(onTap: onTap, leading: _buildIconBox(icon, isDark), title: Text(title, style: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.w500)), trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300)); }
  Widget _buildDivider(bool isDark) { return Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200, indent: 60, endIndent: 20); }
}
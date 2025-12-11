import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/journal_provider.dart';
import '../models/journal_model.dart';
import '../utils/constants.dart';
import 'journal_editor_screen.dart';

class MoodSelectorScreen extends StatefulWidget {
  const MoodSelectorScreen({super.key});

  @override
  State<MoodSelectorScreen> createState() => _MoodSelectorScreenState();
}

class _MoodSelectorScreenState extends State<MoodSelectorScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).fetchMoods();
    });
  }

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  // --- LOGIKA ICON YANG LEBIH CANTIK ---
  IconData _getMoodIcon(String moodName) {
    final name = moodName.toLowerCase();
    // Mapping yang lebih akurat dan ekspresif
    if (name.contains('senang') || name.contains('bahagia') || name.contains('happy')) return Icons.sentiment_very_satisfied_rounded;
    if (name.contains('semangat') || name.contains('excited')) return Icons.rocket_launch_rounded;
    if (name.contains('biasa') || name.contains('neutral') || name.contains('okay')) return Icons.sentiment_neutral_rounded;
    if (name.contains('sedih') || name.contains('sad') || name.contains('kecewa')) return Icons.sentiment_dissatisfied_rounded;
    if (name.contains('marah') || name.contains('angry')) return Icons.mood_bad_rounded;
    if (name.contains('takut') || name.contains('cemas') || name.contains('anxious')) return Icons.sick_rounded;
    if (name.contains('lelah') || name.contains('tired')) return Icons.bedtime_rounded;
    if (name.contains('bersyukur') || name.contains('grateful')) return Icons.volunteer_activism_rounded;
    
    // Default fallback
    return Icons.face_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Apa kabar harimu?", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, child) {
          if (provider.moods.isEmpty) {
             if (provider.isOffline) {
               return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wifi_off_rounded, size: 50, color: Colors.grey), SizedBox(height: 10), Text("Data Mood belum tersedia offline.", style: TextStyle(color: Colors.grey))]));
             }
             return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, // Sedikit lebih kotak biar icon lega
            ),
            itemCount: provider.moods.length,
            itemBuilder: (context, index) {
              final mood = provider.moods[index];
              final color = _parseColor(mood.colorCode);

              return InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalEditorScreen(mood: mood),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lingkaran Icon yang Besar & Jelas
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getMoodIcon(mood.name), 
                          size: 40, // Icon Besar
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        mood.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
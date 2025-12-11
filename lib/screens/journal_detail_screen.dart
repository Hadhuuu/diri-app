import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/journal_model.dart';
import '../utils/constants.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_audio_player.dart';
import '../widgets/journal_media_display.dart'; // Import Widget Media Pintar
import 'journal_editor_screen.dart';

class JournalDetailScreen extends StatelessWidget {
  final int journalId; 

  JournalDetailScreen({super.key, required Journal journal}) : journalId = journal.id;

  Color _parseColor(String hexCode) {
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('EEEE, d MMMM yyyy').format(date); 
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;
    if (!urlString.startsWith('http')) {
      urlString = 'https://$urlString';
    }
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka link.")));
    }
  }

  void _confirmDelete(BuildContext context) {
    // --- SATPAM OFFLINE ---
    final isOffline = Provider.of<JournalProvider>(context, listen: false).isOffline;
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak bisa hapus saat offline 🙏")));
      return;
    }

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text("Hapus Kenangan?", style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text("Jurnal ini akan hilang selamanya.", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              final success = await Provider.of<JournalProvider>(context, listen: false).deleteJournal(journalId);
              if (success && context.mounted) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jurnal berhasil dihapus.")));
              }
            },
            child: const Text("Hapus", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, child) {
        Journal? journal;
        try {
          journal = provider.journals.firstWhere((j) => j.id == journalId);
        } catch (e) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final moodColor = _parseColor(journal.mood.colorCode);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = theme.colorScheme.onSurface;
        final subTextColor = theme.textTheme.bodyMedium?.color;
        final backgroundColor = theme.scaffoldBackgroundColor;

        final lines = journal.content.split('\n');
        final titleText = lines.isNotEmpty ? lines[0] : "";
        final bodyText = lines.length > 1 ? journal.content.substring(journal.content.indexOf('\n') + 1).trim() : "";

        return Scaffold(
          backgroundColor: backgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: (journal.imageUrl != null || journal.localImagePath != null) ? 350 : 100,
                pinned: true,
                backgroundColor: backgroundColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: backgroundColor.withOpacity(0.5), shape: BoxShape.circle),
                  child: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20), onPressed: () => Navigator.pop(context)),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: backgroundColor.withOpacity(0.5), shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(journal.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: journal.isPinned ? Colors.orange : textColor, size: 20),
                      onPressed: () async {
                        // --- SATPAM OFFLINE ---
                        if (provider.isOffline) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Butuh internet untuk menyematkan 🙏")));
                          return;
                        }
                        final msg = await Provider.of<JournalProvider>(context, listen: false).togglePin(journal!.id);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: backgroundColor.withOpacity(0.5), shape: BoxShape.circle),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: textColor),
                      color: theme.cardTheme.color,
                      onSelected: (value) {
                        if (value == 'edit') {
                          // --- SATPAM OFFLINE ---
                          if (provider.isOffline) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak bisa edit saat offline 🙏")));
                            return;
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (context) => JournalEditorScreen(mood: journal!.mood, existingJournal: journal)));
                        } else if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text("Edit Tulisan", style: TextStyle(color: textColor))),
                        PopupMenuItem(value: 'delete', child: Text("Hapus Kenangan", style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: (journal.imageUrl != null || journal.localImagePath != null)
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(tag: 'journal-img-${journal.id}', 
                              child: JournalImageDisplay(imageUrl: journal.imageUrl, localPath: journal.localImagePath, width: double.infinity, height: double.infinity)
                            ),
                            Positioned(bottom: 0, left: 0, right: 0, height: 100, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, backgroundColor])))),
                          ],
                        )
                      : Container(color: moodColor.withOpacity(0.1)),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: moodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: moodColor.withOpacity(0.3))), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: moodColor, shape: BoxShape.circle)), const SizedBox(width: 8), Text(journal.mood.name, style: TextStyle(fontWeight: FontWeight.bold, color: moodColor))])),
                          Text(_formatDate(journal.date), style: GoogleFonts.plusJakartaSans(color: subTextColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (journal.musicLink != null && journal.musicLink!.isNotEmpty)
                        InkWell(
                          onTap: () => _launchURL(context, journal!.musicLink!), 
                          borderRadius: BorderRadius.circular(16),
                          child: Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1DB954).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1DB954))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Soundtrack Kenangan", style: GoogleFonts.plusJakartaSans(fontSize: 10, color: subTextColor)), Text(journal.musicLink!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline))])), const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary)])),
                        ),
                      if (journal.voiceUrl != null || journal.localVoicePath != null)
                        Padding(padding: const EdgeInsets.only(bottom: 24), child: JournalAudioPlayer(url: journal.localVoicePath ?? journal.voiceUrl!, isDark: isDark)),
                      if (titleText.isNotEmpty) ...[Text(titleText, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3, color: textColor)), const SizedBox(height: 16)],
                      if (bodyText.isNotEmpty) Text(bodyText, style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.8, color: textColor.withOpacity(0.9))),
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
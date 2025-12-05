import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_logo.dart';
import 'mood_selector_screen.dart';
import 'journal_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _todaysQuote;
 
  // STATE SELECTION
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};


  // STATE FILTER
  List<int> _filterMoodIds = [];
  String? _filterMediaType; // null, 'photo', 'voice', 'music'
  String _sortOrder = 'newest';
  DateTime? _startDate;
  DateTime? _endDate;


  final List<String> _quotes = [
    "Validasi terbaik datang dari dirimu sendiri.",
    "Tidak apa-apa untuk tidak merasa baik-baik saja.",
    "Hari ini adalah lembaran baru.",
    "Perasaanmu valid, serumit apapun itu.",
    "Ambil napas dalam-dalam. Kamu aman disini.",
  ];


  @override
  void initState() {
    super.initState();
    _todaysQuote = _quotes[Random().nextInt(_quotes.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }


  void _fetchData() {
    Provider.of<JournalProvider>(context, listen: false).fetchJournals(
      keyword: _searchController.text,
      moodIds: _filterMoodIds,
      mediaType: _filterMediaType,
      sortOrder: _sortOrder,
      startDate: _startDate,
      endDate: _endDate,
    );
  }


  // --- LOGIKA SELECTION ---
  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }


  void _enterSelectionMode(int id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }


  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }


  void _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Jurnal?"),
        content: Text("Yakin ingin menghapus $count kenangan terpilih?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    );


    if (confirmed == true) {
      await Provider.of<JournalProvider>(context, listen: false).deleteMultipleJournals(_selectedIds.toList());
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count jurnal dihapus.")));
    }
  }


  // --- LOGIKA FILTER MODAL ---
  void _showFilterModal() {
    final theme = Theme.of(context);
   
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter Canggih", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 20),
             
              Text("Isi Jurnal:", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip("Semua", _filterMediaType == null, () => setModalState(() => _filterMediaType = null)),
                  _buildFilterChip("Ada Foto", _filterMediaType == 'photo', () => setModalState(() => _filterMediaType = 'photo')),
                  _buildFilterChip("Ada Suara", _filterMediaType == 'voice', () => setModalState(() => _filterMediaType = 'voice')),
                  _buildFilterChip("Ada Musik", _filterMediaType == 'music', () => setModalState(() => _filterMediaType = 'music')),
                ],
              ),
              const SizedBox(height: 20),


              Text("Urutan:", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildFilterChip("Terbaru", _sortOrder == 'newest', () => setModalState(() => _sortOrder = 'newest')),
                  const SizedBox(width: 8),
                  _buildFilterChip("Terlama", _sortOrder == 'oldest', () => setModalState(() => _sortOrder = 'oldest')),
                ],
              ),
              const SizedBox(height: 20),


              Text("Rentang Waktu:", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_startDate == null ? "Semua Waktu" : "${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}"),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (picked != null) {
                    setModalState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
              ),
              if (_startDate != null)
                TextButton(onPressed: () => setModalState(() { _startDate = null; _endDate = null; }), child: const Text("Reset Tanggal")),


              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _fetchData(); },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text("Terapkan Filter"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;


    return Scaffold(
      body: Consumer<JournalProvider>(
        builder: (context, provider, child) {
          return AnimationLimiter(
            child: CustomScrollView(
              slivers: [
               
                // 1. HEADER (BERUBAH SAAT SELECTION MODE)
                _isSelectionMode
                ? SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _clearSelection),
                    title: Text("${_selectedIds.length} Terpilih", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null
                      ),
                    ],
                  )
                : SliverAppBar(
                    expandedHeight: 240.0,
                    floating: false,
                    pinned: true, // STICKY
                    backgroundColor: theme.cardTheme.color,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                   
                    title: Row(
                      children: [
                        const AppLogo(size: 32, style: LogoStyle.soul, withText: false),
                        const SizedBox(width: 12),
                        Text('DIRI', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.primary, fontSize: 20))
                      ]
                    ),
                   
                    actions: [
                      Padding(padding: const EdgeInsets.only(right: 16.0), child: CircleAvatar(backgroundColor: theme.scaffoldBackgroundColor, radius: 18, child: IconButton(icon: Icon(Icons.logout_rounded, size: 18, color: textTheme.bodyMedium?.color), onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(), padding: EdgeInsets.zero)))
                    ],
                   
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 60),
                            Text("${_getGreeting()},", style: GoogleFonts.plusJakartaSans(fontSize: 16, color: textTheme.bodyMedium?.color)),
                            Text("Apa ceritamu?", style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            const SizedBox(height: 60)
                          ]
                        )
                      )
                    ),
                   
                    // SEARCH BAR + FILTER BUTTON (STICKY)
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(80),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          children: [
                            // Search Field
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (val) => _fetchData(),
                                textInputAction: TextInputAction.search,
                                style: GoogleFonts.plusJakartaSans(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  hintText: "Cari kenangan...",
                                  hintStyle: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.search_rounded, color: textTheme.bodyMedium?.color),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _fetchData(); }) : null
                                )
                              )
                            ),
                            const SizedBox(width: 12),
                           
                            // TOMBOL FILTER (DI SEBELAH SEARCH)
                            InkWell(
                              onTap: _showFilterModal,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: (_filterMediaType != null || _sortOrder == 'oldest' || _startDate != null) ? AppColors.primary : theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: (_filterMediaType != null || _sortOrder == 'oldest' || _startDate != null) ? Colors.white : textTheme.bodyMedium?.color
                                )
                              ),
                            ),
                          ],
                        )
                      )
                    ),
                  ),


                // 2. DAILY INSIGHT (HANYA MUNCUL KALAU TIDAK SELECTION MODE)
                if (!_isSelectionMode)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.9), const Color(0xFF26A69A)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("INSIGHT HARI INI", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white70)), const SizedBox(height: 4), Text('"$_todaysQuote"', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontStyle: FontStyle.italic))]))]),
                      ),
                    ),
                  ),


                // 3. LIST JURNAL
                if (provider.isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                else if (provider.journals.isEmpty)
                  SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Opacity(opacity: 0.3, child: ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]), child: const AppLogo(size: 100, style: LogoStyle.soul, withText: false))), const SizedBox(height: 20), Text("Tidak ditemukan.", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textTheme.bodyMedium?.color))])),)
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final journal = provider.journals[index];
                        final isSelected = _selectedIds.contains(journal.id);
                        final moodColor = _parseColor(journal.mood.colorCode);
                        final hasImage = journal.imageUrl != null && journal.imageUrl!.isNotEmpty;
                        final hasVoice = journal.voiceUrl != null && journal.voiceUrl!.isNotEmpty;
                        final hasMusic = journal.musicLink != null && journal.musicLink!.isNotEmpty;
                       
                        // First Line as Title
                        final lines = journal.content.split('\n');
                        final titleText = lines.isNotEmpty ? lines[0] : "";
                        final bodyText = lines.length > 1 ? journal.content.substring(journal.content.indexOf('\n') + 1).trim() : "";


                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : theme.cardTheme.color, // Highlight Select
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200), width: isSelected ? 2 : 1),
                                  boxShadow: [if (!isDark && !_isSelectionMode) BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  // --- LOGIKA SELECTION ---
                                  onLongPress: () => _enterSelectionMode(journal.id),
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleSelection(journal.id);
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => JournalDetailScreen(journal: journal)));
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // CHECKBOX SELECTION
                                        if (_isSelectionMode)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12.0),
                                            child: Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? AppColors.primary : Colors.grey),
                                          ),
                                       
                                        // KONTEN JURNAL
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // TANGGAL & PIN
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  if (journal.isPinned) Row(children: [Transform.rotate(angle: 0.5, child: const Icon(Icons.push_pin_rounded, size: 14, color: Colors.orange)), const SizedBox(width: 4), const Text("Pinned", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))]) else const SizedBox(),
                                                  Text(_formatDate(journal.date), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                             
                                              // ISI
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(width: 4, height: 60, decoration: BoxDecoration(color: moodColor, borderRadius: BorderRadius.circular(2))),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(titleText, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                                        if (bodyText.isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Text(bodyText, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.4, color: colorScheme.onSurface.withOpacity(0.7))),
                                                        ],
                                                        const SizedBox(height: 12),
                                                        // BADGES
                                                        Row(
                                                          children: [
                                                            _buildBadge(text: journal.mood.name, color: moodColor, isDark: isDark, theme: theme),
                                                            if (hasVoice) ...[const SizedBox(width: 8), _buildIconBadge(Icons.mic_rounded, Colors.redAccent, isDark, theme)],
                                                            if (hasMusic) ...[const SizedBox(width: 8), _buildIconBadge(Icons.music_note_rounded, Colors.blueAccent, isDark, theme)],
                                                            if (hasImage) ...[const SizedBox(width: 8), _buildIconBadge(Icons.image_rounded, Colors.purpleAccent, isDark, theme)],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                 
                                                  // THUMBNAIL
                                                  if (hasImage) ...[
                                                    const SizedBox(width: 12),
                                                    Hero(
                                                      tag: 'journal-img-${journal.id}',
                                                      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(journal.imageUrl!, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Container(width: 70, height: 70, color: theme.scaffoldBackgroundColor))),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: provider.journals.length,
                    ),
                  ),
               
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      // FAB HILANG SAAT SELECTION MODE
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MoodSelectorScreen())),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 4, label: const Text("Tulis Cerita", style: TextStyle(fontWeight: FontWeight.bold)), icon: const Icon(Icons.edit_rounded),
      ),
    );
  }


  // --- HELPER WIDGETS ---
  Widget _buildBadge({
    required String text,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }


  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }


  Widget _buildIconBadge(
    IconData icon,
    Color color,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }


  String _getGreeting() {
    var hour = DateTime.now().hour;


    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }


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
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}




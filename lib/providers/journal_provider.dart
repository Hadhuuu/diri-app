import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/journal_model.dart';
import '../services/journal_service.dart';
import '../services/local_storage_service.dart';

class JournalProvider with ChangeNotifier {
  List<Journal> _journals = [];
  bool _isLoading = false;
  bool _isOffline = false; 

  List<Journal> get journals => _journals;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  // Data Mood & Calendar
  List<Mood> _moods = [];
  List<Mood> get moods => _moods;
  
  List<Map<String, dynamic>> _calendarData = [];
  List<Map<String, dynamic>> get calendarData => _calendarData;

  final JournalService service = JournalService();

  // --- CONSTRUCTOR ---
  JournalProvider() {
    _loadFromCache();      
    _loadMoodsFromCache(); 
    _initConnectivityListener(); 
  }

  // --- CACHE LOADERS ---
  void _loadFromCache() {
    try {
      final cachedData = LocalStorageService.getCachedJournals();
      if (cachedData.isNotEmpty) {
        _journals = cachedData.map((json) => Journal.fromJson(json)).toList();
        // Saat load cache awal, kita juga bisa langsung generate data kalender
        // Supaya dot langsung muncul tanpa nunggu fetch
        _generateCalendarDataFromLocal(); 
        notifyListeners();
      }
    } catch (e) {
      print("Cache journal error: $e");
    }
  }

  void _loadMoodsFromCache() {
    try {
      final cachedData = LocalStorageService.getCachedMoods();
      if (cachedData.isNotEmpty) {
        _moods = cachedData.map((json) => Mood.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Cache mood error: $e");
    }
  }

  // --- HELPER: GENERATE CALENDAR DOTS DARI DATA LOKAL ---
  // Ini kunci agar saat offline dot tetap muncul!
  void _generateCalendarDataFromLocal() {
    if (_journals.isNotEmpty) {
      _calendarData = _journals.map((j) {
        return {
          'date': j.date, // Format YYYY-MM-DD
          'mood_color': j.mood.colorCode,
        };
      }).toList();
      // Tidak perlu notifyListeners di sini jika dipanggil di dalam flow lain yang sudah notify
    }
  }

  // --- LISTENER CONNECTIVITY (VERSI 4/TUNGGAL) ---
  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool hasInternet = result != ConnectivityResult.none;
      
      _isOffline = !hasInternet;
      notifyListeners();

      if (hasInternet) {
        _processOfflineQueue(); 
        fetchJournals(); 
        fetchMoods();
        fetchCalendarData(); // Refresh kalender juga saat connect
      }
    });
  }

  // --- FETCH DATA UTAMA ---
  Future<void> fetchJournals({
    String? keyword,
    List<int>? moodIds,
    String? mediaType,
    String? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    bool isFiltering = keyword != null || (moodIds != null && moodIds.isNotEmpty) || mediaType != null || startDate != null;
    
    if (isFiltering) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _isOffline = true;
        _isLoading = false;
        if (_journals.isEmpty) _loadFromCache();
        // Pastikan calendar data juga terisi dari lokal saat offline
        _generateCalendarDataFromLocal();
        notifyListeners();
        return; 
      }

      // Online Fetch
      final serverJournals = await service.getJournals(
        keyword: keyword,
        moodIds: moodIds,
        mediaType: mediaType,
        sortOrder: sortOrder,
        startDate: startDate,
        endDate: endDate,
      );

      _journals = serverJournals;
      
      // Update Cache jika tidak sedang filter
      if (!isFiltering) {
        final journalsJson = serverJournals.map((j) => j.toJson()).toList();
        await LocalStorageService.cacheJournals(journalsJson);
        // Update data kalender lokal juga (sebagai backup instan)
        _generateCalendarDataFromLocal();
      }
      
    } catch (e) {
      print("Error fetching journals: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- FETCH CALENDAR DATA (SMART HYBRID) ---
  Future<void> fetchCalendarData() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // 1. JIKA OFFLINE: Pakai Data Lokal (Derivasi dari _journals)
      if (connectivityResult == ConnectivityResult.none) {
        _generateCalendarDataFromLocal();
        notifyListeners();
        return;
      }

      // 2. JIKA ONLINE: Ambil dari API (Lebih akurat/sinkron server)
      _calendarData = await service.getCalendarData();
      notifyListeners();

    } catch (e) {
      print("Error fetch calendar: $e");
      // Fallback: Kalau server error, tetap coba tampilkan dari data lokal yang ada
      _generateCalendarDataFromLocal();
      notifyListeners();
    }
  }

  Future<void> fetchMoods() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    try {
      final serverMoods = await service.getMoods();
      _moods = serverMoods;
      
      final moodsJson = serverMoods.map((m) => {
        'id': m.id,
        'name': m.name,
        'color_code': m.colorCode,
        'icon_name': m.iconName
      }).toList();
      await LocalStorageService.cacheMoods(moodsJson);
      
      notifyListeners();
    } catch (e) { print(e); }
  }

  // --- CRUD (ADD/UPDATE/DELETE) ---

  Future<bool> addJournal(int moodId, String content, DateTime date, {File? image, String? musicLink, File? voice}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (connectivityResult == ConnectivityResult.none) {
      // OFFLINE
      final action = {
        'type': 'add',
        'moodId': moodId,
        'content': content,
        'date': dateString,
        'musicLink': musicLink,
        'imagePath': image?.path,
        'voicePath': voice?.path,
      };
      await LocalStorageService.addToQueue(action);
      
      // Optimistic UI Update
      final selectedMood = _moods.firstWhere((m) => m.id == moodId, orElse: () => Mood(id: moodId, name: "Baru", colorCode: "#CCCCCC", iconName: "neutral"));
      final tempJournal = Journal(
        id: -DateTime.now().millisecondsSinceEpoch,
        content: content,
        date: dateString,
        mood: selectedMood,
        musicLink: musicLink,
        localImagePath: image?.path,
        localVoicePath: voice?.path,
        imageUrl: null, voiceUrl: null, 
      );

      _journals.insert(0, tempJournal);
      
      // Update Cache & Calendar Dots Langsung!
      final journalsJson = _journals.map((j) => j.toJson()).toList();
      await LocalStorageService.cacheJournals(journalsJson);
      _generateCalendarDataFromLocal(); // <-- PENTING: Update dot kalender realtime

      notifyListeners();
      return true; 
    } else {
      // ONLINE
      try {
        _isLoading = true;
        notifyListeners();
        await service.createJournal(moodId: moodId, content: content, date: dateString, imageFile: image, musicLink: musicLink, voiceFile: voice);
        await fetchJournals(); 
        // fetchJournals() di atas akan otomatis update cache & calendar data juga
        return true; 
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        return false; 
      }
    }
  }

  Future<void> _processOfflineQueue() async {
    final queue = await LocalStorageService.getQueue();
    if (queue.isEmpty) return;

    for (var item in queue) {
      if (item['type'] == 'add') {
        try {
          File? imageFile; if (item['imagePath'] != null) imageFile = File(item['imagePath']);
          File? voiceFile; if (item['voicePath'] != null) voiceFile = File(item['voicePath']);

          await service.createJournal(
            moodId: item['moodId'], content: item['content'], date: item['date'], musicLink: item['musicLink'],
            imageFile: imageFile, voiceFile: voiceFile
          );
        } catch (e) { print("Failed sync: $e"); }
      }
    }
    await LocalStorageService.clearQueue();
    await fetchJournals();
  }

  Future<bool> updateJournal(int id, int moodId, String content, DateTime date, {File? image, String? musicLink, File? voice, bool deleteImage = false, bool deleteVoice = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await service.updateJournal(
        id: id, moodId: moodId, content: content, date: dateString, 
        imageFile: image, musicLink: musicLink, voiceFile: voice,
        deleteImage: deleteImage, deleteVoice: deleteVoice
      );
      await fetchJournals(); 
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteJournal(int id) async {
    try {
      await service.deleteJournal(id);
      _journals.removeWhere((j) => j.id == id);
      
      // Update Cache & Calendar
      final journalsJson = _journals.map((j) => j.toJson()).toList();
      await LocalStorageService.cacheJournals(journalsJson);
      _generateCalendarDataFromLocal();

      notifyListeners();
      return true;
    } catch(e) { return false; }
  }

  Future<void> deleteMultipleJournals(List<int> ids) async {
    for (var id in ids) { await service.deleteJournal(id); }
    _journals.removeWhere((j) => ids.contains(j.id));
    
    // Update Cache & Calendar
    final journalsJson = _journals.map((j) => j.toJson()).toList();
    await LocalStorageService.cacheJournals(journalsJson);
    _generateCalendarDataFromLocal();

    notifyListeners();
  }

  Future<String> togglePin(int id) async {
    try {
      final msg = await service.togglePin(id);
      await fetchJournals();
      return msg;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }
  
  List<Journal> getJournalsByDate(DateTime date) {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _journals.where((j) => j.date == dateString).toList();
  }
}
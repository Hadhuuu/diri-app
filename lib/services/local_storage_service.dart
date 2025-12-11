import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class LocalStorageService {
  static const String boxName = 'diri_cache';
  static const String keyJournals = 'journals_data';
  static const String keyPendingQueue = 'pending_queue'; // Antrian offline
  static const String keyMoods = 'moods_data';

  // Inisialisasi di awal aplikasi
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  // Simpan List Jurnal ke HP (Cache)
  static Future<void> cacheJournals(List<dynamic> journalsJson) async {
    var box = Hive.box(boxName);
    // Simpan sebagai string JSON biar aman
    await box.put(keyJournals, json.encode(journalsJson));
  }

  static Future<void> cacheMoods(List<dynamic> moodsJson) async {
    var box = Hive.box(boxName);
    await box.put(keyMoods, json.encode(moodsJson));
  }
  // Ambil List Jurnal dari HP
  static List<dynamic> getCachedJournals() {
    var box = Hive.box(boxName);
    String? data = box.get(keyJournals);
    if (data == null) return [];
    return json.decode(data);
  }
  static List<dynamic> getCachedMoods() {
    var box = Hive.box(boxName);
    String? data = box.get(keyMoods);
    if (data == null) return [];
    return json.decode(data);
  }

  // --- ANTRIAN OFFLINE (PENDING ACTIONS) ---
  
  // Simpan aksi yang tertunda (misal: add journal pas offline)
  static Future<void> addToQueue(Map<String, dynamic> actionData) async {
    var box = Hive.box(boxName);
    List<dynamic> currentQueue = await getQueue();
    currentQueue.add(actionData);
    await box.put(keyPendingQueue, json.encode(currentQueue));
  }

  // Ambil antrian
  static Future<List<dynamic>> getQueue() async {
    var box = Hive.box(boxName);
    String? data = box.get(keyPendingQueue);
    if (data == null) return [];
    return json.decode(data);
  }

  // Bersihkan antrian setelah sinkronisasi
  static Future<void> clearQueue() async {
    var box = Hive.box(boxName);
    await box.delete(keyPendingQueue);
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import '../services/journal_service.dart';


class JournalProvider with ChangeNotifier {
  List<Journal> _journals = [];
  List<Map<String, dynamic>> _calendarData = [];
  bool _isLoading = false;


  List<Journal> get journals => _journals;
  List<Map<String, dynamic>> get calendarData => _calendarData;
  bool get isLoading => _isLoading;


  final JournalService service = JournalService();


  // FETCH JOURNALS (Dengan Parameter Filter)
  Future<void> fetchJournals({
    String? keyword,
    List<int>? moodIds,
    String? mediaType,
    String? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();


    try {
      _journals = await service.getJournals(
        keyword: keyword,
        moodIds: moodIds,
        mediaType: mediaType,
        sortOrder: sortOrder,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print("Error fetching journals: $e");
    }


    _isLoading = false;
    notifyListeners();
  }


  Future<void> fetchCalendarData() async {
    try {
      _calendarData = await service.getCalendarData();
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }


  List<Journal> getJournalsByDate(DateTime date) {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return _journals.where((j) => j.date == dateString).toList();
  }


  Future<bool> addJournal(int moodId, String content, DateTime date, {File? image, String? musicLink, File? voice}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await service.createJournal(moodId: moodId, content: content, date: dateString, imageFile: image, musicLink: musicLink, voiceFile: voice);
      await fetchJournals();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error add: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> updateJournal(int id, int moodId, String content, DateTime date, {File? image, String? musicLink, File? voice}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      await service.updateJournal(id: id, moodId: moodId, content: content, date: dateString, imageFile: image, musicLink: musicLink, voiceFile: voice);
      await fetchJournals();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error update: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<bool> deleteJournal(int id) async {
    try {
      await service.deleteJournal(id);
      _journals.removeWhere((j) => j.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }


  // BULK DELETE
  Future<void> deleteMultipleJournals(List<int> ids) async {
    // Loop delete (untuk saat ini, idealnya backend support bulk delete)
    for (var id in ids) {
      await service.deleteJournal(id);
    }
    _journals.removeWhere((j) => ids.contains(j.id));
    notifyListeners();
  }


  // TOGGLE PIN (Return Message)
  Future<String> togglePin(int id) async {
    try {
      final msg = await service.togglePin(id);
      await fetchJournals(); // Refresh list agar posisi pin berubah
      return msg;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", ""); // Return error message
    }
  }
}




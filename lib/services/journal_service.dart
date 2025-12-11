import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/journal_model.dart';

class JournalService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // GET JOURNALS
  Future<List<Journal>> getJournals({
    String? keyword,
    List<int>? moodIds, 
    String? mediaType,
    String? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _getToken();
    
    String query = '?';
    if (keyword != null && keyword.isNotEmpty) query += 'keyword=$keyword&';
    if (mediaType != null) query += 'media_type=$mediaType&';
    if (sortOrder != null) query += 'sort=$sortOrder&';
    
    if (moodIds != null && moodIds.isNotEmpty) {
      query += 'mood_ids=${moodIds.join(',')}&';
    }

    if (startDate != null && endDate != null) {
      String start = startDate.toIso8601String().split('T')[0];
      String end = endDate.toIso8601String().split('T')[0];
      query += 'start_date=$start&end_date=$end&';
    }

    final response = await http.get(
      Uri.parse('${AppUrls.baseUrl}/journals$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => Journal.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil jurnal');
    }
  }

  Future<List<Map<String, dynamic>>> getCalendarData() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${AppUrls.baseUrl}/journals/calendar'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body)['data']);
    } else {
      throw Exception('Gagal ambil data kalender');
    }
  }

  Future<List<Mood>> getMoods() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${AppUrls.baseUrl}/moods'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => Mood.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil mood');
    }
  }

  // CREATE
  Future<void> createJournal({
    required int moodId,
    required String content,
    required String date,
    File? imageFile,
    String? musicLink,
    File? voiceFile,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${AppUrls.baseUrl}/journals'));
    
    request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    request.fields['mood_id'] = moodId.toString();
    request.fields['content'] = content;
    request.fields['date'] = date;
    if (musicLink != null) request.fields['music_link'] = musicLink;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    if (voiceFile != null) {
      request.files.add(await http.MultipartFile.fromPath('voice', voiceFile.path));
    }

    var response = await request.send();
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal upload');
    }
  }

  // UPDATE (SUDAH DIPERBAIKI UNTUK DELETE IMAGE & VOICE)
  Future<void> updateJournal({
    required int id,
    required int moodId,
    required String content,
    required String date,
    File? imageFile,
    String? musicLink,
    File? voiceFile,
    bool deleteImage = false, // Hapus Foto
    bool deleteVoice = false, // Hapus Suara
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${AppUrls.baseUrl}/journals/$id');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
    
    request.fields['mood_id'] = moodId.toString();
    request.fields['content'] = content;
    request.fields['date'] = date;
    
    // --- SINYAL HAPUS ---
    if (deleteImage) request.fields['delete_image'] = '1';
    if (deleteVoice) request.fields['delete_voice'] = '1';

    if (musicLink != null) request.fields['music_link'] = musicLink;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    if (voiceFile != null) {
      request.files.add(await http.MultipartFile.fromPath('voice', voiceFile.path));
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Gagal update');
    }
  }

  Future<void> deleteJournal(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${AppUrls.baseUrl}/journals/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus');
    }
  }

  Future<String> togglePin(int id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${AppUrls.baseUrl}/journals/$id/pin'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final body = json.decode(response.body);
    if (response.statusCode == 200) {
      return body['message'];
    } else {
      throw Exception(body['message']);
    }
  }
}
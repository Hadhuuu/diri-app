class Mood {
  final int id;
  final String name;
  final String colorCode;
  final String iconName;


  Mood({required this.id, required this.name, required this.colorCode, required this.iconName});


  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      id: json['id'],
      name: json['name'],
      colorCode: json['color_code'],
      iconName: json['icon_name'],
    );
  }
}


class Journal {
  final int id;
  final String content;
  final String date;
  final Mood mood;
  final String? imageUrl;
  final String? musicLink;
  final String? voiceUrl;
  final bool isPinned;
  final String? localImagePath; 
  final String? localVoicePath;

  Journal({
    required this.id,
    required this.content,
    required this.date,
    required this.mood,
    this.imageUrl,
    this.musicLink,
    this.voiceUrl,
    this.isPinned = false,
    this.localImagePath,
    this.localVoicePath,
  });


  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      id: json['id'],
      // Pakai '?? ""' untuk jaga-jaga kalau null biar ga crash
      content: json['content'] ?? '',
      date: json['date'],
      mood: Mood.fromJson(json['mood']),
      imageUrl: json['image_url'],
      musicLink: json['music_link'],
      voiceUrl: json['voice_url'],
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      localImagePath: null, 
      localVoicePath: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'date': date,
      'mood': {
        'id': mood.id,
        'name': mood.name,
        'color_code': mood.colorCode,
        'icon_name': mood.iconName,
      },
      'image_url': imageUrl,     // Pastikan key ini sama dengan yang dibaca fromJson
      'voice_url': voiceUrl,
      'music_link': musicLink,
      'is_pinned': isPinned ? 1 : 0, // Simpan boolean sebagai int/bool tergantung API
    };
  }
}

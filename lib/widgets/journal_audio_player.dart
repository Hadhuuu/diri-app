import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Paket Audio
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class JournalAudioPlayer extends StatefulWidget {
  final String url;
  final bool isDark;

  const JournalAudioPlayer({
    super.key,
    required this.url,
    required this.isDark,
  });

  @override
  State<JournalAudioPlayer> createState() => _JournalAudioPlayerState();
}

class _JournalAudioPlayerState extends State<JournalAudioPlayer> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPlayerInited = false;
  
  // Durasi
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    // Atur agar update durasi tiap 100ms (biar slider mulus)
    await _player.setSubscriptionDuration(const Duration(milliseconds: 100));
    
    setState(() {
      _isPlayerInited = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    _playerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_isPlayerInited) return;

    if (_player.isPlaying) {
      await _player.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      // Jika posisi sudah di akhir, reset ke awal
      if (_player.isPaused) {
        await _player.resumePlayer();
      } else {
        await _player.startPlayer(
          fromURI: widget.url,
          codec: Codec.mp3, // Atau biarkan default, flutter_sound cukup pintar deteksi
          whenFinished: () {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero; // Reset slider pas selesai
            });
          },
        );
        
        // Dengarkan perubahan durasi
        _playerSubscription = _player.onProgress!.listen((e) {
          if (mounted) {
            setState(() {
              _position = e.position;
              _duration = e.duration;
            });
          }
        });
      }
      setState(() => _isPlaying = true);
    }
  }

  // Format durasi jadi 00:00
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final bgColor = widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // TOMBOL PLAY/PAUSE
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isPlaying)
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                ]
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // SLIDER & DURASI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isPlaying ? "Sedang Memutar..." : "Rekaman Suara",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: textColor
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: color,
                          inactiveTrackColor: color.withOpacity(0.2),
                          thumbColor: color,
                        ),
                        child: Slider(
                          min: 0.0,
                          max: _duration.inMilliseconds.toDouble() > 0 
                              ? _duration.inMilliseconds.toDouble() 
                              : 1.0, // Biar ga error divide by zero
                          value: _position.inMilliseconds.toDouble().clamp(
                              0.0, 
                              _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0
                          ),
                          onChanged: (value) async {
                            // Fitur Seek (Geser Durasi)
                            final newPosition = Duration(milliseconds: value.toInt());
                            await _player.seekToPlayer(newPosition);
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

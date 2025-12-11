import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';

class JournalImageDisplay extends StatelessWidget {
  final String? imageUrl;      // Dari Server
  final String? localPath;     // Dari HP (Baru dibuat offline)
  final double height;
  final double width;

  const JournalImageDisplay({
    super.key,
    this.imageUrl,
    this.localPath,
    this.height = 70,
    this.width = 70,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prioritas: File Lokal (Offline baru)
    if (localPath != null && localPath!.isNotEmpty) {
      return Image.file(
        File(localPath!),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildErrorBox(context),
      );
    }

    // 2. Prioritas: URL Server (Pakai CachedNetworkImage)
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height, width: width,
          color: Theme.of(context).cardTheme.color,
          child: const Center(child: Icon(Icons.image, size: 16, color: Colors.grey)),
        ),
        errorWidget: (context, url, error) => _buildErrorBox(context),
      );
    }

    return const SizedBox(); // Kosong
  }

  Widget _buildErrorBox(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
    );
  }
}
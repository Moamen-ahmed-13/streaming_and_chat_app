import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(fontSize: radius * 0.6),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(imageUrl!),
      onBackgroundImageError: (_, __) {},
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => const SizedBox.shrink(),
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) => Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(fontSize: radius * 0.6),
        ),
      ),
    );
  }
}

class CachedImageBox extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedImageBox({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
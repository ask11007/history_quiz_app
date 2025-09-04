import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  const CustomImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
  }) : super(key: key);

  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _isLocalFile(String url) {
    return url.startsWith('/') && File(url).existsSync();
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: width * 0.6,
            color: Colors.grey[600],
          ),
        );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';

    if (url.isEmpty) {
      return _buildErrorWidget();
    }

    // Handle local file paths
    if (_isLocalFile(url)) {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return _buildErrorWidget();
        },
      );
    }

    // Handle network URLs
    if (_isNetworkUrl(url)) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (context, url, error) {
          print('Error loading network image: $error');
          return _buildErrorWidget();
        },
        placeholder: (context, url) => _buildPlaceholder(),
      );
    }

    // Fallback for invalid URLs
    return _buildErrorWidget();
  }
}

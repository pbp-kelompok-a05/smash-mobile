import 'package:flutter/material.dart';

/// ✅ DefaultAvatar dengan FIXED size untuk mencegah overflow TANPA constraints berlebihan
class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    // ✅ constraints di Container, gunakan SizedBox saja
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        // ✅ Gunakan Center untuk memastikan icon tidak overflow
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.grey.shade500,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// ✅ ALTERNATIF: DefaultAvatar dengan ClipOval untuk safety ekstra
class DefaultAvatar2 extends StatelessWidget {
  const DefaultAvatar2({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.grey.shade500,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// ✅ SOLUSI TERBAIK: SafeAvatar dengan error handling untuk semua kasus
class SafeAvatar extends StatelessWidget {
  const SafeAvatar({
    super.key,
    this.size = 40,
    this.imageUrl,
    this.backgroundColor,
    this.child,
    this.borderWidth = 3,
  });

  final double size;
  final String? imageUrl;
  final Color? backgroundColor;
  final Widget? child;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    // ✅ Cegah size menjadi 0 atau negatif
    final safeSize = size > 0 ? size : 40.0;
    
    // ✅ Jika ada imageUrl, coba load dengan error handling
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildNetworkAvatar(safeSize);
    }
    
    // ✅ Default avatar tanpa image
    return Container(
      width: safeSize,
      height: safeSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: child ?? Icon(
          Icons.person,
          color: Colors.grey.shade500,
          size: safeSize * 0.5,
        ),
      ),
    );
  }

  Widget _buildNetworkAvatar(double safeSize) {
    try {
      return Container(
        width: safeSize,
        height: safeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: borderWidth,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: safeSize,
            height: safeSize,
            fit: BoxFit.cover,
            // ✅ Error handling untuk network image
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackAvatar(safeSize);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // ✅ Fallback jika ada exception saat membangun network avatar
      return _buildFallbackAvatar(safeSize);
    }
  }

  Widget _buildFallbackAvatar(double safeSize) {
    return Container(
      width: safeSize,
      height: safeSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: child ?? Icon(
          Icons.person,
          color: Colors.grey.shade500,
          size: safeSize * 0.5,
        ),
      ),
    );
  }
}

/// ✅ Utility untuk memvalidasi image URL sebelum digunakan
class AvatarUtils {
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      // Cek jika URL valid
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return false;
      }
      
      // Cek panjang URL (prevent overflow)
      if (url.length > 2000) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Widget buildAvatar({
    required String? imageUrl,
    double size = 40,
    Widget? fallback,
    Color? backgroundColor,
  }) {
    // Validasi URL
    final isValid = imageUrl != null && isValidImageUrl(imageUrl);
    
    if (!isValid) {
      return fallback ?? DefaultAvatar(size: size);
    }
    
    // Gunakan SafeAvatar untuk loading dengan error handling
    return SafeAvatar(
      size: size,
      imageUrl: imageUrl,
      backgroundColor: backgroundColor,
      child: fallback != null 
          ? SizedBox(width: size, height: size, child: fallback)
          : null,
    );
  }
}
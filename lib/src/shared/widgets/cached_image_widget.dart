import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// A widget that displays a cached network image with placeholder and error handling
class CachedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String? placeholderPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool isCircle;

  const CachedImageWidget({
    super.key,
    this.imageUrl,
    this.placeholderPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.placeholder,
    this.errorWidget,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else {
      imageWidget = _buildErrorWidget();
    }

    if (isCircle) {
      return ClipOval(
        child: imageWidget,
      );
    } else if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return SizedBox(
        width: width,
        height: height,
        child: placeholder,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? AppColors.primaryTint,
        borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(8)),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: SizedBox(
          width: (width != null ? width! * 0.4 : 40.0).clamp(20.0, 60.0).toDouble(),
          height: (height != null ? height! * 0.4 : 40.0).clamp(20.0, 60.0).toDouble(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? AppColors.primaryTint,
        borderRadius: isCircle ? null : (borderRadius ?? BorderRadius.circular(8)),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: (width != null ? width! * 0.5 : 40.0).clamp(24.0, 80.0).toDouble(),
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
    );
  }
}

/// A circular avatar widget with cached image support
class CachedAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const CachedAvatarWidget({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      width: size,
      height: size,
      isCircle: true,
      placeholderColor: backgroundColor ?? AppColors.primaryTint,
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: initials != null && initials!.isNotEmpty
            ? Center(
                child: Text(
                  initials!,
                  style: TextStyle(
                    color: textColor ?? AppColors.primary,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.5,
                color: textColor ?? AppColors.primary,
              ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: initials != null && initials!.isNotEmpty
            ? Center(
                child: Text(
                  initials!,
                  style: TextStyle(
                    color: textColor ?? AppColors.primary,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.5,
                color: textColor ?? AppColors.primary,
              ),
      ),
    );
  }
}


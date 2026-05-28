import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/text_utils.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.fontSize,
    this.fontWeight = FontWeight.w700,
  });

  final String displayName;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color foregroundColor;
  final double? fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? context.appColors.text,
      backgroundImage:
          hasImage ? CachedNetworkImageProvider(normalizedUrl) : null,
      child: hasImage
          ? null
          : Text(
              initialFor(displayName),
              style: TextStyle(
                color: foregroundColor,
                fontSize: fontSize ?? radius * 0.8,
                fontWeight: fontWeight,
              ),
            ),
    );
  }
}

class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorChild,
  });

  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorChild;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return _wrap(
        errorChild ??
            Container(
              height: height,
              width: width,
              color: context.appColors.soft,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported_outlined),
            ),
      );
    }

    final image = CachedNetworkImage(
      imageUrl: normalizedUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) =>
          placeholder ??
          Container(
            height: height,
            width: width,
            color: context.appColors.soft,
          ),
      errorWidget: (_, __, ___) =>
          errorChild ??
          Container(
            height: height,
            width: width,
            color: context.appColors.soft,
            alignment: Alignment.center,
            child: Icon(Icons.image_not_supported_outlined),
          ),
    );

    return _wrap(image);
  }

  Widget _wrap(Widget child) {
    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}

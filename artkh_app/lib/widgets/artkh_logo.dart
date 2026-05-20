import 'package:flutter/material.dart';

class ArtKhLogo extends StatelessWidget {
  static const double headerSize = 36;

  const ArtKhLogo({
    super.key,
    this.size = headerSize,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/artkh_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

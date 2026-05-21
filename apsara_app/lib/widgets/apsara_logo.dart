import 'package:flutter/material.dart';

class ApsaraLogo extends StatelessWidget {
  static const double headerSize = 36;

  const ApsaraLogo({
    super.key,
    this.size = headerSize,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/apsara_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

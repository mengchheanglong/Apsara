import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TypingDots extends StatelessWidget {
  TypingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.chatIncoming,
        border: Border.all(color: context.appColors.chatIncomingBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Dot(),
          _Dot(),
          _Dot(),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  _Dot();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        radius: 3, backgroundColor: context.appColors.textLight);
  }
}

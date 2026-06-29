import 'package:flutter/material.dart';

class SmallAppLogo extends StatelessWidget {
  const SmallAppLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Image.asset(
        'assets/images/LogoBB.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double opacity;
  const AppGlass({
    super.key,
    required this.child,
    this.radius = 18,
    this.opacity = 0.14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            border: Border.all(color: Colors.white.withOpacity(opacity + 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

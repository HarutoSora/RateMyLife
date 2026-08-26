import 'package:flutter/material.dart';

/// Centralized color palette — the "neon arcade" identity (deep purple
/// space, violet glow, gold/pink/blue gradient accents). Screens must
/// reference these tokens instead of inventing new colors.
class AppColors {
  AppColors._();

  // Grounds
  static const Color background = Color(0xFF0A0620);
  static const Color backgroundGlow = Color(0xFF1B1044);
  static const Color surface = Color(0x99171232);
  static const Color surfaceSolid = Color(0xFF171233);
  static const Color surfaceHigh = Color(0xFF201A48);
  static const Color border = Color(0xFF352A63);
  static const Color borderBright = Color(0xFF6C3CE0);

  // Text
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textMuted = Color(0xFFA79FC4);

  // Brand accents
  static const Color purple = Color(0xFF9B4DFF);
  static const Color purpleDeep = Color(0xFF6C2BD9);
  static const Color pink = Color(0xFFFF3D9A);
  static const Color pinkLight = Color(0xFFFF6FB3);
  static const Color gold = Color(0xFFFFC530);
  static const Color goldDeep = Color(0xFFFF9F1C);
  static const Color blue = Color(0xFF3E8EFF);
  static const Color blueLight = Color(0xFF5EC8FF);
  static const Color cyan = Color(0xFF29D4FF);
  static const Color green = Color(0xFF39FF88);
  static const Color greenDeep = Color(0xFF0FBF6C);
  static const Color neonRed = Color(0xFFFF2E4D);
  static const Color neonRedDeep = Color(0xFFC4001E);

  /// The Nuke feature's own accent — deliberately distinct from
  /// `neonRed` (used elsewhere for destructive/urgent actions like
  /// ending a call) so Nuke reads as its own "hazard" identity.
  static const Color nukeOrange = Color(0xFFFA7308);
  static const Color nukeOrangeDeep = Color(0xFFC85C06);

  // Semantic
  static const Color success = Color(0xFF35D07F);
  static const Color danger = Color(0xFFFF4D6A);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD866), goldDeep],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleDeep],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pinkLight, pink],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueLight, blue],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, greenDeep],
  );

  static const LinearGradient neonRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonRed, neonRedDeep],
  );

  static const LinearGradient nukeOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nukeOrange, nukeOrangeDeep],
  );

  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 1.1,
    colors: [backgroundGlow, background],
  );
}

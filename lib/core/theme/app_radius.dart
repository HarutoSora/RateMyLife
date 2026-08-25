import 'package:flutter/material.dart';

/// Centralized corner radii — chunkier/rounder than a typical utility
/// app, matching the game-like brand identity.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double pill = 100;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}

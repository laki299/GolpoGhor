import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display / Big Titles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.lightTextPrimary,
  );

  // Story / Novel Title
  static const TextStyle storyTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.35,
    color: AppColors.lightTextPrimary,
  );

  // Author Name
  static const TextStyle authorName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.lightTextPrimary,
  );

  // Body Text (Reading)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 1.7,
    color: AppColors.lightTextPrimary,
  );

  // Normal Body
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.lightTextPrimary,
  );

  // Secondary / Caption
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.lightTextSecondary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

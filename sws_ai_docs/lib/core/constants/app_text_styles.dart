import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const heading1 = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const heading2 = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const body = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const caption = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 12,
    color: AppColors.textGrey,
  );

  static const buttonLabel = TextStyle(
    fontFamily: 'Livvic',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

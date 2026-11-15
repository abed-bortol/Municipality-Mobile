import 'package:flutter/material.dart';

/// Brand palette taken from the website (Tailwind slate / teal / cyan).
abstract final class AppColors {
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate400 = Color(0xFF94A3B8);
  static const slate100 = Color(0xFFF1F5F9);

  static const teal600 = Color(0xFF0D9488);
  static const teal500 = Color(0xFF14B8A6);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal300 = Color(0xFF5EEAD4);
  static const teal800 = Color(0xFF115E59);
  static const teal950 = Color(0xFF042F2E);
  static const cyan500 = Color(0xFF06B6D4);

  static const slate500 = Color(0xFF64748B);
  static const slate300 = Color(0xFFCBD5E1);
  static const emerald600 = Color(0xFF059669);

  static const rose400 = Color(0xFFFB7185);
  static const rose300 = Color(0xFFFDA4AF);

  /// Primary action buttons (LoginPage: from-teal-500 to-emerald-600).
  static const actionGradient = LinearGradient(colors: [teal500, emerald600]);

  /// Logo tile gradient (Navbar: bg-gradient-to-tr from-teal-600 to-cyan-500).
  static const brandGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [teal600, cyan500],
  );

  /// App title text gradient (from-white via-slate-100 to-teal-300).
  static const titleGradient = LinearGradient(
    colors: [Colors.white, slate100, teal300],
  );
}

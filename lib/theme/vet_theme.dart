import 'package:flutter/material.dart';

class VetTheme {
  // Paleta de colores pastel (Veterinaria moderna)
  static const Color primary = Color(0xFF4CA6A4);      // Teal/Turquesa suave
  static const Color secondary = Color(0xFF8ED1C4);    // Menta pastel
  static const Color accent = Color(0xFFFFB09C);       // Coral suave para alertas/acentos
  static const Color backgroundStart = Color(0xFFF7FBFB); // Inicio del gradiente de fondo
  static const Color backgroundEnd = Color(0xFFEBF5F3);   // Fin del gradiente de fondo
  
  static const Color textDark = Color(0xFF2C3E50);     // Texto principal oscuro
  static const Color textLight = Color(0xFF7F8C8D);    // Texto secundario claro
  static const Color glassBackground = Color(0xB3FFFFFF); // Fondo semi-transparente para Glassmorphism
  static const Color glassBorder = Color(0x4DFFFFFF);     // Borde semi-transparente para Glassmorphism

  // Gradiente de fondo principal de la aplicación
  static BoxDecoration get backgroundGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundStart, backgroundEnd],
        ),
      );

  // Gradiente para botones primarios
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, Color(0xFF388E8C)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // Tema de Flutter adaptado
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Permite ver el gradiente de fondo
      fontFamily: 'Roboto', // Fuente estándar legible
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: glassBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}

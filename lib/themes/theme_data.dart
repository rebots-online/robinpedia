import 'package:flutter/material.dart';
import 'dart:async';

enum ThemeStyle {
  brutalist,
  skeuomorphic,
  neumorphic,
  glassmorphic,
  material3,
  retroTerminal,
}

class AppTheme {
  final String name;
  final ThemeStyle style;
  final ThemeData themeData;
  final BoxDecoration Function(BuildContext) cardDecoration;
  final BoxDecoration Function(BuildContext) buttonDecoration;
  final TextStyle Function(BuildContext) titleStyle;
  final TextStyle Function(BuildContext) bodyStyle;
  final EdgeInsets cardPadding;
  final EdgeInsets buttonPadding;

  const AppTheme({
    required this.name,
    required this.style,
    required this.themeData,
    required this.cardDecoration,
    required this.buttonDecoration,
    required this.titleStyle,
    required this.bodyStyle,
    required this.cardPadding,
    required this.buttonPadding,
  });
}

class ThemeManager {
  static final Map<ThemeStyle, AppTheme> themes = {
    ThemeStyle.brutalist: AppTheme(
      name: 'Brutalist',
      style: ThemeStyle.brutalist,
      themeData: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.grey[800]!,
          surface: Colors.white,
        ),
        fontFamily: 'Courier',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      titleStyle: (context) => const TextStyle(
        fontFamily: 'Courier',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyStyle: (context) => const TextStyle(
        fontFamily: 'Courier',
        fontSize: 14,
        color: Colors.black,
      ),
      cardPadding: const EdgeInsets.all(16),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    ThemeStyle.skeuomorphic: AppTheme(
      name: 'Skeuomorphic',
      style: ThemeStyle.skeuomorphic,
      themeData: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.grey[800]!,
          secondary: Colors.grey[600]!,
          surface: Colors.grey[100]!,
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[100]!,
          ],
        ),
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[400]!,
          ],
        ),
      ),
      titleStyle: (context) => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        shadows: [
          Shadow(
            color: Colors.white,
            offset: Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      bodyStyle: (context) => TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
      ),
      cardPadding: const EdgeInsets.all(16),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    ThemeStyle.neumorphic: AppTheme(
      name: 'Neumorphic',
      style: ThemeStyle.neumorphic,
      themeData: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.grey[800]!,
          secondary: Colors.grey[600]!,
          surface: Colors.grey[200]!,
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            offset: const Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            offset: const Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      titleStyle: (context) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
      bodyStyle: (context) => TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      cardPadding: const EdgeInsets.all(20),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),

    ThemeStyle.glassmorphic: AppTheme(
      name: 'Glassmorphic',
      style: ThemeStyle.glassmorphic,
      themeData: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.blue[700]!,
          secondary: Colors.blue[500]!,
          surface: Colors.white.withOpacity(0.2),
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.3),
          ],
        ),
      ),
      titleStyle: (context) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
      bodyStyle: (context) => TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      cardPadding: const EdgeInsets.all(20),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),

    ThemeStyle.material3: AppTheme(
      name: 'Material 3',
      style: ThemeStyle.material3,
      themeData: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      titleStyle: (context) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      bodyStyle: (context) => TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      cardPadding: const EdgeInsets.all(16),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    ThemeStyle.retroTerminal: AppTheme(
      name: 'FALLOUT-TERMINAL [2077]',
      style: ThemeStyle.retroTerminal,
      themeData: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF33FF33),  // Brighter green
          secondary: Color(0xFF00CC00),
          surface: Colors.black,
          onPrimary: Color(0xFF33FF33),
          onSecondary: Color(0xFF33FF33),
          onSurface: Color(0xFF33FF33),
        ),
        fontFamily: 'RobotoMono',
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF33FF33),
          selectionColor: const Color(0xFF33FF33).withOpacity(0.3),
          selectionHandleColor: const Color(0xFF33FF33),
        ),
      ),
      cardDecoration: (context) => BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: const Color(0xFF33FF33),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(0),  // Sharp corners
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33FF33).withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 2.5,
          colors: [
            Color(0xFF001100),
            Colors.black,
          ],
          stops: [0.0, 1.0],
        ),
      ),
      buttonDecoration: (context) => BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: const Color(0xFF33FF33),
          width: 1,
        ),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33FF33).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      titleStyle: (context) => const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF33FF33),
        shadows: [
          Shadow(
            color: Color(0xFF33FF33),
            blurRadius: 15,
          ),
        ],
        letterSpacing: 1.2,
      ),
      bodyStyle: (context) => const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 14,
        color: Color(0xFF33FF33),
        shadows: [
          Shadow(
            color: Color(0xFF33FF33),
            blurRadius: 8,
          ),
        ],
        letterSpacing: 0.8,
      ),
      cardPadding: const EdgeInsets.all(16),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  };
}

class RetroScanlineEffect extends StatelessWidget {
  final Widget child;

  const RetroScanlineEffect({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: List.generate(
                  100,
                  (index) => index % 2 == 0
                      ? const Color(0xFF001100).withOpacity(0.1)
                      : Colors.transparent,
                ),
                stops: List.generate(
                  100,
                  (index) => index / 100,
                ),
              ),
            ),
          ),
        ),
        // CRT flicker effect
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  const Color(0xFF33FF33).withOpacity(0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RetroText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool animate;

  const RetroText({
    super.key,
    required this.text,
    required this.style,
    this.animate = true,
  });

  @override
  State<RetroText> createState() => _RetroTextState();
}

class _RetroTextState extends State<RetroText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    if (widget.animate) {
      _startTypingAnimation();
    } else {
      _displayedText = widget.text;
    }
  }

  void _startTypingAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
        _controller.forward(from: 0.0);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style.copyWith(
        shadows: [
          Shadow(
            color: const Color(0xFF33FF33),
            blurRadius: 8 + (_currentIndex % 3) * 2.0, // Subtle glow variation
          ),
        ],
      ),
    );
  }
}

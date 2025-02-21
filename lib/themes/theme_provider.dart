import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_data.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeStyle _currentStyle = ThemeStyle.material3;
  
  ThemeStyle get currentStyle => _currentStyle;
  AppTheme get currentTheme => ThemeManager.themes[_currentStyle]!;

  void setTheme(ThemeStyle style) {
    if (_currentStyle != style) {
      _currentStyle = style;
      notifyListeners();
    }
  }
}

class ThemedContainer extends StatelessWidget {
  final Widget child;
  final bool isCard;
  final bool isButton;
  final VoidCallback? onTap;

  const ThemedContainer({
    super.key,
    required this.child,
    this.isCard = false,
    this.isButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = ThemeManager.themes[themeProvider.currentStyle]!;
    final decoration = isCard
        ? theme.cardDecoration(context)
        : isButton
            ? theme.buttonDecoration(context)
            : null;
    final padding = isCard
        ? theme.cardPadding
        : isButton
            ? theme.buttonPadding
            : EdgeInsets.zero;

    Widget content = Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        child: content,
      );
    }

    if (themeProvider.currentStyle == ThemeStyle.retroTerminal) {
      content = RetroScanlineEffect(child: content);
    }

    return content;
  }
}

class ThemedText extends StatelessWidget {
  final String text;
  final bool isTitle;
  final bool animate;

  const ThemedText(
    this.text, {
    super.key,
    this.isTitle = false,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = ThemeManager.themes[themeProvider.currentStyle]!;
    final style = isTitle ? theme.titleStyle(context) : theme.bodyStyle(context);

    Widget textWidget = themeProvider.currentStyle == ThemeStyle.retroTerminal
        ? RetroText(
            text: text,
            style: style,
            animate: animate,
          )
        : Text(
            text,
            style: style,
          );

    if (themeProvider.currentStyle == ThemeStyle.retroTerminal) {
      textWidget = RetroScanlineEffect(child: textWidget);
    }

    return textWidget;
  }
}

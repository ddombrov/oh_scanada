import 'package:flutter/material.dart';

// Colourblind modes
enum ColourblindMode {
  none,
  protanopia,
  deuteranopia,
  tritanopia,
}

// Theme provider for managing dark mode
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

// Canadian theme colours and styles
class CanadianTheme {
  static const Color canadianRed = Color(0xFFE51837);
  static const Color offWhite = Color(0xFFF8F8F8);
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFE5E5E5);

  static const TextStyle canadianBase = TextStyle(
    color: Colors.white,
    fontFamily: 'Montserrat',
  );

  static TextStyle canadianText({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.0,
    Color? color,
  }) {
    return canadianBase.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color ?? canadianBase.color,
    );
  }

  // Get adjusted colour based on colourblind mode
  static Color getAdjustedColour(Color colour) {
    return ColourblindProvider().transformColour(colour);
  }

  // Convenience getters for adjusted colours
  static Color get adjustedCanadianRed {
    return ColourblindProvider().transformColour(canadianRed);
  }

  static Color get adjustedDarkGrey {
    return ColourblindProvider().transformColour(darkGrey);
  }

  static Color get adjustedOffWhite {
    return ColourblindProvider().transformColour(offWhite);
  }

  static Color get adjustedLightGrey {
    return ColourblindProvider().transformColour(lightGrey);
  }
}

// Colourblind provider for managing colourblind mode
class ColourblindProvider extends ChangeNotifier {
  ColourblindMode _mode = ColourblindMode.none;
  ColourblindMode get mode => _mode;
  static final ColourblindProvider _instance = ColourblindProvider._internal();
  factory ColourblindProvider() => _instance;
  ColourblindProvider._internal();

  void setMode(ColourblindMode mode) {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();
  }

  void setModeFromString(String modeName) {
    ColourblindMode newMode;

    switch (modeName.toLowerCase()) {
      case 'protanopia':
        newMode = ColourblindMode.protanopia;
        break;
      case 'deuteranopia':
        newMode = ColourblindMode.deuteranopia;
        break;
      case 'tritanopia':
        newMode = ColourblindMode.tritanopia;
        break;
      case 'none':
      default:
        newMode = ColourblindMode.none;
        break;
    }

    setMode(newMode);
  }

  // Transform colours based on colourblind mode
  Color transformColour(Color colour) {
    switch (_mode) {
      case ColourblindMode.protanopia:
        return _simulateProtanopia(colour);
      case ColourblindMode.deuteranopia:
        return _simulateDeuteranopia(colour);
      case ColourblindMode.tritanopia:
        return _simulateTritanopia(colour);
      case ColourblindMode.none:
      default:
        return colour;
    }
  }

  // Simulate protanopia (red-blind)
  Color _simulateProtanopia(Color colour) {
    // Convert RGB to LMS colour space
    double r = colour.red / 255.0;
    double g = colour.green / 255.0;
    double b = colour.blue / 255.0;

    // Protanopia simulation matrix (simplified approximation)
    double newR = 0.0 * r + 2.02344 * g + -2.52581 * b;
    double newG = 0.0 * r + 1.0 * g + 0.0 * b;
    double newB = 0.0 * r + 0.0 * g + 1.0 * b;

    // Ensure values are in valid range
    newR = newR.clamp(0.0, 1.0);
    newG = newG.clamp(0.0, 1.0);
    newB = newB.clamp(0.0, 1.0);

    // Convert back to RGB
    return Color.fromRGBO(
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
      colour.opacity,
    );
  }

  // Simulate deuteranopia (green-blind)
  Color _simulateDeuteranopia(Color colour) {
    double r = colour.red / 255.0;
    double g = colour.green / 255.0;
    double b = colour.blue / 255.0;

    // Deuteranopia simulation matrix
    double newR = 1.0 * r + 0.0 * g + 0.0 * b;
    double newG = 0.494207 * r + 0.0 * g + 1.24827 * b;
    double newB = 0.0 * r + 0.0 * g + 1.0 * b;

    newR = newR.clamp(0.0, 1.0);
    newG = newG.clamp(0.0, 1.0);
    newB = newB.clamp(0.0, 1.0);

    return Color.fromRGBO(
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
      colour.opacity,
    );
  }

  // Simulate tritanopia (blue-blind)
  Color _simulateTritanopia(Color colour) {
    double r = colour.red / 255.0;
    double g = colour.green / 255.0;
    double b = colour.blue / 255.0;

    // Tritanopia simulation matrix
    double newR = 1.0 * r + 0.0 * g + 0.0 * b;
    double newG = 0.0 * r + 1.0 * g + 0.0 * b;
    double newB = -0.395913 * r + 0.801109 * g + 0.0 * b;

    newR = newR.clamp(0.0, 1.0);
    newG = newG.clamp(0.0, 1.0);
    newB = newB.clamp(0.0, 1.0);

    return Color.fromRGBO(
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
      colour.opacity,
    );
  }

  // Get colour filter for widget-level transformation
  ColorFilter getColourFilter() {
    switch (_mode) {
      // Red-blind
      case ColourblindMode.protanopia:
        return const ColorFilter.matrix([
          0.567,
          0.433,
          0.0,
          0,
          0,
          0.558,
          0.442,
          0.0,
          0,
          0,
          0.0,
          0.242,
          0.758,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      // Green-blind
      case ColourblindMode.deuteranopia:
        return const ColorFilter.matrix([
          0.625,
          0.375,
          0.0,
          0,
          0,
          0.7,
          0.3,
          0.0,
          0,
          0,
          0.0,
          0.3,
          0.7,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      // Blue-blind
      case ColourblindMode.tritanopia:
        return const ColorFilter.matrix([
          0.95,
          0.05,
          0.0,
          0,
          0,
          0.0,
          0.433,
          0.567,
          0,
          0,
          0.0,
          0.475,
          0.525,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      // Identity matrix - no change
      case ColourblindMode.none:
      default:
        return const ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
    }
  }
}

// Colour adjustment widget for applying colourblind filters
class ColourAdjustment extends StatefulWidget {
  final Widget child;

  const ColourAdjustment({
    super.key,
    required this.child,
  });

  @override
  State<ColourAdjustment> createState() => _ColourAdjustmentState();
}

class _ColourAdjustmentState extends State<ColourAdjustment> {
  final _colourblindProvider = ColourblindProvider();

  @override
  void initState() {
    super.initState();
    _colourblindProvider.addListener(_colourblindListener);
  }

  @override
  void dispose() {
    _colourblindProvider.removeListener(_colourblindListener);
    super.dispose();
  }

  void _colourblindListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = _colourblindProvider.mode;

    // If no colourblind mode is active, return the original child
    if (mode == ColourblindMode.none) {
      return widget.child;
    }

    // Apply colourblind filter
    return ColorFiltered(
      colorFilter: _colourblindProvider.getColourFilter(),
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';

class ColorConstants {
  // Brand Colors
  static const Color primaryColor = Color(0xFF1DBF73);
  static const Color secondaryColor = Color(0xFF36D68B);
  static const Color accentColor = Color(0xFF1DBF73);

  // Add primary property for compatibility
  static const Color primary = primaryColor;

  // Add missing properties
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF404145);

  // Secondary colors
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Neutral colors
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF404145);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color veryLightGrey = Color(0xFFF5F5F5);
  static const Color white = Colors.white;

  // Text colors
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color hintTextColor = Color(0xFF9E9E9E);

  // Surface colors
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Status colors
  static const Color activeColor = Color(0xFF1DBF73);
  static const Color pendingColor = Color(0xFFFFC107);
  static const Color completedColor = Color(0xFF1DBF73);
  static const Color cancelledColor = Color(0xFFFF5252);

  // Gradient colors
  static const List<Color> primaryGradient = [primaryColor, secondaryColor];
  static const List<Color> greenGradient = [
    Color(0xFF1DBF73),
    Color(0xFF36D68B)
  ];

  // Shadow colors
  static Color shadowColor = const Color.fromRGBO(0, 0, 0, 0.1);
  static Color lightShadowColor = const Color.fromRGBO(0, 0, 0, 0.05);
}

// Design System Constants
class SpacingConstants {
  // Spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Common padding values
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // Common margin values
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
}

class BorderRadiusConstants {
  // Border radius scale
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 24.0;

  // Common border radius values
  static const BorderRadius radiusSmall =
      BorderRadius.all(Radius.circular(small));
  static const BorderRadius radiusMedium =
      BorderRadius.all(Radius.circular(medium));
  static const BorderRadius radiusLarge =
      BorderRadius.all(Radius.circular(large));
  static const BorderRadius radiusXLarge =
      BorderRadius.all(Radius.circular(xlarge));
}

class FontSizeConstants {
  // Typography scale
  static const double caption = 12.0;
  static const double body = 14.0;
  static const double subtitle = 16.0;
  static const double title = 20.0;
  static const double heading = 24.0;
  static const double display = 32.0;
}

class ElevationConstants {
  // Elevation scale
  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
  static const double highest = 16.0;
}

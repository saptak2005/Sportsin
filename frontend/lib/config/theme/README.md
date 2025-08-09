# SportsIN Theme System Documentation

## Overview
This document provides comprehensive information about the SportsIN app's theme system, including colors, typography, component styles, and usage guidelines.

## Theme Structure

### 1. App Colors (`app_colors.dart`)
The color palette is designed specifically for sports applications with energetic and professional colors:

#### Primary Colors
- **Primary Blue**: `#1E3A8A` - Main brand color, used for primary actions and branding
- **Primary Blue Light**: `#3B82F6` - Lighter variant for hover states and backgrounds
- **Primary Blue Dark**: `#1E40AF` - Darker variant for pressed states

#### Secondary Colors
- **Secondary Orange**: `#F97316` - Energy and action color, used for CTAs and highlights
- **Secondary Orange Light**: `#FB923C` - Lighter variant
- **Secondary Orange Dark**: `#EA580C` - Darker variant

#### Accent Colors
- **Accent Green**: `#10B981` - Success states, positive indicators
- **Error Red**: `#EF4444` - Error states, negative indicators
- **Warning Yellow**: `#F59E0B` - Warning states, caution indicators

#### Sport-Specific Colors
- **Football Green**: `#22C55E`
- **Basketball Orange**: `#FF8C00`
- **Soccer Blue**: `#0EA5E9`
- **Tennis Yellow**: `#FACC15`
- **Baseball Red**: `#EF4444`

#### Neutral Colors
Complete grayscale from `grey50` to `grey900` for text, backgrounds, and borders.

### 2. Typography (`app_text_styles.dart`)
Based on Material Design 3 typography with sports-specific additions:

#### Display Styles
- `displayLarge`: 57px - Hero headings
- `displayMedium`: 45px - Large headings
- `displaySmall`: 36px - Medium headings

#### Headline Styles
- `headlineLarge`: 32px, FontWeight.w600 - Page titles
- `headlineMedium`: 28px, FontWeight.w600 - Section titles
- `headlineSmall`: 24px, FontWeight.w600 - Subsection titles

#### Title Styles
- `titleLarge`: 22px, FontWeight.w500 - Card titles
- `titleMedium`: 16px, FontWeight.w500 - List item titles
- `titleSmall`: 14px, FontWeight.w500 - Small titles

#### Body Styles
- `bodyLarge`: 16px - Main body text
- `bodyMedium`: 14px - Secondary body text
- `bodySmall`: 12px - Captions and metadata

#### Button Styles
- `buttonLarge`: 16px, FontWeight.w600 - Large buttons
- `buttonMedium`: 14px, FontWeight.w600 - Standard buttons
- `buttonSmall`: 12px, FontWeight.w600 - Small buttons

#### Sports-Specific Styles
- `sportScoreLarge`: 48px, FontWeight.w800 - Large score displays
- `sportScoreMedium`: 32px, FontWeight.w700 - Medium score displays
- `teamName`: 18px, FontWeight.w600 - Team names
- `matchTime`: 16px, FontWeight.w500 - Match timing information

### 3. Theme Data (`app_theme.dart`)
Complete theme configuration including:

#### Component Themes
- **AppBar**: Primary blue background with white text
- **Buttons**: Rounded corners (12px), proper spacing, and color variants
- **Input Fields**: Filled style with rounded borders, focus states
- **Cards**: Elevated with rounded corners (16px) and subtle shadows
- **Chips**: Rounded (20px) with selection states
- **Navigation**: Bottom navigation with proper color states

#### Material 3 Support
- Full ColorScheme implementation
- Proper light/dark theme support
- Material You compatibility

### 4. Sports Extensions (`sports_theme_extensions.dart`)
Specialized decorations and utilities for sports-specific components:

#### Sport Color Mapping
```dart
SportsThemeExtensions.getSportColor('football') // Returns football green
```

#### Specialized Decorations
- **Score Cards**: Gradient backgrounds with shadows
- **Team Cards**: Clean borders with subtle elevation
- **Match Status**: Color-coded status indicators (live, upcoming, finished)
- **Leaderboards**: Success gradient styling
- **Achievement Badges**: Tiered styling (bronze, silver, gold)
- **Win/Loss Indicators**: Green for wins, red for losses

## Usage Guidelines

### 1. Importing the Theme
```dart
import 'config/theme/theme.dart'; // Imports everything
// or specific files:
import 'config/theme/app_colors.dart';
import 'config/theme/app_text_styles.dart';
```

### 2. Using Colors
```dart
Container(
  color: AppColors.primaryBlue,
  child: Text(
    'SportsIN',
    style: AppTextStyles.headlineLarge.copyWith(
      color: AppColors.textOnPrimary,
    ),
  ),
)
```

### 3. Using Sports Extensions
```dart
Container(
  decoration: SportsThemeExtensions.scoreCardDecoration,
  child: Text(
    '3-1',
    style: AppTextStyles.sportScoreLarge,
  ),
)
```

### 4. Theme Context Access
```dart
// Access theme colors through context
final colors = Theme.of(context).colorScheme;
final textTheme = Theme.of(context).textTheme;

Container(
  color: colors.primary,
  child: Text(
    'Dynamic Theme Text',
    style: textTheme.headlineMedium,
  ),
)
```

## Best Practices

### 1. Color Usage
- Use `AppColors` constants for consistent theming
- Prefer theme context colors for dynamic theming
- Use sport-specific colors only for sport-related content
- Maintain proper contrast ratios (WCAG AA compliance)

### 2. Typography
- Use semantic text styles (headline, body, etc.)
- Avoid hardcoded font sizes
- Use `copyWith()` for style modifications
- Maintain consistent line heights and letter spacing

### 3. Component Styling
- Leverage existing component themes before custom styling
- Use theme decorations from sports extensions
- Maintain consistent border radius and elevation patterns
- Follow Material Design 3 principles

### 4. Responsive Design
- Text styles scale appropriately across devices
- Use relative sizing where possible
- Test themes on different screen sizes
- Consider accessibility requirements

## Dark Theme Support
The theme system includes full dark theme support:
- Automatic color scheme adaptation
- Proper contrast maintenance
- Surface color variations
- Icon and text color adjustments

Access through:
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Follows system preference
)
```

## Customization
To customize the theme:

1. **Modify Colors**: Update `app_colors.dart` constants
2. **Update Typography**: Adjust styles in `app_text_styles.dart`
3. **Component Themes**: Modify component configurations in `app_theme.dart`
4. **Sports Elements**: Add/modify decorations in `sports_theme_extensions.dart`

## Migration Guide
When updating from the previous theme:
1. Replace hardcoded colors with `AppColors` constants
2. Update text styles to use `AppTextStyles`
3. Apply component themes through `Theme.of(context)`
4. Use sports extensions for specialized components

This theme system provides a robust foundation for consistent, accessible, and maintainable UI across the SportsIN application.

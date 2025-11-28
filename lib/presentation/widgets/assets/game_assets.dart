import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paths to generated game assets.
///
/// Assets are generated via `python3 tool/generate_sd_assets.py` using
/// Stable Diffusion (DreamShaper XL Lightning model). If assets are not
/// available, widgets should gracefully fall back to icon/color-based rendering.
class GameAssetPaths {
  static const String basePath = 'assets/images';

  // App branding
  static const String appIcon = '$basePath/app_icon.png';
  static const String beeMascot = '$basePath/bee_mascot.png';

  // Backgrounds
  static const String splashBackground = '$basePath/splash_background.png';
  static const String victoryBackground = '$basePath/victory_background.png';
  static const String headerBanner = '$basePath/header_banner.png';

  // Level cell button
  static const String levelButton = '$basePath/level_button.png';
  static const String levelButtonHover = '$basePath/level_button_hover.png';

  // Hexagonal cell states
  static const String hexCellUnvisited = '$basePath/hex_cell_unvisited.png';
  static const String hexCellVisited = '$basePath/hex_cell_visited.png';
  static const String hexCellStart = '$basePath/hex_cell_start.png';
  static const String hexCellEnd = '$basePath/hex_cell_end.png';

  // Icons
  static const String lockIcon = '$basePath/lock_icon.png';
  static const String starFilled = '$basePath/star_filled.png';
  static const String starEmpty = '$basePath/star_empty.png';
  static const String trophyIcon = '$basePath/trophy_icon.png';
  static const String checkmarkIcon = '$basePath/icon_checkmark.png';

  // Navigation buttons
  static const String buttonPlay = '$basePath/button_play.png';
  static const String buttonRetry = '$basePath/button_retry.png';
  static const String buttonNext = '$basePath/button_next.png';
  static const String buttonBack = '$basePath/button_back.png';
  static const String buttonMenu = '$basePath/button_menu.png';

  // Settings icons
  static const String iconSettings = '$basePath/icon_settings.png';
  static const String iconSoundOn = '$basePath/icon_sound_on.png';
  static const String iconSoundOff = '$basePath/icon_sound_off.png';
  static const String iconInfo = '$basePath/icon_info.png';

  // Decorations
  static const String honeyDrip = '$basePath/honey_drip.png';
  static const String progressFill = '$basePath/progress_fill.png';
}

/// Utility for loading game assets with fallback support.
///
/// Checks if assets exist at runtime and provides widgets that
/// gracefully fall back to programmatic rendering when assets
/// are unavailable.
class GameAssets {
  /// Cache of asset availability checks.
  static final Map<String, bool> _assetCache = {};

  /// Checks if an asset exists and is loadable.
  static Future<bool> assetExists(String path) async {
    if (_assetCache.containsKey(path)) {
      return _assetCache[path]!;
    }

    try {
      await rootBundle.load(path);
      _assetCache[path] = true;
      return true;
    } catch (_) {
      _assetCache[path] = false;
      return false;
    }
  }

  /// Clears the asset cache (useful for hot reload).
  static void clearCache() {
    _assetCache.clear();
  }
}

/// Widget that displays an asset image with a fallback widget.
///
/// Attempts to load the image from [assetPath]. If the asset is not
/// available, displays [fallback] instead.
class AssetImageWithFallback extends StatefulWidget {
  /// Path to the asset image.
  final String assetPath;

  /// Widget to display if the asset is not available.
  final Widget fallback;

  /// Width of the image (optional).
  final double? width;

  /// Height of the image (optional).
  final double? height;

  /// How to fit the image within its bounds.
  final BoxFit fit;

  const AssetImageWithFallback({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<AssetImageWithFallback> createState() => _AssetImageWithFallbackState();
}

class _AssetImageWithFallbackState extends State<AssetImageWithFallback> {
  bool? _assetExists;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  @override
  void didUpdateWidget(AssetImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _checkAsset();
    }
  }

  Future<void> _checkAsset() async {
    final exists = await GameAssets.assetExists(widget.assetPath);
    if (mounted) {
      setState(() => _assetExists = exists);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_assetExists == null) {
      // Still checking - show fallback to avoid flicker
      return widget.fallback;
    }

    if (_assetExists!) {
      return Image.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => widget.fallback,
      );
    }

    return widget.fallback;
  }
}

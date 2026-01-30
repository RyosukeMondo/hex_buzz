/// Hexagonal grid widget components.
///
/// This library exports all hex grid components in a clean,
/// decomposed architecture following single responsibility principle.
///
/// Main components:
/// - [HexGridWidget]: Main composition root
/// - [HexGridLayout]: Layout calculations
/// - [HexGridRenderer]: Visual rendering
/// - [HexGridGestureHandler]: User interactions
/// - [HexGridAnimator]: Cell animations
/// - [HexGridTheme]: Styling configuration
library hex_grid;

export 'hex_grid/hex_grid_animator.dart';
export 'hex_grid/hex_grid_gesture_handler.dart';
export 'hex_grid/hex_grid_layout.dart';
export 'hex_grid/hex_grid_renderer.dart';
export 'hex_grid/hex_grid_theme.dart';
export 'hex_grid/hex_grid_widget.dart';

# Track 2: Widget Decomposition

**Status:** ready
**Priority:** high
**Parent Spec:** `../spec.md`
**Effort:** Medium (4-6 hours)
**Risk:** Medium (UI rendering changes)

## Objective

Refactor `hex_grid_widget.dart` (509 lines) into smaller, composable, testable widgets following single responsibility principle.

## Problem Statement

`hex_grid_widget.dart` violates the 500-line guideline and has multiple responsibilities:
1. Grid layout and positioning
2. Hex cell rendering
3. Gesture handling (tap, hover, drag)
4. Path animation
5. State management (selection, hover states)
6. Color theming and styling

**Current Size:** 509 lines
**Target Size:** <150 lines (main widget), <100 lines per component

## Architecture

### Current Structure (Monolithic)
```
HexGridWidget (509 lines)
├── Grid layout calculation
├── Cell rendering
├── Gesture detection
├── Animation logic
└── State management
```

### Target Structure (Composed)
```
HexGridWidget (120 lines) - Composition root
├── HexGridLayout (80 lines) - Positioning & sizing
├── HexGridRenderer (90 lines) - Visual rendering
├── HexGridGestureHandler (110 lines) - User interactions
├── HexGridAnimator (70 lines) - Path animations
└── HexGridTheme (40 lines) - Styling & colors
```

## Implementation Tasks

### Task 1: Analyze Current Implementation
Read and understand `hex_grid_widget.dart`:
- Identify all responsibilities
- Map dependencies between responsibilities
- Identify state management patterns
- Document current behavior

### Task 2: Extract HexGridLayout
**Responsibility:** Calculate hex positions, grid sizing, coordinate transformations

```dart
/// Handles hexagonal grid layout calculations and positioning
class HexGridLayout {
  final int gridSize;
  final double cellRadius;
  final HexCoordinate origin;

  Size calculateGridSize();
  Offset hexToPixel(HexCoordinate coord);
  HexCoordinate? pixelToHex(Offset position);
  List<HexCoordinate> getVisibleCoordinates();
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_layout.dart`
- `test/presentation/widgets/hex_grid_layout_test.dart`

### Task 3: Extract HexGridRenderer
**Responsibility:** Render hex cells, paths, highlights

```dart
/// Renders hexagonal grid visually
class HexGridRenderer extends StatelessWidget {
  final HexGridLayout layout;
  final GameState gameState;
  final HexGridTheme theme;
  final Set<HexCoordinate> hoveredCells;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HexGridPainter(
        layout: layout,
        cells: gameState.cells,
        path: gameState.currentPath,
        theme: theme,
        hoveredCells: hoveredCells,
      ),
    );
  }
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_renderer.dart`
- `lib/presentation/widgets/hex_grid/hex_grid_painter.dart`
- `test/presentation/widgets/hex_grid_renderer_test.dart`

### Task 4: Extract HexGridGestureHandler
**Responsibility:** Handle user gestures (tap, hover, drag)

```dart
/// Handles user interactions with hex grid
class HexGridGestureHandler extends StatefulWidget {
  final HexGridLayout layout;
  final ValueChanged<HexCoordinate>? onCellTap;
  final ValueChanged<HexCoordinate?>? onCellHover;
  final Widget child;

  @override
  State<HexGridGestureHandler> createState() => _HexGridGestureHandlerState();
}

class _HexGridGestureHandlerState extends State<HexGridGestureHandler> {
  HexCoordinate? _hoveredCell;

  void _handlePointerMove(PointerMoveEvent event) {
    final cell = widget.layout.pixelToHex(event.localPosition);
    if (cell != _hoveredCell) {
      setState(() => _hoveredCell = cell);
      widget.onCellHover?.call(cell);
    }
  }

  void _handleTap(TapUpDetails details) {
    final cell = widget.layout.pixelToHex(details.localPosition);
    if (cell != null) {
      widget.onCellTap?.call(cell);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      child: MouseRegion(
        onHover: _handlePointerMove,
        child: widget.child,
      ),
    );
  }
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_gesture_handler.dart`
- `test/presentation/widgets/hex_grid_gesture_handler_test.dart`

### Task 5: Extract HexGridAnimator
**Responsibility:** Animate path drawing, cell transitions

```dart
/// Animates hex grid transitions
class HexGridAnimator extends StatefulWidget {
  final List<HexCoordinate> path;
  final Duration duration;
  final Widget Function(List<HexCoordinate> visiblePath) builder;

  @override
  State<HexGridAnimator> createState() => _HexGridAnimatorState();
}

class _HexGridAnimatorState extends State<HexGridAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final visibleCount = (_animation.value * widget.path.length).round();
        final visiblePath = widget.path.take(visibleCount).toList();
        return widget.builder(visiblePath);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_animator.dart`
- `test/presentation/widgets/hex_grid_animator_test.dart`

### Task 6: Extract HexGridTheme
**Responsibility:** Theme data for hex grid styling

```dart
/// Theme configuration for hex grid
@immutable
class HexGridTheme {
  final Color pathColor;
  final Color startColor;
  final Color endColor;
  final Color checkpointColor;
  final Color hoveredColor;
  final Color invalidColor;
  final double strokeWidth;
  final double cellOpacity;

  const HexGridTheme({
    required this.pathColor,
    required this.startColor,
    required this.endColor,
    required this.checkpointColor,
    required this.hoveredColor,
    required this.invalidColor,
    this.strokeWidth = 3.0,
    this.cellOpacity = 0.8,
  });

  factory HexGridTheme.fromColorScheme(ColorScheme scheme) {
    return HexGridTheme(
      pathColor: scheme.primary,
      startColor: scheme.secondary,
      endColor: scheme.tertiary,
      checkpointColor: scheme.primaryContainer,
      hoveredColor: scheme.surfaceContainerHighest,
      invalidColor: scheme.error,
    );
  }
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_theme.dart`
- `test/presentation/widgets/hex_grid_theme_test.dart`

### Task 7: Create Composed HexGridWidget
**Responsibility:** Compose all components into cohesive widget

```dart
/// Main hexagonal grid widget - composes all hex grid components
class HexGridWidget extends StatefulWidget {
  final GameState gameState;
  final ValueChanged<HexCoordinate>? onCellTap;
  final double cellRadius;

  const HexGridWidget({
    Key? key,
    required this.gameState,
    this.onCellTap,
    this.cellRadius = 30.0,
  }) : super(key: key);

  @override
  State<HexGridWidget> createState() => _HexGridWidgetState();
}

class _HexGridWidgetState extends State<HexGridWidget> {
  late HexGridLayout _layout;
  late HexGridTheme _theme;
  Set<HexCoordinate> _hoveredCells = {};

  @override
  void initState() {
    super.initState();
    _layout = HexGridLayout(
      gridSize: widget.gameState.level.gridSize,
      cellRadius: widget.cellRadius,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = HexGridTheme.fromColorScheme(Theme.of(context).colorScheme);
  }

  void _handleCellHover(HexCoordinate? cell) {
    setState(() {
      _hoveredCells = cell != null ? {cell} : {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return HexGridGestureHandler(
      layout: _layout,
      onCellTap: widget.onCellTap,
      onCellHover: _handleCellHover,
      child: HexGridAnimator(
        path: widget.gameState.currentPath,
        duration: const Duration(milliseconds: 300),
        builder: (animatedPath) => HexGridRenderer(
          layout: _layout,
          gameState: widget.gameState.copyWith(currentPath: animatedPath),
          theme: _theme,
          hoveredCells: _hoveredCells,
        ),
      ),
    );
  }
}
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid/hex_grid_widget.dart` (refactored)
- `test/presentation/widgets/hex_grid_widget_test.dart` (enhanced)

### Task 8: Create Barrel Export
Create `hex_grid.dart` for clean imports:

```dart
/// Hexagonal grid widget components
library hex_grid;

export 'hex_grid/hex_grid_widget.dart';
export 'hex_grid/hex_grid_layout.dart';
export 'hex_grid/hex_grid_renderer.dart';
export 'hex_grid/hex_grid_gesture_handler.dart';
export 'hex_grid/hex_grid_animator.dart';
export 'hex_grid/hex_grid_theme.dart';
```

**Files to Create:**
- `lib/presentation/widgets/hex_grid.dart`

### Task 9: Update Imports
Update all files that import `hex_grid_widget.dart`:

```dart
// ❌ Before
import 'package:hex_buzz/presentation/widgets/hex_grid_widget.dart';

// ✅ After
import 'package:hex_buzz/presentation/widgets/hex_grid.dart';
```

**Files to Check:**
- `lib/presentation/screens/game_screen.dart`
- `lib/presentation/screens/daily_challenge_screen.dart`
- Any other files importing hex_grid_widget

### Task 10: Comprehensive Testing

**Test Coverage Requirements:**
- Each component: 100% line coverage
- Integration test: All components working together
- Golden tests: Visual regression testing

**Tests to Create:**
1. `hex_grid_layout_test.dart` - Layout calculations
2. `hex_grid_renderer_test.dart` - Rendering logic
3. `hex_grid_gesture_handler_test.dart` - Gesture handling
4. `hex_grid_animator_test.dart` - Animation behavior
5. `hex_grid_theme_test.dart` - Theme configuration
6. `hex_grid_widget_test.dart` - Full integration

**Golden Tests:**
```dart
testWidgets('renders hex grid correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HexGridWidget(
        gameState: testGameState,
      ),
    ),
  );

  await expectLater(
    find.byType(HexGridWidget),
    matchesGoldenFile('goldens/hex_grid_default.png'),
  );
});
```

## File Structure

```
lib/presentation/widgets/
├── hex_grid.dart (barrel export)
└── hex_grid/
    ├── hex_grid_widget.dart (120 lines)
    ├── hex_grid_layout.dart (80 lines)
    ├── hex_grid_renderer.dart (90 lines)
    ├── hex_grid_painter.dart (100 lines)
    ├── hex_grid_gesture_handler.dart (110 lines)
    ├── hex_grid_animator.dart (70 lines)
    └── hex_grid_theme.dart (40 lines)

test/presentation/widgets/
└── hex_grid/
    ├── hex_grid_widget_test.dart
    ├── hex_grid_layout_test.dart
    ├── hex_grid_renderer_test.dart
    ├── hex_grid_gesture_handler_test.dart
    ├── hex_grid_animator_test.dart
    └── hex_grid_theme_test.dart
    └── goldens/
        ├── hex_grid_default.png
        ├── hex_grid_with_path.png
        └── hex_grid_hovered.png
```

## Success Criteria

- [ ] `hex_grid_widget.dart` reduced to <150 lines
- [ ] All extracted components <100 lines each
- [ ] Each component has single, clear responsibility
- [ ] All components are independently testable
- [ ] Test coverage: 100% for all components
- [ ] Golden tests for visual regression
- [ ] No behavioral changes (UI looks identical)
- [ ] No performance regressions
- [ ] All existing tests pass

## Testing Strategy

### Unit Tests
- Test each component in isolation
- Mock dependencies
- Test edge cases

### Integration Tests
- Test components working together
- Test gesture handling end-to-end
- Test animation behavior

### Visual Regression Tests
- Golden file tests for rendering
- Compare before/after screenshots
- Test various grid sizes and states

### Performance Tests
```dart
test('rendering performance', () {
  final stopwatch = Stopwatch()..start();

  // Render large grid
  final layout = HexGridLayout(gridSize: 15);
  final cells = generateTestCells(15);

  // Measure rendering time
  for (var i = 0; i < 100; i++) {
    layout.calculateGridSize();
  }

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

## Rollback Plan

If refactoring causes issues:
1. Keep original `hex_grid_widget.dart` as `hex_grid_widget_legacy.dart`
2. Revert to legacy version if needed
3. Debug component issues
4. Reapply refactoring with fixes

## Dependencies

- `flutter_test` (existing)
- Golden file infrastructure
- No new external dependencies

## Completion Checklist

- [ ] Task 1: Current implementation analyzed
- [ ] Task 2: HexGridLayout extracted and tested
- [ ] Task 3: HexGridRenderer extracted and tested
- [ ] Task 4: HexGridGestureHandler extracted and tested
- [ ] Task 5: HexGridAnimator extracted and tested
- [ ] Task 6: HexGridTheme extracted and tested
- [ ] Task 7: Composed HexGridWidget created
- [ ] Task 8: Barrel export created
- [ ] Task 9: All imports updated
- [ ] Task 10: Comprehensive tests added
- [ ] Golden tests pass
- [ ] All existing tests pass
- [ ] Visual verification complete
- [ ] Performance benchmarks pass
- [ ] Code review completed
- [ ] Documentation updated

## Estimated Timeline

- Analysis: 1 hour
- Extract layout: 1 hour
- Extract renderer: 1 hour
- Extract gesture handler: 1 hour
- Extract animator: 45 minutes
- Extract theme: 30 minutes
- Compose widget: 1 hour
- Testing: 2 hours
- Review and fixes: 1 hour

**Total: 4-6 hours**

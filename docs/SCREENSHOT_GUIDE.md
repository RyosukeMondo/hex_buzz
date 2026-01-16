# Screenshot Creation Guide for Microsoft Store

This guide provides detailed instructions for creating high-quality screenshots for the HexBuzz Microsoft Store submission.

## Requirements

### Technical Requirements
- **Minimum Screenshots**: 4 (required)
- **Recommended Screenshots**: 6-8 (optimal conversion)
- **Maximum Screenshots**: 10
- **Format**: PNG (preferred) or JPEG
- **File Size**: Maximum 50 MB per image
- **Resolution Options**:
  - 1366 × 768 (minimum, widely compatible)
  - **1920 × 1080 (recommended, Full HD)**
  - 2560 × 1440 (2K)
  - 3840 × 2160 (4K)

### Content Requirements
- Must show actual app interface (no mockups)
- No device frames or borders
- No marketing text overlay
- No debug UI or developer tools
- Clean, polished interface
- Highlight key features
- Show diverse content

## Screenshot Plan

### Screenshot 1: Level Select Screen
**Filename**: `screenshot_01_level_select.png`

**Purpose**: First impression - show game structure and progression

**What to Capture**:
- Full level select grid
- Multiple difficulty levels visible (4×4 through 16×16)
- Star ratings on completed levels
- Clean, organized interface
- App branding/title

**How to Capture**:
1. Launch app in release mode
2. Navigate to level select (main menu)
3. Ensure some levels show completion stars
4. Capture at 1920×1080

**Key Elements**:
- Shows game structure at a glance
- Demonstrates progressive difficulty
- Highlights achievement system (stars)
- Clean, accessible interface

---

### Screenshot 2: Tutorial/Easy Gameplay
**Filename**: `screenshot_02_easy_puzzle.png`

**Purpose**: Show gameplay mechanics and ease of entry

**What to Capture**:
- 4×4 or 6×6 honeycomb puzzle
- Path partially drawn (about 50% complete)
- Visual effects on the path visible
- Numbered checkpoints clearly visible (0, 1, 2, 3...)
- Undo/Reset buttons visible

**How to Capture**:
1. Start a 4×4 or 6×6 level
2. Draw path to about halfway
3. Ensure visual effects are visible
4. Capture while path animation is active

**Key Elements**:
- Demonstrates core mechanic (path drawing)
- Shows honeycomb structure
- Visual effects preview
- Easy to understand gameplay

---

### Screenshot 3: Medium Difficulty Puzzle
**Filename**: `screenshot_03_medium_puzzle.png`

**Purpose**: Show depth and challenge level

**What to Capture**:
- 8×8 or 10×10 honeycomb puzzle
- Path 70-80% complete
- More complex path pattern
- Visual effects prominent
- Star counter visible

**How to Capture**:
1. Start an 8×8 or 10×10 level
2. Draw most of the path
3. Show interesting path pattern
4. Capture with effects active

**Key Elements**:
- Demonstrates increased complexity
- Shows engaging challenge
- More intricate visual effects
- Appeals to puzzle enthusiasts

---

### Screenshot 4: Completion Celebration
**Filename**: `screenshot_04_celebration.png`

**Purpose**: Show satisfaction and reward system

**What to Capture**:
- Completed puzzle with full path drawn
- Celebration effects/animations in progress
- Star rating displayed (3 stars ideally)
- Completion time shown
- "Level Complete" overlay or similar

**How to Capture**:
1. Complete a medium-difficulty level
2. Capture during celebration animation
3. Ensure star rating is visible
4. Show completion overlay if present

**Key Elements**:
- Demonstrates reward/feedback
- Shows visual polish
- Achievement satisfaction
- Motivates players

---

### Screenshot 5: Daily Challenge (Optional but Recommended)
**Filename**: `screenshot_05_daily_challenge.png`

**Purpose**: Highlight competitive/social features

**What to Capture**:
- Daily challenge interface
- Challenge date visible
- Leaderboard showing player rankings
- Your position highlighted (if possible)
- "Today's Challenge" branding

**How to Capture**:
1. Navigate to daily challenge screen
2. If leaderboard available, show it
3. Highlight competitive element
4. Capture clean interface

**Key Elements**:
- Shows social/competitive features
- Demonstrates daily engagement hook
- Leaderboard visibility
- Community aspect

---

### Screenshot 6: Advanced Puzzle (Optional but Recommended)
**Filename**: `screenshot_06_advanced.png`

**Purpose**: Show content depth for hardcore players

**What to Capture**:
- 14×14 or 16×16 puzzle
- Complex path pattern
- Challenge level evident
- Visual effects impressive

**How to Capture**:
1. Start a large (14×14 or 16×16) level
2. Draw complex path pattern
3. Show impressive scale
4. Capture with effects

**Key Elements**:
- Appeals to hardcore puzzlers
- Shows content depth
- Demonstrates scalability
- "End-game" content preview

---

## Step-by-Step Capture Process

### Prerequisites

1. **Build Release Version**
   ```bash
   flutter build windows --release
   ```

2. **Launch Application**
   ```bash
   ./build/windows/x64/runner/Release/hex_buzz.exe
   ```

3. **Verify Settings**
   - Visual effects: ON
   - Resolution: 1920×1080 or higher
   - No debug banners
   - Clean interface

### Capture Methods

#### Method 1: Windows Game Bar (Recommended)
1. Press `Win + G` to open Game Bar
2. Click Screenshot button (camera icon)
3. Or press `Win + Alt + PrtScn`
4. Screenshots saved to: `Videos/Captures/`

**Pros**: Easy, no extra software, captures at native resolution

#### Method 2: Snipping Tool
1. Press `Win + Shift + S`
2. Select area to capture
3. Automatically copies to clipboard
4. Paste into image editor
5. Save as PNG

**Pros**: Precise area selection, built-in

#### Method 3: OBS Studio
1. Install OBS Studio (free)
2. Set up window capture
3. Take screenshot via hotkey
4. Saves to configured folder

**Pros**: Professional control, consistent quality

### Post-Capture Processing

1. **Verify Resolution**
   ```bash
   # Check image dimensions
   # Should be exactly 1920×1080
   ```

2. **Verify File Size**
   - Should be under 50 MB
   - PNG: typically 2-5 MB
   - JPEG: typically 500 KB - 2 MB

3. **Verify Quality**
   - No compression artifacts
   - No blur or scaling issues
   - Colors accurate
   - Text readable

4. **Crop if Needed**
   - Remove borders
   - Ensure 16:9 aspect ratio (1920×1080)
   - Use image editor if necessary

5. **Optimize (Optional)**
   ```bash
   # Use optipng for PNG compression
   optipng -o7 screenshot.png

   # Or pngquant for lossy compression
   pngquant --quality=90-100 screenshot.png
   ```

## Directory Structure

Create directory for screenshots:

```bash
mkdir -p assets/store/screenshots
```

**File naming convention**:
```
assets/store/screenshots/
├── screenshot_01_level_select.png
├── screenshot_02_easy_puzzle.png
├── screenshot_03_medium_puzzle.png
├── screenshot_04_celebration.png
├── screenshot_05_daily_challenge.png (optional)
└── screenshot_06_advanced.png (optional)
```

## Quality Checklist

Before uploading to Partner Center:

### Technical Quality
- [ ] Resolution exactly 1920×1080 (or chosen resolution)
- [ ] File format is PNG or JPEG
- [ ] File size under 50 MB per image
- [ ] 16:9 aspect ratio maintained
- [ ] No scaling artifacts or blur
- [ ] Colors accurate and vibrant

### Content Quality
- [ ] Shows actual app interface (no mockups)
- [ ] No debug UI, banners, or overlays
- [ ] No device frames or borders
- [ ] No marketing text overlay
- [ ] Interface is clean and polished
- [ ] Text is readable
- [ ] Visual effects visible (where applicable)

### Diversity
- [ ] Shows different difficulty levels
- [ ] Demonstrates core gameplay
- [ ] Highlights visual polish
- [ ] Shows progression/achievements
- [ ] Includes social/competitive features (if available)

### First Impression
- [ ] Screenshot 1 is most impressive
- [ ] Clear what the game is about
- [ ] Visually appealing
- [ ] Professional presentation

## Tips for Best Results

### Timing
1. **Capture During Animation**
   - Visual effects look best in motion
   - Capture at peak of animation
   - May need multiple attempts

2. **Use Good Lighting**
   - Bright, clear interface
   - High contrast for readability
   - Avoid dark/dim screenshots

### Composition
1. **Focus on Key Elements**
   - Honeycomb grid should be prominent
   - Path drawing should be visible
   - UI elements clear but not distracting

2. **Show Action**
   - Path partially drawn (not empty, not complete)
   - Effects active
   - Engaging moment

3. **Balance**
   - Not too cluttered
   - Not too empty
   - Just right amount of visual interest

### Common Mistakes to Avoid
- ❌ Capturing debug/development UI
- ❌ Low resolution or wrong aspect ratio
- ❌ Compression artifacts from JPEG over-compression
- ❌ Boring screenshots (empty grids, no action)
- ❌ Too many similar screenshots
- ❌ First screenshot isn't the best one
- ❌ Text too small to read
- ❌ Dark or low-contrast images

## After Capturing

1. **Review All Screenshots**
   - Open all images side-by-side
   - Ensure variety and quality
   - Verify they tell a story

2. **Order Matters**
   - Screenshot 1: Most important (search results)
   - Screenshot 2-3: Gameplay demonstration
   - Screenshot 4-6: Features and depth
   - Put best foot forward!

3. **Get Feedback**
   - Show to friends/colleagues
   - Ask: "What do you think this game is about?"
   - Verify clarity and appeal

4. **Prepare for Upload**
   - Copy to easily accessible folder
   - Verify filenames are descriptive
   - Keep originals backed up

## Alternative: Video Capture

Microsoft Store also accepts promotional videos.

**If creating video**:
- Length: 30-60 seconds
- Format: MP4, MOV, or WMV
- Resolution: 1920×1080 (1080p)
- Show gameplay montage
- Add text overlays for key features
- Use upbeat background music
- No voiceover necessary

**Note**: Video is optional but can increase conversion rates.

## Automation (Advanced)

For AI agents or automated screenshot capture:

```bash
# Launch app in headless mode (if supported)
flutter run -d windows --release

# Use PowerShell to capture window
# (Requires additional scripting)
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Capture active window
# Save as PNG at 1920×1080
# (Full script available on request)
```

## Resources

- **Microsoft Screenshot Guidelines**: https://learn.microsoft.com/windows/apps/publish/app-screenshots-and-images
- **Image Optimization**: https://tinypng.com/ or https://squoosh.app/
- **OBS Studio**: https://obsproject.com/
- **GIMP** (free editor): https://www.gimp.org/

## Support

If you encounter issues:
- Resolution problems: Check display settings, ensure 1920×1080
- Capture quality: Use PNG format, avoid JPEG compression
- File size: Optimize with pngquant or TinyPNG
- Content questions: Refer to screenshot plan above

## Next Steps

After creating screenshots:
1. Verify all images meet requirements
2. Save to `assets/store/screenshots/`
3. Prepare for Partner Center upload
4. Keep originals for future updates
5. Create promotional video (optional)

---

**Screenshot creation is one of the most important parts of your Store listing. Take your time to create high-quality, representative images that showcase HexBuzz's best features!**

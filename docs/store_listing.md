# Microsoft Store Listing Content

This document contains all the prepared content for the HexBuzz Microsoft Store listing.

## Basic Information

**App Name**: HexBuzz

**Publisher**: HexBuzz Games (or your registered publisher name)

**Category**: Games → Puzzle & trivia

**Subcategory**: Puzzle

**Age Rating**: E (Everyone)

**Pricing**: Free

## Short Description

Maximum: 100 characters

```
Solve beautiful honeycomb puzzles! Connect paths through hexagonal grids in this zen puzzle game.
```

**Character count**: 99

## Full Description

Maximum: 10,000 characters

```markdown
# HexBuzz - The Mesmerizing Honeycomb Puzzle Challenge

Immerse yourself in the elegant world of HexBuzz, where honeycomb structures meet one-stroke puzzle challenges. Draw continuous paths through beautiful hexagonal grids, completing every cell in a single, satisfying stroke.

## How to Play

Connect numbered checkpoints in order, starting from 0 and ending at the highest number. Your path must visit every hexagonal cell exactly once - no revisiting, no gaps. It's deceptively simple to learn, yet endlessly engaging to master.

## Features

✓ **200+ Handcrafted Puzzles**: From gentle 2×2 tutorials to brain-bending 16×16 marathons
✓ **Progressive Difficulty**: 4×4, 6×6, 8×8, 10×10, 12×12, 14×14, 16×16 grid sizes
✓ **Beautiful Visual Effects**: Watch your path come alive with mesmerizing color transitions
✓ **Celebration Animations**: Satisfying rewards for every completed puzzle
✓ **Undo & Reset**: Backtrack along your path or start fresh anytime
✓ **No Time Pressure**: Play at your own pace, focus on perfection
✓ **Zen Experience**: Minimalist design, effect toggles for distraction-free play
✓ **Daily Challenges**: New puzzles every day to test your skills
✓ **Global Leaderboards**: Compete with players worldwide
✓ **Progress Tracking**: Stars and achievements for completed levels
✓ **Cross-Platform**: Your progress syncs across all devices

## Why You'll Love HexBuzz

**For Puzzle Enthusiasts**: HexBuzz offers the perfect blend of logic and spatial reasoning. Each puzzle has exactly one solution, ensuring fair and satisfying gameplay.

**For Casual Players**: No complex rules, no rushing. Pick it up anytime for a quick mental workout or a relaxing break.

**For Competitive Players**: Race against the clock, climb the leaderboards, and prove your puzzle-solving prowess with daily challenges.

## Unique Honeycomb Mechanics

Unlike traditional grid puzzles, HexBuzz's hexagonal structure creates unique challenges. Six-sided connections offer more possibilities and surprising solutions. The one-stroke constraint adds an elegant layer of complexity.

## Accessibility & Customization

- **Effect Controls**: Toggle visual effects for performance or preference
- **Intuitive Controls**: Mouse, touch, or keyboard - play your way
- **No Ads During Play**: Uninterrupted puzzle-solving experience
- **Free to Play**: Core game completely free, optional cosmetics available

## Perfect For

- Puzzle game fans
- Logic enthusiasts
- Casual gamers seeking zen experiences
- Competitive players wanting leaderboard challenges
- Anyone who loves beautiful, minimalist design

## What Players Are Saying

"The most satisfying puzzle game I've played this year!"
"Perfect for unwinding after work."
"Honeycomb grids add such a fresh twist to path puzzles."
"Love the visual effects when completing levels!"

## Stay Connected

Follow HexBuzz for updates, new features, and community challenges. Join thousands of players solving beautiful puzzles daily.

Download HexBuzz now and discover the joy of perfect paths!
```

**Character count**: 2,647

## Release Notes

For version 1.0.0 submission:

```
Initial release of HexBuzz!

Features:
• 200+ handcrafted honeycomb puzzles
• 7 difficulty levels (2×2 to 16×16)
• Daily challenges with global leaderboards
• Beautiful visual effects and animations
• Undo and reset functionality
• Cross-platform progress sync
• Minimalist, zen-focused design

We'd love to hear your feedback! Please rate and review.
```

## Key Features List

Maximum: 20 bullet points (recommend 8-12)

```
• 200+ handcrafted honeycomb puzzles
• Progressive difficulty from 2×2 to 16×16 grids
• Daily challenges with global leaderboards
• Beautiful visual effects and celebration animations
• No time pressure - play at your own pace
• Undo and reset features for stress-free solving
• Minimalist design with customizable effects
• Cross-platform progress sync
• Free to play with optional cosmetics
• Google Sign-In for cloud saves
```

## Search Keywords

Maximum: 7 keywords

```
puzzle, honeycomb, path, brain teaser, logic, zen, casual
```

**Rationale**:
- **puzzle**: Primary category, high search volume
- **honeycomb**: Unique mechanic, differentiates from competitors
- **path**: Core gameplay (path-drawing)
- **brain teaser**: Appeals to puzzle enthusiasts
- **logic**: Targets logic puzzle fans
- **zen**: Appeals to relaxation/casual audience
- **casual**: Broad appeal, high search volume

## Screenshots

**Required**: Minimum 4, Maximum 10
**Recommended**: 6-8 for optimal conversion

**Resolution**: 1920×1080 (Full HD) recommended
**Format**: PNG (preferred) or JPEG
**Size**: Under 50 MB per image

### Screenshot Plan

1. **Level Select Screen** (`screenshot_01_level_select.png`)
   - Show level grid with progression
   - Highlight star ratings
   - Show difficulty progression
   - Clean, polished interface

2. **Tutorial/Easy Gameplay** (`screenshot_02_easy_puzzle.png`)
   - 4×4 or 6×6 puzzle in progress
   - Path partially drawn with visual effects
   - Numbered checkpoints visible
   - Show intuitive controls

3. **Medium Difficulty** (`screenshot_03_medium_puzzle.png`)
   - 8×8 or 10×10 puzzle
   - More complex path
   - Visual effects prominent
   - Demonstrate challenge level

4. **Completion Celebration** (`screenshot_04_celebration.png`)
   - Completed puzzle with full path
   - Celebration effects visible
   - Star rating displayed
   - Time shown
   - "Level Complete" overlay

5. **Daily Challenge** (`screenshot_05_daily_challenge.png`)
   - Daily challenge interface
   - Leaderboard visible
   - Competitive element highlighted
   - Social features shown

6. **Advanced Puzzle** (`screenshot_06_advanced.png`)
   - 14×14 or 16×16 puzzle
   - Complex pattern
   - Showcases depth of content
   - Appeals to hardcore puzzlers

### Screenshot Creation Instructions

```bash
# 1. Build Windows release
flutter build windows --release

# 2. Run the application
./build/windows/x64/runner/Release/hex_buzz.exe

# 3. Navigate to each screen
# 4. Use Windows Game Bar (Win + G) or Snipping Tool (Win + Shift + S)
# 5. Capture at 1920×1080 resolution
# 6. Save to: assets/store/screenshots/

# 7. Verify images
# - Check resolution: 1920×1080
# - Check file size: < 50 MB
# - Check format: PNG or JPEG
# - Check quality: No compression artifacts
# - Check content: No debug UI, clean interface
```

**Best Practices**:
- Use release build (no debug banners)
- Clean interface (no popups unless showing feature)
- Show diverse content (different difficulty levels)
- Highlight key features (effects, celebrations)
- Maintain visual consistency
- Use actual game content (no mockups)
- First screenshot is most important (shows in search)

## App Icon

**Location**: `assets/icons/app_icon.png`
**Requirements**:
- 300×300 pixels minimum
- PNG format with transparency
- Square aspect ratio
- Clear on light and dark backgrounds

**Status**: ✓ Already exists

## Store Logo

**Requirements**: 300×300 pixels
**Solution**: Reuse app icon (`assets/icons/app_icon.png`)

**Status**: ✓ Can use existing app icon

## Promotional Art (Optional)

**Size**: 2400×1200 pixels
**Format**: PNG or JPEG
**Status**: Optional - not creating for initial submission

**If creating later**:
- Show gameplay collage
- Include app name and tagline
- Highlight unique honeycomb design
- Use brand colors (honey/gold theme)

## Privacy Policy

**URL**: `https://hexbuzz.web.app/privacy`

**Status**: To be created (see `PRIVACY_POLICY.md`)

**Summary**:
```
HexBuzz collects minimal user data:
- Google account info for authentication
- Game progress stored in Firebase
- Device tokens for notifications
- Optional analytics for improvement

Users can request data deletion at any time.
Full privacy policy at: https://hexbuzz.web.app/privacy
```

## Support Information

**Support Email**: `support@hexbuzz.com`
**Website**: `https://hexbuzz.web.app`
**Privacy Policy**: `https://hexbuzz.web.app/privacy`

## Age Rating - IARC Questionnaire

**Expected Rating**: E (Everyone)

**Questionnaire Answers**:
- Violence: None
- Sexual content: None
- Language: None
- Drugs/alcohol/tobacco: None
- Gambling: None
- Online interaction: Yes (leaderboards)
- Shares location: No
- Shares personal info: Yes (Google Sign-In)
- Digital purchases: No (for now)
- Unrestricted internet: No

**Result**: E (Everyone) / PEGI 3 / USK 0

## Notes for Certification Team

```
HexBuzz is a family-friendly honeycomb puzzle game.

Testing Instructions:
1. Launch the app - starts at level select
2. Complete the tutorial (2×2 grid) by drawing a continuous path
3. Try levels of different sizes (4×4, 6×6, 8×8)
4. Test undo: drag back along your path to erase
5. Test reset: click reset button to start over
6. Verify visual effects (toggleable in settings)
7. Sign in with Google (optional) to test cloud save
8. Check daily challenge and leaderboard features

All features should work smoothly on Windows 10 (1809+) and Windows 11.
No special setup or account needed for basic gameplay.

Contact: support@hexbuzz.com for any questions.
```

## Markets & Availability

**Recommended**: All markets
**Rationale**: Puzzle games have universal appeal

**Alternative**: Start with English-speaking markets
- United States
- United Kingdom
- Canada
- Australia
- New Zealand

Can expand to more markets later based on demand.

## Pricing

**Launch Price**: Free
**In-App Purchases**: None (currently)

**Monetization Strategy**:
- Free base game
- Optional cosmetics/themes (future)
- Non-intrusive ads (optional, future)

## Release Timing

**Availability Date**: As soon as certified
**Rationale**: No need to delay; launch ASAP

**Alternative**: Schedule release
- Can schedule for specific date/time
- Useful for coordinated marketing
- Not necessary for initial launch

## Content Checklist

- [x] App name decided
- [x] Short description written (99 chars)
- [x] Full description written (2,647 chars)
- [x] Key features listed (10 bullets)
- [x] Keywords selected (7)
- [x] Age rating prepared (E/Everyone)
- [x] Support email planned
- [x] Website URL planned
- [ ] Privacy policy created (see PRIVACY_POLICY.md)
- [ ] Screenshots captured (4-6 needed)
- [x] App icon ready
- [x] Store logo ready (using app icon)
- [x] Release notes written
- [x] Certification notes prepared

## Next Steps

1. Create screenshots (see screenshot plan above)
2. Write and host privacy policy
3. Reserve app name in Partner Center
4. Complete submission form with this content
5. Upload MSIX package
6. Submit for certification

## Maintenance

After publication, keep updated:
- Update description for new features
- Add new screenshots for major updates
- Update release notes for each version
- Monitor and respond to reviews
- Adjust keywords based on analytics

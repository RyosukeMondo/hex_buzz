# Microsoft Partner Center Setup Guide

This guide walks through creating a Microsoft Partner Center account and preparing HexBuzz for Store submission.

## Overview

Task 9.4 focuses on preparing all necessary accounts, assets, and documentation for Microsoft Store submission. This is a prerequisite for task 9.5 (actual submission).

## Phase 1: Account Creation

### Step 1: Create Microsoft Partner Center Account

**Time Required**: 2-5 business days (including approval)

1. **Visit Registration Page**
   - URL: https://partner.microsoft.com/dashboard/registration
   - Select account type: "Individual" or "Company"

2. **Account Type Decision**

   | Individual | Company |
   |-----------|---------|
   | Faster setup (1-2 days) | Longer verification (3-5 days) |
   | $19 USD one-time fee | $99 USD one-time fee |
   | Your personal name as publisher | Company name as publisher |
   | Best for indie developers | Required for business entities |

   **Recommendation for HexBuzz**: Individual account (faster, cheaper)

3. **Required Information**
   - Microsoft account (create one if needed)
   - Contact email address
   - Phone number
   - Country/region
   - Payment method (credit card for registration fee)

4. **Complete Registration**
   - Pay $19 USD registration fee (non-refundable)
   - Verify email address
   - Complete identity verification
   - Accept Microsoft Store Policies

5. **Wait for Approval**
   - Check email for approval notification
   - Usually takes 24-48 hours
   - May take up to 5 business days

### Step 2: Configure Account Settings

Once approved:

1. **Navigate to Account Settings**
   - Partner Center Dashboard → Settings (gear icon)
   - Account settings → Organization profile

2. **Note Your Publisher ID**
   - Go to: Identities section
   - Find your Publisher ID (format: `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)
   - **CRITICAL**: Copy this exactly - you'll need it for MSIX packaging

3. **Update Tax Information** (if applicable)
   - Account settings → Payout and tax
   - Complete W-8/W-9 forms if selling paid apps

4. **Set Up Payout Account** (optional for free apps)
   - Only needed if planning paid apps or in-app purchases
   - Can skip for free apps like HexBuzz

### Step 3: Reserve App Name

1. **Create New App**
   - Dashboard → Apps and games
   - Click "New product"
   - Select "MSIX or PWA app"

2. **Reserve Name "HexBuzz"**
   - Enter: HexBuzz
   - Check availability
   - Reserve the name (lasts 3 months unless submitted)

3. **Note App Identity**
   - After reservation, go to Product Identity
   - Find: Package/Identity/Name
   - Should be: `com.hexbuzz.hexbuzz` (or similar)
   - Verify this matches `identity_name` in `pubspec.yaml`

## Phase 2: Store Assets Preparation

### Required Assets Checklist

- [x] App Icon (300x300) - Already exists: `assets/icons/app_icon.png`
- [x] Windows Icons (multiple sizes) - Already exist in `assets/icons/windows/`
- [ ] **Screenshots (minimum 4)** - Need to create
- [ ] Store Logo (300x300) - Can reuse app icon
- [ ] Promotional art (2400x1200) - Optional

### Creating Screenshots

**Requirements**:
- Minimum: 4 screenshots (recommended: 6-8)
- Formats: PNG or JPEG
- Resolutions (choose one or mix):
  - 1366 x 768 (minimum, recommended)
  - 1920 x 1080 (full HD, popular)
  - 2560 x 1440 (2K)
  - 3840 x 2160 (4K)
- File size: <50 MB per image
- Content: Must show actual gameplay/app interface

**Screenshot Strategy for HexBuzz**:

1. **Main Menu / Level Select** (Screenshot 1)
   - Show level grid with progression
   - Highlight visual design
   - Resolution: 1920x1080

2. **Gameplay - Easy Level** (Screenshot 2)
   - Show simple 4x4 or 6x6 puzzle
   - Path drawing in progress
   - Visual effects visible
   - Resolution: 1920x1080

3. **Gameplay - Complex Level** (Screenshot 3)
   - Show larger 10x10 or 12x12 puzzle
   - Demonstrate challenge level
   - Resolution: 1920x1080

4. **Completion Celebration** (Screenshot 4)
   - Show completion effects
   - Star rating visible
   - Time displayed
   - Resolution: 1920x1080

5. **Daily Challenge** (Screenshot 5 - Optional)
   - Show daily challenge interface
   - Leaderboard visible
   - Resolution: 1920x1080

6. **Settings/Customization** (Screenshot 6 - Optional)
   - Show settings screen
   - Visual effect toggles
   - Resolution: 1920x1080

**How to Create**:

```bash
# Run app in Windows release mode
flutter run -d windows --release

# Use Windows built-in tools:
# - Windows + Shift + S (Snipping Tool)
# - Windows + G (Game Bar) → Screenshot
# - Or use OBS Studio for recording

# Save to: assets/store/screenshots/
```

**Best Practices**:
- No device frames or borders
- Clean interface (no debug overlays)
- Actual game content (no mockups)
- Highlight unique features
- Show visual polish
- Use consistent resolution across images

### Store Listing Content

Create file: `docs/store_listing.md`

#### App Title
```
HexBuzz - Honeycomb Puzzle Game
```
(Note: Store will use reserved name "HexBuzz")

#### Short Description (100 characters max)
```
Solve beautiful honeycomb puzzles! Connect paths through hexagonal grids in this zen puzzle game.
```

#### Description (10,000 characters max)

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

#### Key Features (bullet list)
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
```

#### Keywords (7 maximum, comma-separated)
```
puzzle, honeycomb, path, brain teaser, logic, zen, casual
```

#### Age Rating
- **IARC Rating**: E for Everyone
- **Content**: No violence, no explicit content, no ads targeting children
- **Answer questionnaire honestly**

#### Privacy Policy URL
```
https://hexbuzz.web.app/privacy
```
(Will be created in Phase 3)

#### Support Contact
```
Email: support@hexbuzz.com
Website: https://hexbuzz.web.app
```

#### Category
- **Primary**: Games → Puzzle & trivia
- **Subcategory**: Puzzle

## Phase 3: Privacy Policy & Terms

### Privacy Policy Requirements

Microsoft Store requires a privacy policy URL for all apps that collect user data.

**HexBuzz Data Collection**:
- Google account info (email, name, avatar) - for authentication
- Game progress and scores - stored in Firestore
- Device tokens - for push notifications
- Analytics - gameplay metrics (optional)

**Create**: `docs/PRIVACY_POLICY.md` (to be hosted at Firebase)

Key sections needed:
1. What data we collect
2. How we use it
3. How we store it (Firebase/Google Cloud)
4. User rights (GDPR compliance)
5. Data deletion process
6. Third-party services (Google Sign-In, Firebase)
7. Contact information

**Note**: See `docs/PRIVACY_POLICY.md` for full template.

### Terms of Service (Optional)

Terms of Service are optional for free apps but recommended.

Key sections:
1. License to use the app
2. User conduct rules
3. Intellectual property rights
4. Limitation of liability
5. Termination of service

## Phase 4: Pre-Submission Checklist

Before uploading MSIX to Partner Center:

### Technical Requirements
- [ ] MSIX package built and tested locally
- [ ] WACK tests passed (see `docs/MS_STORE_DEPLOYMENT.md`)
- [ ] App runs on Windows 10 1809+ and Windows 11
- [ ] All features tested on Windows
- [ ] No critical bugs or crashes
- [ ] Publisher ID updated in `pubspec.yaml`

### Assets Ready
- [ ] App icon (300x300)
- [ ] Minimum 4 screenshots (1920x1080 recommended)
- [ ] Store logo (can reuse app icon)
- [ ] Promotional art (optional, 2400x1200)

### Documentation Ready
- [ ] Privacy policy URL live and accessible
- [ ] Support email configured
- [ ] Store description written
- [ ] Keywords selected
- [ ] Age rating questionnaire answers prepared

### Account Setup
- [ ] Partner Center account approved
- [ ] App name "HexBuzz" reserved
- [ ] Publisher ID copied from Partner Center
- [ ] Product Identity verified

### Compliance
- [ ] App complies with Microsoft Store Policies
- [ ] No copyright violations
- [ ] No inappropriate content
- [ ] Age rating accurate
- [ ] Privacy policy meets GDPR requirements

## Phase 5: Submission Process

Once all preparation is complete:

1. **Upload MSIX Package**
   - Navigate to: App submission → Packages
   - Upload: `build/windows/x64/runner/Release/hex_buzz.msix`
   - System validates package automatically

2. **Complete Store Listing**
   - Description: Paste prepared description
   - Features: Add key features
   - Screenshots: Upload all 4-8 images
   - Category: Games → Puzzle & trivia

3. **Set Pricing**
   - Pricing: Free
   - Markets: All markets (or select specific regions)
   - Availability: Immediate upon certification

4. **Age Rating**
   - Complete IARC questionnaire
   - Answer honestly about game content
   - Expected rating: E (Everyone)

5. **Properties**
   - Privacy policy URL
   - Support contact email
   - Website (optional)

6. **Notes for Certification**
   ```
   HexBuzz is a relaxing honeycomb puzzle game. To test:
   1. Launch the app
   2. Complete tutorial level (2×2 grid)
   3. Try a few levels of different sizes
   4. Test undo by dragging back along path
   5. Test reset button
   6. Verify all features work as described

   No special account or setup needed. All content is appropriate for all ages.
   ```

7. **Submit**
   - Review all sections
   - Click "Submit to Store"
   - Wait for certification (1-3 business days)

## Cost Breakdown

| Item | Cost | When |
|------|------|------|
| Partner Center Registration | $19 USD | One-time (now) |
| App Submission | Free | Per submission |
| App Updates | Free | Unlimited |
| Firebase Hosting (Privacy Policy) | Free | Ongoing |
| **Total Upfront** | **$19 USD** | |

## Timeline Estimate

| Phase | Duration | Notes |
|-------|----------|-------|
| Account creation | 1-2 days | Plus 2-3 days approval |
| App name reservation | 5 minutes | Instant |
| Screenshot creation | 2-4 hours | Quality matters |
| Store listing writing | 1-2 hours | Use template |
| Privacy policy | 1-2 hours | Use template |
| MSIX preparation | 30 minutes | Already done (9.1-9.3) |
| Submission form | 1 hour | First time |
| Certification | 1-3 business days | Microsoft review |
| **Total** | **3-7 days** | Including waiting |

## Common Mistakes to Avoid

1. **Wrong Publisher ID**: Must match Partner Center exactly
2. **Low-Quality Screenshots**: Use 1920x1080, show actual gameplay
3. **Missing Privacy Policy**: Required for data collection
4. **Incomplete Age Rating**: Answer IARC questionnaire fully
5. **Bad Description**: Use keywords, highlight features clearly
6. **Wrong Category**: Should be Games → Puzzle
7. **Not Testing MSIX**: Install locally and test before submitting
8. **Screenshots with Debug UI**: Use release build for screenshots

## After Approval

Once approved and published:

1. **App Goes Live**
   - Appears in Microsoft Store search
   - Users can install via Store app or web

2. **Monitor Performance**
   - Check Partner Center analytics
   - Reviews and ratings
   - Installation metrics
   - Crash reports

3. **Respond to Reviews**
   - Reply to user feedback
   - Fix reported issues
   - Update description if needed

4. **Plan Updates**
   - New features
   - Bug fixes
   - Version increments

## Resources

- **Partner Center**: https://partner.microsoft.com/dashboard
- **Store Policies**: https://learn.microsoft.com/windows/apps/publish/store-policies
- **App Submission Guide**: https://learn.microsoft.com/windows/apps/publish/publish-your-app/
- **IARC Ratings**: https://www.globalratings.com/
- **Privacy Policy Generator**: https://www.termsfeed.com/privacy-policy-generator/

## Support

For issues during setup:
- Partner Center Support: https://partner.microsoft.com/support
- Windows App Development Forum: https://github.com/microsoft/WindowsAppSDK/discussions

## Next Steps

After completing this guide:
1. Mark task 9.4 as complete
2. Proceed to task 9.5: Actual store submission
3. Upload MSIX and complete submission form
4. Wait for certification
5. Celebrate launch! 🎉

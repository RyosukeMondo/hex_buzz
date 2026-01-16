# Microsoft Store Submission Guide

This guide provides step-by-step instructions for submitting HexBuzz to the Microsoft Store (Task 9.5).

## Prerequisites

Before starting the submission process, ensure you have completed:

- [x] Task 9.1: MSIX packaging configured
- [x] Task 9.2: Windows-specific adaptations implemented
- [x] Task 9.3: WACK testing passed
- [x] Task 9.4: Partner Center account created and app name reserved
- [ ] **Required**: Publisher ID obtained from Partner Center and updated in `pubspec.yaml`
- [ ] **Required**: MSIX package built and tested locally
- [ ] **Required**: Screenshots captured (minimum 4)

## Phase 1: Pre-Submission Preparation

### Step 1: Update Publisher ID

**CRITICAL**: You must obtain your actual Publisher ID from Microsoft Partner Center before building the MSIX.

1. **Get Publisher ID from Partner Center**:
   - Go to https://partner.microsoft.com/dashboard
   - Navigate to: Account Settings → Organization Profile → Identities
   - Copy your Publisher ID (format: `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)

2. **Update pubspec.yaml**:
   ```yaml
   msix_config:
     publisher: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX  # Replace with your actual ID
   ```

3. **Verify identity_name matches Partner Center**:
   - In Partner Center, go to your app → Product Identity
   - Confirm `Package/Identity/Name` matches `identity_name` in pubspec.yaml
   - Default: `com.hexbuzz.hexbuzz`

### Step 2: Build and Test MSIX Package

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build Windows release**:
   ```bash
   flutter build windows --release
   ```

3. **Create MSIX package**:
   ```bash
   flutter pub run msix:create
   ```

4. **Verify MSIX location**:
   ```bash
   ls -lh build/windows/x64/runner/Release/hex_buzz.msix
   ```

   Expected size: ~50-100 MB

5. **Test MSIX locally**:
   - Double-click `hex_buzz.msix` to install
   - Launch from Start Menu
   - Test all features:
     - [ ] Game launches correctly
     - [ ] Level selection works
     - [ ] Gameplay is smooth
     - [ ] Progress saves properly
     - [ ] Window resizing works
     - [ ] Keyboard shortcuts work (Ctrl+Z, Escape)
     - [ ] Settings are saved
     - [ ] No crashes or errors
   - Uninstall after testing: Settings → Apps → HexBuzz → Uninstall

### Step 3: Run WACK (Windows App Certification Kit)

**CRITICAL**: WACK must pass before submission. Microsoft will reject apps that fail WACK.

1. **Run WACK tests** (on Windows machine):
   ```powershell
   .\run_wack_tests.ps1 -BuildFirst
   ```

2. **Verify all tests pass**:
   - Open HTML report (auto-opens after tests)
   - Confirm: **0 Errors, 0 Warnings**
   - If failures occur, see `docs/WACK_TESTING_GUIDE.md` for fixes

3. **Save WACK report**:
   - Keep HTML report for your records
   - Microsoft may request during certification

### Step 4: Prepare Screenshots

**Requirements**:
- Minimum: 4 screenshots
- Recommended: 6-8 screenshots
- Resolution: 1920x1080 (preferred) or 1366x768 (minimum)
- Format: PNG or JPEG
- Content: Must show actual gameplay/UI

**Screenshot Plan** (see `docs/SCREENSHOT_GUIDE.md` for details):

1. **Welcome/Tutorial Screen** (2x2 grid)
   - Caption: "Easy to learn - start with simple puzzles"

2. **Mid-Game 6x6 Level**
   - Caption: "Draw paths through beautiful hexagonal grids"

3. **Completion Animation**
   - Caption: "Satisfying celebrations for every puzzle solved"

4. **Level Selection Screen**
   - Caption: "200+ handcrafted puzzles from 2×2 to 16×16"

5. **Advanced 12x12 Level** (optional)
   - Caption: "Challenge your mind with complex puzzles"

6. **Daily Challenge Screen** (optional, if implemented)
   - Caption: "New daily challenges with global leaderboards"

**Capture Instructions**:

```bash
# Set window to 1920x1080
# Play through game, capture screens at key moments
# On Windows: Win+Shift+S or Snipping Tool
# Save as PNG in: screenshots/store/
```

**Quality checklist**:
- [ ] All screenshots are 1920x1080
- [ ] Show actual game UI (no mockups)
- [ ] Bright, colorful, appealing
- [ ] Text is readable
- [ ] No debug overlays or watermarks
- [ ] Showcase key features
- [ ] Progressive difficulty visible

### Step 5: Prepare Store Listing Content

All content is pre-written in `docs/store_listing.md`. Review and customize if needed:

- [x] App name: HexBuzz
- [x] Short description (99 chars)
- [x] Full description (2,647 chars)
- [x] Key features (10 bullet points)
- [x] Keywords (7 terms)
- [x] Release notes
- [x] Privacy policy URL (see Step 6)

### Step 6: Deploy Privacy Policy

**Requirement**: Microsoft Store requires a privacy policy URL for apps that collect data.

1. **Privacy policy prepared**: `docs/PRIVACY_POLICY.md`

2. **Deployment options**:

   **Option A: Firebase Hosting** (recommended):
   ```bash
   # Convert markdown to HTML
   # Deploy to Firebase Hosting
   # URL will be: https://your-app.web.app/privacy-policy.html
   ```

   **Option B: GitHub Pages**:
   ```bash
   # Create docs/privacy.html from PRIVACY_POLICY.md
   # Enable GitHub Pages
   # URL: https://username.github.io/hex_buzz/privacy.html
   ```

   **Option C: Custom Domain**:
   - Host on your own website
   - Must be publicly accessible

3. **Verify URL**:
   - [ ] Privacy policy is accessible
   - [ ] HTTPS enabled
   - [ ] No authentication required
   - [ ] Mobile-friendly

4. **Note URL for submission**: `https://____________________`

## Phase 2: Microsoft Store Submission

### Step 1: Access Partner Center

1. Go to https://partner.microsoft.com/dashboard
2. Sign in with your Microsoft account
3. Navigate to: **Apps and games**
4. Select your **HexBuzz** app (should be reserved from Task 9.4)

### Step 2: Start New Submission

1. Click **"Start submission"** button
2. You'll see a checklist of required sections:
   - Pricing and availability
   - Properties
   - Age ratings
   - Packages
   - Store listings
   - Submission options
   - Notes for certification

### Step 3: Pricing and Availability

1. **Markets**:
   - Select: **All markets** (or specific regions)
   - Exclude any restricted countries if needed

2. **Pricing**:
   - Select: **Free**
   - (HexBuzz is free-to-play with optional ads)

3. **Availability date**:
   - **As soon as possible after certification**
   - Or schedule for specific date

4. **Organizational licensing**:
   - Leave unchecked (not applicable)

5. Click **Save**

### Step 4: Properties

1. **Category**:
   - Primary: **Games** → **Puzzle & trivia**
   - Subcategory: **Puzzle**

2. **System requirements** (optional):
   - Can leave default (MSIX handles this)
   - Or specify:
     - OS: Windows 10 version 1809 (17763) or higher
     - RAM: 4 GB minimum

3. **Additional properties** (optional):
   - Leave default

4. Click **Save**

### Step 5: Age Ratings

Complete the IARC (International Age Rating Coalition) questionnaire:

1. Click **Get rating**

2. **Answer questionnaire**:
   - Does your product contain violence? **No**
   - Does it contain sexual content? **No**
   - Does it contain bad language? **No**
   - Does it contain drug use? **No**
   - Does it contain gambling? **No**
   - Does it allow communication with others? **No** (unless social features implemented)
   - Does it allow sharing of personal information? **No** (unless user profiles implemented)
   - Does it contain in-app purchases? **No** (unless implemented)

3. **Expected rating**: **E (Everyone)** or **3+ (PEGI)**

4. **Submit questionnaire** and receive ratings

5. Click **Save**

### Step 6: Packages

**CRITICAL STEP**: Upload your MSIX file.

1. **Upload MSIX**:
   - Click **Browse** or drag-and-drop
   - Select: `build/windows/x64/runner/Release/hex_buzz.msix`
   - Wait for upload (may take 2-5 minutes depending on size)

2. **Package validation**:
   - System automatically validates package
   - Wait for validation to complete (~1-2 minutes)
   - **Must show**: ✓ Package validated successfully
   - If validation fails, see "Troubleshooting" section below

3. **Verify package details**:
   - Package version: `1.0.0.0`
   - Supported processor architectures: `x64`
   - Supported languages: `en-US, ja-JP`
   - Minimum OS version: `10.0.17763.0` (Windows 10 1809)

4. **Device families**:
   - Should show: **Desktop** (automatically detected)

5. Click **Save**

### Step 7: Store Listings

Complete for each language (English required, Japanese optional):

#### English (United States) - REQUIRED

1. **Product name**: HexBuzz

2. **Description** (copy from `docs/store_listing.md`):
   ```
   Immerse yourself in the elegant world of HexBuzz, where honeycomb structures meet one-stroke puzzle challenges...

   [Full description - 2,647 characters]
   ```

3. **Release notes** (for this version):
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

4. **Key features** (up to 20):
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

5. **Screenshots**:
   - Upload 4-8 screenshots captured in Step 4
   - Drag to reorder (first screenshot is most important)
   - Add captions for each (optional but recommended)

6. **Store logos**:
   - Upload `assets/icons/app_icon.png` (300x300) for:
     - 1:1 Square logo (300x300)
     - Can use same image for all logo sizes

7. **Promotional images** (optional):
   - Hero image (2400x1200) - skip for now
   - Can add later in updates

8. **Trailers** (optional):
   - Skip for initial release
   - Can add gameplay video later

9. **Additional information**:
   - **Copyright and trademark info**: `© 2026 HexBuzz Games. All rights reserved.`
   - **Additional license terms**: Leave blank
   - **Website**: (optional, your game website if available)
   - **Support contact info**: Your email for support inquiries
   - **Privacy policy**: **REQUIRED** - Enter URL from Step 6
     - Example: `https://your-app.web.app/privacy-policy.html`

10. **Search terms** (up to 7):
    ```
    puzzle
    honeycomb
    path
    brain teaser
    logic
    zen
    casual
    ```

11. Click **Save**

#### Japanese (Japan) - OPTIONAL

If you want to support Japanese market, repeat above in Japanese. Otherwise, skip.

### Step 8: Submission Options

1. **Publishing hold options**:
   - Select: **Publish this submission as soon as it passes certification**
   - (Or choose manual publish if you want to control timing)

2. **Notes for testers** (see Step 9)

3. Click **Save**

### Step 9: Notes for Certification

Provide helpful information for Microsoft's certification testers:

```
Thank you for reviewing HexBuzz!

HOW TO PLAY:
1. Launch the app - a simple 2×2 tutorial puzzle appears first
2. Tap/click numbered checkpoint "0" to start
3. Drag your mouse/finger to the next checkpoint in order (0 → 1 → 2, etc.)
4. Your path must fill all hexagonal cells exactly once
5. End at the highest numbered checkpoint to complete the puzzle

FEATURES TO TEST:
• Level selection: Various grid sizes (4×4, 6×6, 8×8, 10×10, 12×12, 14×14, 16×16)
• Undo: Backtrack by dragging backward along your path
• Reset: Button in top-right corner to restart current puzzle
• Settings: Toggle visual effects (for performance testing)
• Progress saving: Completed levels show star ratings

NETWORK USAGE:
• Internet connection required for:
  - Google Sign-In (optional, for cloud saves)
  - Daily challenges (optional feature)
  - Leaderboards (optional feature)
• Core single-player game works completely offline

TEST CREDENTIALS:
• No login required for core gameplay
• Google Sign-In is optional for cloud features

NOTES:
• First launch may take a few seconds to initialize
• All features work on Windows 10 version 1809 and later
• No admin privileges required
• WACK certification passed (attached report if needed)

Please let me know if you need any clarification or have questions!
```

Click **Save**

### Step 10: Review and Submit

1. **Review all sections**:
   - Check for green checkmarks on all sections
   - Fix any warnings or errors (red/yellow indicators)

2. **Final checklist**:
   - [ ] MSIX package uploaded and validated
   - [ ] Screenshots uploaded (minimum 4)
   - [ ] Privacy policy URL entered
   - [ ] Store description complete
   - [ ] Age rating complete
   - [ ] Notes for certification added
   - [ ] All required fields filled

3. **Submit for certification**:
   - Click **"Submit to the Store"** button at top
   - Confirm submission in popup dialog
   - **Submission is now in queue!**

## Phase 3: Certification and Monitoring

### Certification Process Timeline

| Stage | Duration | Description |
|-------|----------|-------------|
| **Pre-processing** | 5-30 minutes | Automated package validation |
| **Security testing** | 2-6 hours | Malware, virus, safety scans |
| **Technical compliance** | 1-3 days | Manual testing by Microsoft |
| **Content compliance** | 1-2 days | Policy review, age rating verification |
| **Release** | 5-30 minutes | Publishing to Store |

**Total estimated time**: 1-3 business days

**Note**: First submissions may take longer. Subsequent updates are usually faster.

### Monitoring Your Submission

1. **Check status**:
   - Partner Center Dashboard → Your app → Submission status
   - Email notifications at each stage

2. **Status indicators**:
   - **In pre-processing**: Initial validation
   - **In testing**: Microsoft is actively reviewing
   - **Pending publish**: Passed, waiting to go live
   - **In the Store**: Live and available! 🎉
   - **Failed certification**: Issues found (see next section)

3. **Email notifications**:
   - You'll receive emails at each stage
   - Check spam folder if not received

### If Certification Fails

Don't worry! This is common for first submissions.

1. **Review failure report**:
   - Partner Center shows detailed failure reasons
   - Common issues:
     - App crashes on launch
     - Missing privacy policy
     - Screenshots don't match actual app
     - Performance issues (slow launch)
     - Policy violations

2. **Fix issues**:
   - Address each failure reason
   - Rebuild MSIX if code changes needed
   - Update store listing if content issues

3. **Resubmit**:
   - Create new submission
   - Upload fixed MSIX
   - Add notes explaining what was fixed
   - Microsoft prioritizes resubmissions

### After Approval

Once your app is **"In the Store"**:

1. **Verify store listing**:
   - Search for "HexBuzz" in Microsoft Store app
   - Check that all information displays correctly
   - Verify screenshots look good

2. **Test installation**:
   - Uninstall your local test version
   - Install from Microsoft Store
   - Verify it works identically

3. **Monitor metrics**:
   - Partner Center → Analytics
   - Track:
     - Installs
     - Active users
     - Ratings and reviews
     - Crashes (if any)

4. **Respond to reviews**:
   - Monitor user reviews
   - Respond to feedback
   - Address reported issues in updates

5. **Share the news**:
   - Microsoft Store link: `https://www.microsoft.com/store/apps/[YOUR_APP_ID]`
   - Share on social media
   - Update your website/documentation

## Troubleshooting

### MSIX Upload Fails

**Error**: "Package validation failed"

**Solutions**:
1. Verify publisher ID matches Partner Center exactly
2. Check `identity_name` matches reserved app identity
3. Ensure MSIX version is higher than any previous submissions
4. Run WACK locally to catch issues before upload
5. Check MSIX file isn't corrupted (rebuild if needed)

### Screenshots Rejected

**Error**: "Screenshots don't represent actual app"

**Solutions**:
1. Use actual game UI (no mockups or edited images)
2. Ensure resolution meets requirements (1366x768 min)
3. No text overlays or marketing materials
4. Must clearly show game features

### Privacy Policy Issues

**Error**: "Privacy policy URL not accessible"

**Solutions**:
1. Verify URL is publicly accessible (test in incognito browser)
2. Must use HTTPS
3. No login/authentication required to view
4. Check that page loads on mobile devices

### App Crashes During Testing

**Error**: "Application crashed during certification testing"

**Solutions**:
1. Test MSIX thoroughly before submission
2. Check Windows Event Viewer for crash logs
3. Ensure all dependencies are included in package
4. Test on clean Windows 10 1809 installation
5. Check for file path issues (use relative paths)

### Performance Test Fails

**Error**: "Application launch time exceeds 5 seconds"

**Solutions**:
1. Optimize `main()` function
2. Move heavy initialization to background
3. Use lazy loading for assets
4. Profile with Flutter DevTools
5. Test on lower-spec hardware

## Post-Submission Updates

When you need to submit an update:

1. **Increment version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   msix_config:
     msix_version: 1.0.1.0
   ```

2. **Rebuild MSIX**:
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --release
   flutter pub run msix:create
   ```

3. **Create new submission**:
   - Partner Center → Your app → Create new submission
   - Most fields will be pre-filled from previous submission
   - Update: Packages, Release notes, Screenshots (if changed)

4. **Describe changes** in release notes:
   ```
   Version 1.0.1 Update:

   • Fixed bug with level progress saving
   • Improved performance on Windows 10
   • Added new visual effects
   • Minor UI improvements
   ```

5. **Submit** and monitor as before

## Success Checklist

Before submitting, confirm:

- [ ] Publisher ID updated in `pubspec.yaml`
- [ ] MSIX built successfully
- [ ] WACK tests passed (0 errors, 0 warnings)
- [ ] MSIX tested locally (installs, runs, all features work)
- [ ] 4-8 screenshots captured at 1920x1080
- [ ] Privacy policy deployed and accessible
- [ ] Store listing content prepared
- [ ] Partner Center account active
- [ ] App name "HexBuzz" reserved
- [ ] All store sections completed (green checkmarks)
- [ ] Notes for certification added
- [ ] Final review completed

## Resources

- **Partner Center Dashboard**: https://partner.microsoft.com/dashboard
- **Store Policies**: https://learn.microsoft.com/windows/apps/publish/store-policies
- **MSIX Documentation**: https://learn.microsoft.com/windows/msix/
- **WACK Guide**: `docs/WACK_TESTING_GUIDE.md`
- **Screenshot Guide**: `docs/SCREENSHOT_GUIDE.md`
- **Privacy Policy**: `docs/PRIVACY_POLICY.md`
- **Store Listing Content**: `docs/store_listing.md`

## Timeline Summary

| Phase | Duration | Details |
|-------|----------|---------|
| **Preparation** | 1-2 hours | Build MSIX, run WACK, capture screenshots |
| **Submission** | 30-60 minutes | Fill out Partner Center forms |
| **Certification** | 1-3 days | Microsoft review process |
| **Go Live** | Immediate | Appears in Store after approval |

**Total time from start to live**: ~2-4 days (assuming Partner Center account already set up)

## Next Steps

After successful submission:

1. **Task 9.5**: ✓ Complete once app is submitted
2. **Task 10.x**: Begin testing and quality assurance
3. **Task 11.x**: Setup monitoring, documentation, CI/CD
4. Monitor certification status daily
5. Address any feedback from Microsoft
6. Celebrate when app goes live! 🎉

---

**Good luck with your submission! You've got this!** 🚀

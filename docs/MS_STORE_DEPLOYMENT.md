# Microsoft Store Deployment Guide

This document describes how to deploy HexBuzz to the Microsoft Store.

## Quick Reference

```bash
# Install dependencies
flutter pub get

# Build Windows release
flutter build windows --release

# Create MSIX package
flutter pub run msix:create

# MSIX output location
build/windows/x64/runner/Release/hex_buzz.msix
```

## Application Info

| Property | Value |
|----------|-------|
| App Name | HexBuzz |
| Display Name | HexBuzz |
| Identity Name | `com.hexbuzz.hexbuzz` |
| Publisher Display Name | HexBuzz Games |
| Publisher ID | `CN=YourPublisherID` (Get from Partner Center and update in pubspec.yaml) |

## File Locations

| File | Path | Purpose |
|------|------|---------|
| MSIX Config | `pubspec.yaml` (msix_config section) | Package configuration |
| Built MSIX | `build/windows/x64/runner/Release/hex_buzz.msix` | Upload artifact |
| App Icon | `assets/icons/app_icon.png` | Store icon source |
| Windows Runner | `windows/runner/` | Windows platform files |

## Prerequisites

### 1. Microsoft Partner Center Account

- Register at https://partner.microsoft.com/dashboard
- Pay one-time registration fee (~$19 USD for individuals)
- Verify your account identity
- Wait for account approval (usually 24-48 hours)

### 2. Reserve Your App Name

1. Go to Partner Center → Apps and games
2. Click "New product" → "MSIX or PWA app"
3. Reserve the name "HexBuzz"
4. Note your Publisher ID from Account Settings → Organization Profile → Identities

## Configuration

### Update MSIX Config in pubspec.yaml

The MSIX configuration has been configured in `pubspec.yaml`. Before building for the Store, update the `publisher` value:

```yaml
msix_config:
  display_name: HexBuzz
  publisher_display_name: HexBuzz Games
  identity_name: com.hexbuzz.hexbuzz
  publisher: CN=YourPublisherID                 # UPDATE THIS from Partner Center
  msix_version: 1.0.0.0
  logo_path: assets/icons/app_icon.png
  start_menu_icon_path: assets/icons/app_icon.png
  tile_icon_path: assets/icons/app_icon.png
  icons_background_color: transparent
  architecture: x64
  capabilities: internetClient
  store: true
  languages: en-us, ja-jp
  protocol_activation: hexbuzz
  windows_build_version: 10.0.17763.0
```

**Important**:
- `identity_name` must be unique across the entire Microsoft Store (currently: `com.hexbuzz.hexbuzz`)
- `publisher` must match exactly from Partner Center (including CN= prefix) - **UPDATE THIS BEFORE BUILDING**
- `msix_version` format is Major.Minor.Build.Revision (e.g., 1.0.0.0)
- `windows_build_version` targets Windows 10 version 1809 (October 2018 Update) and later

## Version Management

Before each deployment, increment the version in `pubspec.yaml`:

```yaml
# Flutter version (user-facing)
version: 1.0.1+2

# MSIX version (Store requirement)
msix_config:
  msix_version: 1.0.1.0
```

**Version Rules**:
- Flutter version: `major.minor.patch+buildNumber`
- MSIX version: `major.minor.build.revision` (must match or be compatible)
- Each new submission must have a higher version number

## Building the MSIX Package

### Step 1: Clean Build
```bash
flutter clean
flutter pub get
```

### Step 2: Build Windows Release
```bash
flutter build windows --release
```

### Step 3: Create MSIX Package
```bash
flutter pub run msix:create
```

The MSIX file will be created at:
```
build/windows/x64/runner/Release/hex_buzz.msix
```

## Testing Locally (Optional)

Before submitting to the Store, test the MSIX package:

1. **Install locally**:
   - Double-click the `.msix` file
   - Windows will prompt for installation
   - Or use PowerShell: `Add-AppxPackage -Path "path\to\hex_buzz.msix"`

2. **Test the app**:
   - Launch from Start Menu
   - Test all game features
   - Verify saved progress works
   - Check for crashes or errors

3. **Uninstall** (if needed):
   - Settings → Apps → HexBuzz → Uninstall
   - Or PowerShell: `Remove-AppxPackage -Package "HexBuzz_1.0.0.0_x64__..."`

## Store Submission

### 1. Prepare Store Assets

You'll need the following assets:

| Asset | Requirements | Current Status |
|-------|-------------|----------------|
| App Icon | 300x300 PNG | ✓ `assets/icons/app_icon.png` |
| Screenshots | 1366x768, 1920x1080, or 3840x2160 PNG/JPEG | ⚠ Need to create |
| Store Logo | 300x300 PNG | ✓ Can use app icon |
| Promotional Art | 2400x1200 PNG (optional) | ⚠ Optional |

**Screenshot Requirements**:
- Minimum: 1 screenshot
- Maximum: 10 screenshots
- Show actual gameplay/features
- No borders or device frames

### 2. Submit to Partner Center

1. **Go to Partner Center**:
   - https://partner.microsoft.com/dashboard
   - Select your HexBuzz app

2. **Start Submission**:
   - Click "Start your submission"

3. **Pricing and Availability**:
   - Markets: Select regions (or "All markets")
   - Pricing: Free (or set price)
   - Availability date: Choose release timing

4. **Properties**:
   - Category: Games → Puzzle & trivia
   - Subcategory: Puzzle
   - Age rating: Complete IARC questionnaire (likely E for Everyone)

5. **Packages**:
   - Upload your MSIX file
   - System will validate the package
   - Ensure version matches your config

6. **Store listings**:
   - Description: Write compelling game description
   - Features: List key features
   - Screenshots: Upload gameplay screenshots
   - Additional assets: Logos, promotional images

7. **Notes for certification**:
   - Explain how to play the game
   - Mention any special features
   - Note if network access is needed

8. **Submit for certification**:
   - Review all sections
   - Click "Submit to the Store"

### 3. Certification Process

| Stage | Duration | Details |
|-------|----------|---------|
| Pre-processing | Minutes | Automatic validation |
| Security testing | Hours | Malware/safety scan |
| Technical compliance | 1-2 days | App policy review |
| Content compliance | 1-2 days | Age rating verification |
| Release | Minutes | Live in Store |

**Total Time**: Typically 1-3 business days

## Update Deployment

To deploy an update:

1. **Increment versions** in `pubspec.yaml`:
   ```yaml
   version: 1.0.2+3
   msix_config:
     msix_version: 1.0.2.0
   ```

2. **Build new MSIX**:
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --release
   flutter pub run msix:create
   ```

3. **Submit update**:
   - Go to Partner Center → Your app
   - Create new submission
   - Upload new MSIX package
   - Update release notes
   - Submit

4. **Update rollout**:
   - Can be gradual (percentage-based)
   - Or immediate to all users

## Troubleshooting

### Build Errors

**"Publisher not found"**
- Verify `publisher` in `msix_config` matches Partner Center exactly
- Include the `CN=` prefix
- Copy-paste to avoid typos

**"Identity name already exists"**
- Change `identity_name` to a unique value
- Format: reverse domain notation (com.yourname.hexbuzz)

**"Invalid version format"**
- MSIX version must be `X.Y.Z.W` format
- All parts must be integers
- Example: `1.0.0.0` ✓, `1.0.0` ✗

**"Logo not found"**
- Verify `logo_path` points to existing file
- Use forward slashes: `assets/icons/app_icon.png`
- PNG format recommended, 256x256 minimum

### Certification Failures

**"App crashes on launch"**
- Test MSIX locally before submitting
- Check Windows Event Viewer for crash logs
- Ensure all dependencies are included

**"Missing age rating"**
- Complete IARC questionnaire in Properties section
- Select appropriate content descriptors

**"Invalid screenshots"**
- Screenshots must show actual app UI
- No marketing materials or text-only images
- Meet size requirements (1366x768 minimum)

### Package Validation Errors

**"Package architecture mismatch"**
- Ensure `architecture: x64` in msix_config
- Or use `x86` for 32-bit, `arm64` for ARM
- Don't mix architectures in same package

**"Capability not allowed"**
- Remove unnecessary capabilities from msix_config
- Only use what your app actually needs
- Common: `internetClient`, `picturesLibrary`

## Advanced Configuration

### Multiple Architectures

To support multiple architectures, build separate packages:

```bash
# x64 (most common)
flutter build windows --release
flutter pub run msix:create

# Change architecture in msix_config to x86, then:
flutter build windows --release
flutter pub run msix:create
```

Upload all architecture packages in the same submission.

### Store-Specific Capabilities

Add Windows capabilities as needed:

```yaml
msix_config:
  capabilities: internetClient, picturesLibrary, musicLibrary
```

Common capabilities:
- `internetClient`: Network access (already configured)
- `location`: GPS/location services
- `microphone`: Microphone access
- `webcam`: Camera access
- `picturesLibrary`: User's Pictures folder
- `musicLibrary`: User's Music folder

### Custom Protocol Handler

The app is configured with protocol activation:

```yaml
msix_config:
  protocol_activation: hexbuzz
```

Users can launch app via `hexbuzz://` URLs (e.g., `hexbuzz://daily-challenge`).

### Windows Icons Configuration

Windows-specific icons have been created in multiple sizes:
- **44x44**: Small tile icon
- **71x71**: Medium tile icon
- **150x150**: Wide tile icon
- **310x310**: Large tile icon
- **620x620**: Store logo (high DPI)

Icons are located in `assets/icons/windows/` and automatically included in the MSIX package.

## For AI Agents

When deploying a new version:

1. **Check current version**:
   ```bash
   grep "version:" pubspec.yaml
   grep "msix_version:" pubspec.yaml
   ```

2. **Increment versions**:
   - Edit `pubspec.yaml`
   - Increment both `version` and `msix_version`
   - Version code must be higher than previous

3. **Build MSIX**:
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --release
   flutter pub run msix:create
   ```

4. **Verify build**:
   - Check that MSIX exists at `build/windows/x64/runner/Release/hex_buzz.msix`
   - Note the file size (should be several MB)

5. **Manual submission required**:
   - Unlike Google Play, Microsoft Store doesn't have a simple API for uploads
   - MSIX must be uploaded through Partner Center web UI
   - Cannot be fully automated without complex Partner Center API integration

## Resources

- **Partner Center**: https://partner.microsoft.com/dashboard
- **MSIX Documentation**: https://learn.microsoft.com/windows/msix/
- **Flutter MSIX Plugin**: https://pub.dev/packages/msix
- **Store Policies**: https://learn.microsoft.com/windows/apps/publish/store-policies
- **Age Ratings**: https://www.globalratings.com/

## Security Notes

- Store certificates are managed by Microsoft
- No need to manage signing certificates (unlike Android)
- Partner Center credentials should be kept secure
- Use 2FA on Partner Center account
- MSIX packages are automatically signed during Store submission

## Cost Summary

| Item | Cost | Frequency |
|------|------|-----------|
| Developer Account | $19 USD | One-time |
| App Submission | Free | Per submission |
| Updates | Free | Unlimited |

**Total to get started**: $19 USD (one-time)

# Windows App Certification Kit (WACK) Testing Guide

## Overview

The Windows App Certification Kit (WACK) is a validation tool required before submitting apps to the Microsoft Store. This guide covers how to run WACK tests on the HexBuzz MSIX package and resolve common issues.

## Prerequisites

### System Requirements
- **Operating System**: Windows 10 version 1809 or later, or Windows 11
- **WACK Version**: Included with Windows SDK (automatically installs with Visual Studio)
- **Hardware**: At least 4GB RAM, 10GB free disk space
- **Administrator Access**: Required to run WACK

### Installing WACK

WACK is included with the Windows SDK. If not already installed:

1. **Via Visual Studio**:
   - Install Visual Studio 2019 or later
   - Select "Windows 10 SDK" or "Windows 11 SDK" during installation
   - WACK will be included automatically

2. **Standalone Windows SDK**:
   - Download from: https://developer.microsoft.com/windows/downloads/windows-sdk/
   - Run installer and select "Windows App Certification Kit"
   - Complete installation

3. **Verify Installation**:
   ```powershell
   # Check if WACK is installed
   Get-Command appcert.exe

   # Should show path like:
   # C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe
   ```

## Building the MSIX Package

Before running WACK, build a release MSIX package:

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build Windows release binary
flutter build windows --release

# Create MSIX package
flutter pub run msix:create
```

**MSIX Location**: `build/windows/x64/runner/Release/hex_buzz.msix`

**Note**: Building Windows apps requires Windows OS. This cannot be done on Linux/macOS.

## Running WACK Tests

### Method 1: GUI (Recommended for First Run)

1. **Launch WACK**:
   - Press Windows key, type "Windows App Cert Kit"
   - Or run: `C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe`

2. **Select Validation Type**:
   - Choose "Validate Store App"
   - Click "Next"

3. **Select Package**:
   - Click "Browse"
   - Navigate to: `build/windows/x64/runner/Release/hex_buzz.msix`
   - Select the MSIX file
   - Click "Next"

4. **Choose Test Location**:
   - Select where to save results (default: Documents/App Certification Kit)
   - Click "Next"

5. **Run Tests**:
   - Tests will run automatically (15-30 minutes)
   - Do not use the computer during testing for accurate results
   - WACK will test:
     - App manifest validation
     - Security tests
     - Performance tests
     - Binary analyzers
     - Package sanity tests
     - Platform tests

6. **Review Results**:
   - WACK will show PASS/FAIL for each category
   - Detailed HTML report will be saved
   - Review any failures or warnings

### Method 2: Command Line (Automated)

For CI/CD or repeated testing:

```powershell
# Set variables
$msixPath = "build\windows\x64\runner\Release\hex_buzz.msix"
$reportPath = "wack_results\hex_buzz_wack_report.xml"

# Create output directory
New-Item -ItemType Directory -Force -Path "wack_results"

# Run WACK
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" `
    test -apptype metroapp `
    -appxpackagepath $msixPath `
    -reportoutputpath $reportPath

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "WACK tests PASSED" -ForegroundColor Green
} else {
    Write-Host "WACK tests FAILED - Check report at $reportPath" -ForegroundColor Red
    exit 1
}
```

### Method 3: PowerShell Script (Comprehensive)

Save this as `run_wack_tests.ps1` in the project root:

```powershell
# WACK Testing Script for HexBuzz
# Run from project root: .\run_wack_tests.ps1

param(
    [string]$MsixPath = "build\windows\x64\runner\Release\hex_buzz.msix",
    [string]$OutputDir = "wack_results",
    [switch]$BuildFirst = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== HexBuzz WACK Testing ===" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some tests may fail." -ForegroundColor Yellow
    Write-Host "For best results, run PowerShell as Administrator." -ForegroundColor Yellow
}

# Build MSIX if requested
if ($BuildFirst) {
    Write-Host "`nBuilding MSIX package..." -ForegroundColor Cyan

    flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    flutter pub run msix:create
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "MSIX build completed" -ForegroundColor Green
}

# Verify MSIX exists
if (-not (Test-Path $MsixPath)) {
    Write-Host "ERROR: MSIX file not found at: $MsixPath" -ForegroundColor Red
    Write-Host "Run with -BuildFirst to build the package first" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nFound MSIX package: $MsixPath" -ForegroundColor Green
$msixInfo = Get-Item $MsixPath
Write-Host "  Size: $([math]::Round($msixInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host "  Modified: $($msixInfo.LastWriteTime)" -ForegroundColor Gray

# Find WACK executable
$wackPath = "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe"
if (-not (Test-Path $wackPath)) {
    Write-Host "ERROR: WACK not found at expected location" -ForegroundColor Red
    Write-Host "Install Windows SDK from: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nFound WACK: $wackPath" -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Set up report paths
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xmlReport = Join-Path $OutputDir "hex_buzz_wack_${timestamp}.xml"
$htmlReport = Join-Path $OutputDir "hex_buzz_wack_${timestamp}.html"

Write-Host "`nRunning WACK tests..." -ForegroundColor Cyan
Write-Host "This will take 15-30 minutes. Do not use the computer during testing." -ForegroundColor Yellow
Write-Host "Results will be saved to: $OutputDir" -ForegroundColor Gray

# Run WACK
$startTime = Get-Date
& $wackPath test -apptype metroapp `
    -appxpackagepath (Resolve-Path $MsixPath).Path `
    -reportoutputpath $xmlReport

$exitCode = $LASTEXITCODE
$duration = (Get-Date) - $startTime

Write-Host "`nWACK tests completed in $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor Cyan

# Parse results
if (Test-Path $xmlReport) {
    [xml]$results = Get-Content $xmlReport

    Write-Host "`n=== WACK Test Results ===" -ForegroundColor Cyan

    $allTests = $results.REPORT.TEST
    $passed = ($allTests | Where-Object { $_.RESULT -eq "PASS" }).Count
    $failed = ($allTests | Where-Object { $_.RESULT -eq "FAIL" }).Count
    $warnings = ($allTests | Where-Object { $_.RESULT -eq "WARNING" }).Count

    Write-Host "  Passed: $passed" -ForegroundColor Green
    Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
    Write-Host "  Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })

    # Show failed tests
    if ($failed -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        foreach ($test in ($allTests | Where-Object { $_.RESULT -eq "FAIL" })) {
            Write-Host "  - $($test.TITLE)" -ForegroundColor Red
            if ($test.MESSAGES.MESSAGE) {
                foreach ($msg in $test.MESSAGES.MESSAGE) {
                    Write-Host "    $($msg.'#text')" -ForegroundColor Gray
                }
            }
        }
    }

    # Show warnings
    if ($warnings -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        foreach ($test in ($allTests | Where-Object { $_.RESULT -eq "WARNING" })) {
            Write-Host "  - $($test.TITLE)" -ForegroundColor Yellow
        }
    }

    Write-Host "`nDetailed report: $xmlReport" -ForegroundColor Cyan

    # Try to open HTML report if available
    if (Test-Path $htmlReport) {
        Write-Host "HTML report: $htmlReport" -ForegroundColor Cyan
        Write-Host "`nOpening HTML report in browser..." -ForegroundColor Gray
        Start-Process $htmlReport
    }
}

# Exit with WACK exit code
if ($exitCode -eq 0) {
    Write-Host "`n=== WACK PASSED ===" -ForegroundColor Green
    Write-Host "Package is ready for Microsoft Store submission" -ForegroundColor Green
} else {
    Write-Host "`n=== WACK FAILED ===" -ForegroundColor Red
    Write-Host "Fix the issues above before submitting to the Store" -ForegroundColor Red
}

exit $exitCode
```

**Usage**:
```powershell
# Run WACK on existing MSIX
.\run_wack_tests.ps1

# Build and then run WACK
.\run_wack_tests.ps1 -BuildFirst

# Custom MSIX location
.\run_wack_tests.ps1 -MsixPath "path\to\custom.msix"
```

## WACK Test Categories

WACK validates several aspects of your app:

### 1. App Manifest Tests
- **What**: Validates AppxManifest.xml structure and values
- **Common Issues**:
  - Invalid capabilities
  - Incorrect publisher ID
  - Missing required declarations
- **Fix**: Update `msix_config` in `pubspec.yaml`

### 2. Package Sanity Test
- **What**: Validates package structure and file integrity
- **Common Issues**:
  - Missing required files
  - Invalid file signatures
  - Incorrect file paths
- **Fix**: Ensure clean build, verify all assets included

### 3. Performance Tests
- **What**: Checks launch time, suspend/resume, CPU usage
- **Common Issues**:
  - Slow launch (>5 seconds)
  - High memory usage
  - App doesn't suspend properly
- **Fix**: Optimize startup code, implement proper lifecycle handling

### 4. App Manifest Resources Test
- **What**: Validates all resources referenced in manifest exist
- **Common Issues**:
  - Missing icon files
  - Incorrect logo paths
  - Missing splash screen
- **Fix**: Verify all asset paths in `pubspec.yaml`

### 5. Windows Security Features Test
- **What**: Checks security best practices
- **Common Issues**:
  - Insecure API usage
  - Deprecated functions
  - Missing security flags
- **Fix**: Update dependencies, use secure APIs

### 6. Windows Desktop Bridge Test (if applicable)
- **What**: Validates desktop bridge compatibility
- **Common Issues**:
  - Restricted API usage
  - Invalid registry access
- **Fix**: Use UWP-compatible APIs

### 7. Binary Analyzer
- **What**: Analyzes compiled binaries for compliance
- **Common Issues**:
  - Invalid PE headers
  - Missing compiler flags
  - Security vulnerabilities
- **Fix**: Update build tools, enable security flags

### 8. Platform Appropriate Files Test
- **What**: Checks for platform-specific requirements
- **Common Issues**:
  - Wrong architecture binaries
  - Missing ARM64 support (if declared)
- **Fix**: Build for correct architecture (x64)

## Common WACK Failures and Fixes

### 1. "App doesn't meet the minimum version requirement"

**Cause**: App targets older Windows version than declared

**Fix**: Update `windows_build_version` in `pubspec.yaml`:
```yaml
msix_config:
  windows_build_version: 10.0.17763.0  # Windows 10 1809
```

### 2. "App manifest validation error"

**Cause**: Invalid manifest syntax or values

**Fix**: Validate MSIX config:
- Check `publisher` matches Partner Center exactly
- Ensure `identity_name` is unique
- Verify all paths exist

### 3. "Performance test failed - Launch time"

**Cause**: App takes >5 seconds to launch

**Fix**:
- Remove heavy initialization from startup
- Use lazy loading for resources
- Profile with Flutter DevTools

### 4. "Missing logo resources"

**Cause**: Manifest references missing image files

**Fix**: Verify all icon assets exist:
```bash
# Check icon files
ls assets/icons/
```

Required icons (handled by msix plugin):
- Application icon (300x300 minimum)
- Small tile, Medium tile, Wide tile, Large tile

### 5. "Security features test failed"

**Cause**: Using insecure or deprecated APIs

**Fix**:
- Update Flutter SDK: `flutter upgrade`
- Update dependencies: `flutter pub upgrade`
- Check for security warnings in build output

### 6. "Capability not allowed"

**Cause**: Declared capability not appropriate for app type

**Fix**: Review `capabilities` in `msix_config`:
```yaml
msix_config:
  capabilities: internetClient  # Only declare what you need
```

Common allowed capabilities:
- `internetClient` - network access (HexBuzz needs this)
- `internetClientServer` - server hosting
- `privateNetworkClientServer` - local network
- `documentsLibrary` - access to documents (with file type declarations)
- `picturesLibrary` - access to pictures
- `videosLibrary` - access to videos
- `musicLibrary` - access to music

### 7. "App crashes during launch test"

**Cause**: Runtime error during startup

**Fix**:
1. Test MSIX locally before WACK
2. Check Event Viewer for crash logs
3. Add error handling to main():
```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MyApp());
  }, (error, stack) {
    // Log crash
    print('Error: $error');
  });
}
```

### 8. "High memory usage"

**Cause**: App uses excessive memory during testing

**Fix**:
- Profile memory usage with DevTools
- Dispose controllers and listeners properly
- Avoid memory leaks

## Testing on Windows 10 vs Windows 11

WACK behavior differs slightly:

### Windows 10 (1809+)
- **Required**: Minimum target for Store apps
- **WACK Version**: Matches OS version
- **Features**: Basic UWP APIs

### Windows 11
- **Optional**: Enhanced features available
- **WACK Version**: More strict validation
- **Features**: Additional APIs (rounded corners, snap layouts, etc.)

**Recommendation**: Test on Windows 10 1809 or later to ensure broadest compatibility.

## Manual Testing Checklist

After WACK passes, manually verify:

- [ ] App installs from MSIX double-click
- [ ] App launches and shows main menu
- [ ] All game features work (play levels, see progress)
- [ ] Firebase authentication works (if connected)
- [ ] Settings persist across app restarts
- [ ] Window resizing works correctly
- [ ] Keyboard shortcuts work (Ctrl+Z, Escape)
- [ ] App suspends/resumes without crashes
- [ ] App uninstalls cleanly
- [ ] No error messages in Event Viewer
- [ ] Performance is acceptable (smooth 60fps)

## Troubleshooting WACK

### WACK Won't Launch

**Symptom**: WACK crashes or doesn't open

**Solutions**:
1. Run as Administrator
2. Update Windows to latest version
3. Reinstall Windows SDK
4. Check Windows Event Viewer for errors

### WACK Tests Hang

**Symptom**: Tests run but never complete

**Solutions**:
1. Restart computer
2. Close all other apps
3. Disable antivirus temporarily
4. Check for Windows updates

### WACK Results Unclear

**Symptom**: Error messages are vague

**Solutions**:
1. Check detailed XML report
2. Search error code on Microsoft Docs
3. Compare with previous successful tests
4. Check MSIX packaging logs

### False Positives

**Symptom**: WACK fails but app works fine

**Solutions**:
1. Run WACK again (some tests are flaky)
2. Test on different Windows machine
3. Update WACK to latest version
4. Contact Microsoft Support if persistent

## CI/CD Integration

### GitHub Actions Example

```yaml
name: WACK Testing

on:
  push:
    tags:
      - 'v*'

jobs:
  wack-test:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.9.2'

    - name: Install dependencies
      run: flutter pub get

    - name: Build MSIX
      run: |
        flutter build windows --release
        flutter pub run msix:create

    - name: Run WACK
      shell: powershell
      run: |
        $wackPath = "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe"
        $msixPath = "build\windows\x64\runner\Release\hex_buzz.msix"
        $reportPath = "wack_results\report.xml"

        New-Item -ItemType Directory -Force -Path "wack_results"

        & $wackPath test -apptype metroapp `
          -appxpackagepath $msixPath `
          -reportoutputpath $reportPath

        exit $LASTEXITCODE

    - name: Upload WACK Results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: wack-results
        path: wack_results/

    - name: Upload MSIX
      if: success()
      uses: actions/upload-artifact@v3
      with:
        name: hex_buzz-msix
        path: build/windows/x64/runner/Release/hex_buzz.msix
```

## Next Steps After WACK Passes

1. **Create Store Assets**:
   - Screenshots (1366x768 minimum, 4-10 images)
   - App description (compelling copy)
   - Keywords for search optimization

2. **Reserve App Name**:
   - Go to Partner Center
   - Reserve "HexBuzz" name
   - Get publisher ID

3. **Update Publisher ID**:
   - Update `publisher` in `pubspec.yaml`
   - Rebuild MSIX with correct publisher
   - Run WACK again to verify

4. **Submit to Store**:
   - Upload MSIX to Partner Center
   - Fill in store listing
   - Submit for certification

5. **Monitor Certification**:
   - Check Partner Center daily
   - Respond to any feedback
   - Publish once approved

## Resources

- **WACK Documentation**: https://learn.microsoft.com/windows/uwp/debug-test-perf/windows-app-certification-kit
- **Store Policies**: https://learn.microsoft.com/windows/apps/publish/store-policies
- **MSIX Packaging**: https://learn.microsoft.com/windows/msix/
- **Flutter Windows**: https://docs.flutter.dev/platform-integration/windows/building
- **Partner Center**: https://partner.microsoft.com/dashboard

## Support

If WACK testing fails repeatedly:

1. Review detailed XML report
2. Check Microsoft Store Developer forums
3. Contact Microsoft Developer Support
4. Consider Windows SDK version compatibility

## Summary

WACK testing is mandatory for Microsoft Store submission. Follow this guide to:

1. Build release MSIX package
2. Run WACK tests (GUI or CLI)
3. Fix any failures
4. Verify manual testing checklist
5. Submit to Store once passed

**Time Required**: 1-2 hours (including fixes)

**Pass Rate**: ~80% on first try with proper configuration

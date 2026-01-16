#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Prepares HexBuzz for Microsoft Store submission

.DESCRIPTION
    Automates the pre-submission checklist for Microsoft Store deployment:
    - Validates configuration
    - Builds MSIX package
    - Runs validation checks
    - Generates submission checklist

.PARAMETER SkipBuild
    Skip the Flutter build step (use existing build)

.PARAMETER SkipWack
    Skip WACK testing (not recommended)

.PARAMETER PublisherId
    Your Microsoft Partner Center Publisher ID (format: CN=XXXX...)
    If not provided, will check pubspec.yaml

.EXAMPLE
    .\prepare_store_submission.ps1

.EXAMPLE
    .\prepare_store_submission.ps1 -PublisherId "CN=12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\prepare_store_submission.ps1 -SkipWack
#>

param(
    [switch]$SkipBuild,
    [switch]$SkipWack,
    [string]$PublisherId
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success($message) { Write-Host "✓ $message" -ForegroundColor Green }
function Write-Error-Custom($message) { Write-Host "✗ $message" -ForegroundColor Red }
function Write-Warning-Custom($message) { Write-Host "⚠ $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ $message" -ForegroundColor Cyan }
function Write-Step($message) { Write-Host "`n>>> $message" -ForegroundColor Magenta }

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          Microsoft Store Submission Preparation              ║
║                     HexBuzz v1.0.0                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if running on Windows
if ($PSVersionTable.Platform -eq 'Unix') {
    Write-Error-Custom "This script must run on Windows for MSIX packaging and WACK testing"
    Write-Info "Current platform: Unix/Linux/macOS"
    Write-Info "Please run this script on a Windows machine"
    exit 1
}

# Validate prerequisites
Write-Step "Validating prerequisites..."

# Check Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
    Write-Success "Flutter installed: $flutterVersion"
} catch {
    Write-Error-Custom "Flutter not found. Please install Flutter: https://flutter.dev"
    exit 1
}

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error-Custom "pubspec.yaml not found. Please run from project root directory."
    exit 1
}
Write-Success "Project directory confirmed"

# Parse pubspec.yaml
Write-Step "Parsing project configuration..."

$pubspecContent = Get-Content "pubspec.yaml" -Raw
$appName = ($pubspecContent | Select-String "name:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
$version = ($pubspecContent | Select-String "version:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
$publisherInYaml = ($pubspecContent | Select-String "publisher:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
$identityName = ($pubspecContent | Select-String "identity_name:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
$msixVersion = ($pubspecContent | Select-String "msix_version:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()

Write-Info "App Name: $appName"
Write-Info "Version: $version"
Write-Info "MSIX Version: $msixVersion"
Write-Info "Identity Name: $identityName"

# Check Publisher ID
if ($PublisherId) {
    Write-Info "Publisher ID (from parameter): $PublisherId"
    if ($publisherInYaml -ne $PublisherId) {
        Write-Warning-Custom "Publisher ID parameter differs from pubspec.yaml"
        Write-Info "Will update pubspec.yaml with provided Publisher ID"

        # Update pubspec.yaml
        $pubspecContent = $pubspecContent -replace "publisher:\s*CN=.*", "publisher: $PublisherId"
        Set-Content "pubspec.yaml" -Value $pubspecContent
        Write-Success "Updated pubspec.yaml with new Publisher ID"
    }
} else {
    Write-Info "Publisher ID: $publisherInYaml"
    if ($publisherInYaml -match "YourPublisherID" -or $publisherInYaml -match "^CN=$" -or [string]::IsNullOrWhiteSpace($publisherInYaml)) {
        Write-Error-Custom "Publisher ID not set in pubspec.yaml!"
        Write-Info "`nTo get your Publisher ID:"
        Write-Info "1. Go to https://partner.microsoft.com/dashboard"
        Write-Info "2. Navigate to: Account Settings → Organization Profile → Identities"
        Write-Info "3. Copy your Publisher ID (format: CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)"
        Write-Info "4. Either:"
        Write-Info "   - Update 'publisher' in pubspec.yaml manually, or"
        Write-Info "   - Run: .\prepare_store_submission.ps1 -PublisherId 'CN=YOUR-ID-HERE'"
        exit 1
    }
}
Write-Success "Publisher ID validated"

# Check assets
Write-Step "Checking required assets..."

$requiredAssets = @(
    "assets/icons/app_icon.png"
)

foreach ($asset in $requiredAssets) {
    if (Test-Path $asset) {
        Write-Success "Found: $asset"
    } else {
        Write-Error-Custom "Missing: $asset"
        exit 1
    }
}

# Check screenshots
$screenshotDir = "screenshots/store"
if (Test-Path $screenshotDir) {
    $screenshots = Get-ChildItem $screenshotDir -Filter "*.png" -ErrorAction SilentlyContinue
    if ($screenshots.Count -ge 4) {
        Write-Success "Screenshots ready: $($screenshots.Count) found in $screenshotDir"
    } else {
        Write-Warning-Custom "Only $($screenshots.Count) screenshots found (minimum: 4)"
        Write-Info "Capture screenshots at 1920x1080 and save to: $screenshotDir"
        Write-Info "See docs/SCREENSHOT_GUIDE.md for details"
    }
} else {
    Write-Warning-Custom "Screenshot directory not found: $screenshotDir"
    Write-Info "Create directory and add at least 4 screenshots (1920x1080)"
}

# Build MSIX
if (-not $SkipBuild) {
    Write-Step "Building MSIX package..."

    Write-Info "Running flutter clean..."
    flutter clean | Out-Null

    Write-Info "Running flutter pub get..."
    flutter pub get | Out-Null

    Write-Info "Building Windows release (this may take several minutes)..."
    $buildStart = Get-Date
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Flutter build failed"
        exit 1
    }
    $buildDuration = ((Get-Date) - $buildStart).TotalSeconds
    Write-Success "Build completed in $([math]::Round($buildDuration, 1)) seconds"

    Write-Info "Creating MSIX package..."
    $msixStart = Get-Date
    flutter pub run msix:create
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "MSIX creation failed"
        exit 1
    }
    $msixDuration = ((Get-Date) - $msixStart).TotalSeconds
    Write-Success "MSIX created in $([math]::Round($msixDuration, 1)) seconds"
} else {
    Write-Warning-Custom "Skipping build (using existing build)"
}

# Verify MSIX exists
$msixPath = "build\windows\x64\runner\Release\hex_buzz.msix"
if (Test-Path $msixPath) {
    $msixSize = (Get-Item $msixPath).Length / 1MB
    Write-Success "MSIX package found: $msixPath ($([math]::Round($msixSize, 2)) MB)"
} else {
    Write-Error-Custom "MSIX package not found at: $msixPath"
    Write-Info "Run without -SkipBuild to build the package"
    exit 1
}

# Run WACK
if (-not $SkipWack) {
    Write-Step "Running Windows App Certification Kit (WACK)..."

    $wackScript = ".\run_wack_tests.ps1"
    if (Test-Path $wackScript) {
        Write-Info "Starting WACK tests (this takes 15-30 minutes)..."
        Write-Warning-Custom "Do not use your computer during testing - it affects performance metrics"

        & $wackScript -OpenReport:$false

        if ($LASTEXITCODE -eq 0) {
            Write-Success "WACK tests passed!"
        } else {
            Write-Error-Custom "WACK tests failed"
            Write-Info "Review the report in wack_results/ directory"
            Write-Info "See docs/WACK_TESTING_GUIDE.md for troubleshooting"
            exit 1
        }
    } else {
        Write-Warning-Custom "WACK script not found: $wackScript"
        Write-Info "Run WACK manually or ensure script exists"
    }
} else {
    Write-Warning-Custom "Skipping WACK tests (NOT RECOMMENDED)"
    Write-Info "Microsoft Store requires WACK certification"
    Write-Info "Run .\run_wack_tests.ps1 before submission"
}

# Generate submission checklist
Write-Step "Generating submission checklist..."

$checklist = @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              Microsoft Store Submission Checklist            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

✓ COMPLETED AUTOMATICALLY:
  ✓ Publisher ID configured
  ✓ MSIX package built: $msixPath
  ✓ MSIX size: $([math]::Round((Get-Item $msixPath).Length / 1MB, 2)) MB
  $(if (-not $SkipWack) { "✓ WACK tests passed" } else { "⚠ WACK tests skipped (REQUIRED before submission)" })

⚠ MANUAL STEPS REQUIRED:

Partner Center Setup:
  [ ] Partner Center account created and approved
  [ ] App name "HexBuzz" reserved
  [ ] Publisher ID matches: $publisherInYaml

Screenshots:
  [ ] Captured 4-8 screenshots at 1920x1080
  [ ] Saved to: screenshots/store/
  [ ] See docs/SCREENSHOT_GUIDE.md for guidance

Privacy Policy:
  [ ] Privacy policy deployed to web
  [ ] URL is publicly accessible (HTTPS)
  [ ] Privacy policy URL: ______________________________

Store Listing Content (prepared in docs/store_listing.md):
  [ ] Review app description (2,647 chars)
  [ ] Review key features (10 bullet points)
  [ ] Review keywords (7 terms)
  [ ] Review release notes

Submission Process:
  [ ] Go to https://partner.microsoft.com/dashboard
  [ ] Start new submission for HexBuzz
  [ ] Complete all required sections:
      [ ] Pricing and availability (Free, All markets)
      [ ] Properties (Games → Puzzle)
      [ ] Age ratings (Complete IARC questionnaire → E rating)
      [ ] Packages (Upload: $msixPath)
      [ ] Store listings (Description, screenshots, privacy URL)
      [ ] Notes for certification (See docs/MS_STORE_SUBMISSION.md)
  [ ] Review all sections (all green checkmarks)
  [ ] Submit to the Store

Post-Submission:
  [ ] Monitor certification status (1-3 days)
  [ ] Respond to any certification issues
  [ ] Verify app appears in Store after approval
  [ ] Test installation from Store

📖 DETAILED INSTRUCTIONS:
   See docs/MS_STORE_SUBMISSION.md for complete step-by-step guide

📧 CERTIFICATION TIMELINE:
   - Pre-processing: 5-30 minutes
   - Security testing: 2-6 hours
   - Technical compliance: 1-3 days
   - Content compliance: 1-2 days
   - Total: 1-3 business days

🚀 NEXT STEPS:
   1. Complete manual checklist items above
   2. Follow submission guide in docs/MS_STORE_SUBMISSION.md
   3. Monitor Partner Center for certification status
   4. Celebrate when app goes live! 🎉

═══════════════════════════════════════════════════════════════

Package ready for submission!
Location: $msixPath
"@

Write-Host $checklist

# Save checklist to file
$checklistFile = "SUBMISSION_CHECKLIST.txt"
$checklist | Out-File $checklistFile -Encoding UTF8
Write-Success "Checklist saved to: $checklistFile"

Write-Host "`n"
Write-Success "Preparation complete!"
Write-Info "Next: Follow the manual steps in the checklist above"
Write-Info "Detailed guide: docs/MS_STORE_SUBMISSION.md"
Write-Host "`n"

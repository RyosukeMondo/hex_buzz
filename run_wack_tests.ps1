# WACK Testing Script for HexBuzz
# Run from project root: .\run_wack_tests.ps1
# Requires: Windows 10 1809+ or Windows 11, Windows SDK with WACK installed

param(
    [string]$MsixPath = "build\windows\x64\runner\Release\hex_buzz.msix",
    [string]$OutputDir = "wack_results",
    [switch]$BuildFirst = $false,
    [switch]$OpenReport = $true
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   HexBuzz WACK Testing Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some WACK tests may fail or show warnings." -ForegroundColor Yellow
    Write-Host "For best results, run PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "Continue anyway? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Exiting. Please restart PowerShell as Administrator." -ForegroundColor Yellow
        exit 1
    }
    Write-Host ""
}

# Build MSIX if requested
if ($BuildFirst) {
    Write-Host "Building MSIX package..." -ForegroundColor Cyan
    Write-Host ""

    # Clean
    Write-Host "Step 1/4: Cleaning previous builds..." -ForegroundColor Gray
    flutter clean
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter clean failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # Get dependencies
    Write-Host "Step 2/4: Getting dependencies..." -ForegroundColor Gray
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter pub get failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # Build Windows release
    Write-Host "Step 3/4: Building Windows release..." -ForegroundColor Gray
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter build windows failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # Create MSIX
    Write-Host "Step 4/4: Creating MSIX package..." -ForegroundColor Gray
    flutter pub run msix:create
    if ($LASTEXITCODE -ne 0) {
        Write-Host "MSIX creation failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    Write-Host ""
    Write-Host "MSIX build completed successfully" -ForegroundColor Green
    Write-Host ""
}

# Verify MSIX exists
Write-Host "Checking for MSIX package..." -ForegroundColor Cyan
if (-not (Test-Path $MsixPath)) {
    Write-Host "ERROR: MSIX file not found at: $MsixPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "  1. Run with -BuildFirst flag to build the package" -ForegroundColor Yellow
    Write-Host "  2. Manually build with: flutter pub run msix:create" -ForegroundColor Yellow
    Write-Host "  3. Specify custom path with -MsixPath parameter" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Found MSIX package: $MsixPath" -ForegroundColor Green
$msixInfo = Get-Item $MsixPath
Write-Host "  Size: $([math]::Round($msixInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host "  Modified: $($msixInfo.LastWriteTime)" -ForegroundColor Gray
Write-Host ""

# Find WACK executable
Write-Host "Locating Windows App Certification Kit..." -ForegroundColor Cyan
$wackPath = "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe"

if (-not (Test-Path $wackPath)) {
    # Try alternative locations
    $alternativePaths = @(
        "C:\Program Files\Windows Kits\10\App Certification Kit\appcert.exe",
        "C:\Program Files (x86)\Windows Kits\11\App Certification Kit\appcert.exe",
        "C:\Program Files\Windows Kits\11\App Certification Kit\appcert.exe"
    )

    $found = $false
    foreach ($altPath in $alternativePaths) {
        if (Test-Path $altPath) {
            $wackPath = $altPath
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "ERROR: Windows App Certification Kit (WACK) not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "WACK is required to test Windows Store packages." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Installation options:" -ForegroundColor Yellow
        Write-Host "  1. Install Visual Studio with Windows SDK" -ForegroundColor Yellow
        Write-Host "  2. Install standalone Windows SDK from:" -ForegroundColor Yellow
        Write-Host "     https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

Write-Host "Found WACK: $wackPath" -ForegroundColor Green
Write-Host ""

# Create output directory
Write-Host "Preparing output directory..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
Write-Host "Results will be saved to: $OutputDir" -ForegroundColor Gray
Write-Host ""

# Set up report paths
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$xmlReport = Join-Path $OutputDir "hex_buzz_wack_${timestamp}.xml"

# Show pre-test information
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "   Starting WACK Tests" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Duration: This will take approximately 15-30 minutes" -ForegroundColor Yellow
Write-Host "Important: Do NOT use the computer during testing" -ForegroundColor Yellow
Write-Host "Reason: WACK measures performance metrics that require system idle" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tests include:" -ForegroundColor Gray
Write-Host "  - App manifest validation" -ForegroundColor Gray
Write-Host "  - Package sanity checks" -ForegroundColor Gray
Write-Host "  - Performance tests (launch time, suspend/resume)" -ForegroundColor Gray
Write-Host "  - Security validation" -ForegroundColor Gray
Write-Host "  - Binary analysis" -ForegroundColor Gray
Write-Host "  - Platform compliance" -ForegroundColor Gray
Write-Host ""

# Countdown
Write-Host "Starting in..." -ForegroundColor Cyan
for ($i = 5; $i -gt 0; $i--) {
    Write-Host "  $i..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}
Write-Host ""

# Run WACK
$startTime = Get-Date
Write-Host "Running WACK tests..." -ForegroundColor Cyan
Write-Host "Started at: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host ""

& $wackPath test -apptype metroapp `
    -appxpackagepath (Resolve-Path $MsixPath).Path `
    -reportoutputpath $xmlReport

$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "WACK tests completed" -ForegroundColor Cyan
Write-Host "Ended at: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor Gray
Write-Host ""

# Parse and display results
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   WACK Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $xmlReport) {
    try {
        [xml]$results = Get-Content $xmlReport

        $allTests = $results.REPORT.TEST
        $passed = ($allTests | Where-Object { $_.RESULT -eq "PASS" }).Count
        $failed = ($allTests | Where-Object { $_.RESULT -eq "FAIL" }).Count
        $warnings = ($allTests | Where-Object { $_.RESULT -eq "WARNING" }).Count
        $total = $allTests.Count

        # Summary
        Write-Host "Summary:" -ForegroundColor White
        Write-Host "  Total Tests: $total" -ForegroundColor Gray
        Write-Host "  Passed:      $passed" -ForegroundColor Green
        Write-Host "  Failed:      $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
        Write-Host "  Warnings:    $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
        Write-Host ""

        # Show failed tests with details
        if ($failed -gt 0) {
            Write-Host "Failed Tests:" -ForegroundColor Red
            Write-Host ""
            $failNum = 1
            foreach ($test in ($allTests | Where-Object { $_.RESULT -eq "FAIL" })) {
                Write-Host "  ${failNum}. $($test.TITLE)" -ForegroundColor Red
                if ($test.DESCRIPTION) {
                    Write-Host "     Description: $($test.DESCRIPTION)" -ForegroundColor Gray
                }
                if ($test.MESSAGES.MESSAGE) {
                    Write-Host "     Details:" -ForegroundColor Gray
                    foreach ($msg in $test.MESSAGES.MESSAGE) {
                        $msgText = $msg.'#text'
                        if ($msgText) {
                            Write-Host "       - $msgText" -ForegroundColor DarkGray
                        }
                    }
                }
                Write-Host ""
                $failNum++
            }
        }

        # Show warnings
        if ($warnings -gt 0) {
            Write-Host "Warnings:" -ForegroundColor Yellow
            Write-Host ""
            $warnNum = 1
            foreach ($test in ($allTests | Where-Object { $_.RESULT -eq "WARNING" })) {
                Write-Host "  ${warnNum}. $($test.TITLE)" -ForegroundColor Yellow
                if ($test.DESCRIPTION) {
                    Write-Host "     Description: $($test.DESCRIPTION)" -ForegroundColor Gray
                }
                Write-Host ""
                $warnNum++
            }
        }

        # Show all passed test categories (brief)
        if ($passed -gt 0) {
            Write-Host "Passed Test Categories:" -ForegroundColor Green
            foreach ($test in ($allTests | Where-Object { $_.RESULT -eq "PASS" })) {
                Write-Host "  ✓ $($test.TITLE)" -ForegroundColor Green
            }
            Write-Host ""
        }

    } catch {
        Write-Host "WARNING: Could not parse WACK XML report" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host "Detailed XML report: $xmlReport" -ForegroundColor Cyan

    # Look for HTML report
    $htmlReport = $xmlReport -replace '\.xml$', '.html'
    if (Test-Path $htmlReport) {
        Write-Host "HTML report: $htmlReport" -ForegroundColor Cyan

        if ($OpenReport) {
            Write-Host ""
            Write-Host "Opening HTML report in browser..." -ForegroundColor Gray
            Start-Process $htmlReport
        }
    }
    Write-Host ""
} else {
    Write-Host "WARNING: WACK report not generated" -ForegroundColor Yellow
    Write-Host "Check if WACK completed successfully" -ForegroundColor Yellow
    Write-Host ""
}

# Final status
Write-Host "========================================" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "   ✓ WACK PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Congratulations! Your package passed all WACK tests." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Review any warnings in the report" -ForegroundColor Gray
    Write-Host "  2. Test the MSIX manually on Windows 10 1809+" -ForegroundColor Gray
    Write-Host "  3. Prepare store assets (screenshots, description)" -ForegroundColor Gray
    Write-Host "  4. Update publisher ID in pubspec.yaml from Partner Center" -ForegroundColor Gray
    Write-Host "  5. Rebuild and re-test with correct publisher ID" -ForegroundColor Gray
    Write-Host "  6. Submit to Microsoft Store via Partner Center" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See docs/MS_STORE_DEPLOYMENT.md for submission guide" -ForegroundColor Cyan
} else {
    Write-Host "   ✗ WACK FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Your package failed WACK certification." -ForegroundColor Red
    Write-Host ""
    Write-Host "What to do:" -ForegroundColor White
    Write-Host "  1. Review the failed tests above" -ForegroundColor Gray
    Write-Host "  2. Check detailed report: $xmlReport" -ForegroundColor Gray
    Write-Host "  3. See docs/WACK_TESTING_GUIDE.md for solutions" -ForegroundColor Gray
    Write-Host "  4. Fix the issues in your code or configuration" -ForegroundColor Gray
    Write-Host "  5. Rebuild and re-test" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor White
    Write-Host "  - Update publisher ID in pubspec.yaml" -ForegroundColor Gray
    Write-Host "  - Verify all logo assets exist" -ForegroundColor Gray
    Write-Host "  - Optimize app launch time" -ForegroundColor Gray
    Write-Host "  - Review capabilities in msix_config" -ForegroundColor Gray
}
Write-Host ""

exit $exitCode

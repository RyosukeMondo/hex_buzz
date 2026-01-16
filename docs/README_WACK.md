# WACK Testing Documentation

This folder contains comprehensive documentation for testing HexBuzz with the Windows App Certification Kit (WACK) before Microsoft Store submission.

## Quick Start

```powershell
# On Windows, run from project root:
.\run_wack_tests.ps1 -BuildFirst
```

## Documentation Files

### WACK_TESTING_GUIDE.md
**Comprehensive testing guide** covering:
- WACK installation and setup
- Running tests (GUI, CLI, automated script)
- All 8 test categories explained
- Common failures with detailed fixes
- Manual testing checklist
- CI/CD integration examples
- Troubleshooting guide

**When to use**: Read this for complete understanding of WACK testing process.

### MS_STORE_DEPLOYMENT.md
**Microsoft Store deployment guide** including:
- MSIX packaging configuration
- WACK testing quick start section
- Store submission process
- Version management
- Publisher ID setup

**When to use**: Follow this for the complete Store deployment workflow.

## Testing Scripts

### run_wack_tests.ps1
**Automated PowerShell script** features:
- Optional pre-build automation
- Administrator privilege checking
- Color-coded results with details
- HTML report auto-opening
- Failure diagnostics and suggestions
- Duration tracking

**Location**: Project root

**Usage**:
```powershell
# Build and test
.\run_wack_tests.ps1 -BuildFirst

# Test existing MSIX
.\run_wack_tests.ps1

# Custom MSIX path
.\run_wack_tests.ps1 -MsixPath "path\to\package.msix"
```

## WACK Testing Workflow

```
1. Build MSIX Package
   ↓
2. Run WACK Tests (15-30 min)
   ↓
3. Review Results
   ↓
   ├─ PASS → Manual Testing → Store Submission
   └─ FAIL → Fix Issues → Rebuild → Re-test WACK
```

## Common WACK Failures

| Issue | File to Check | Fix |
|-------|--------------|-----|
| Publisher ID mismatch | `pubspec.yaml` | Update `publisher` with Partner Center ID |
| Slow launch time | `lib/main.dart` | Optimize initialization |
| Missing logos | `assets/icons/` | Verify all icon files exist |
| Invalid capabilities | `pubspec.yaml` | Use only `internetClient` |
| Version requirement | `pubspec.yaml` | Set `windows_build_version: 10.0.17763.0` |

## Prerequisites

- **Windows 10 version 1809+** or **Windows 11**
- **Windows SDK** with WACK installed (via Visual Studio or standalone)
- **Administrator access** for running tests
- **Flutter SDK** configured for Windows development

## Important Notes

1. **Run as Administrator**: For best results, run PowerShell as Admin
2. **No interruption**: Don't use computer during testing (affects performance metrics)
3. **Clean state**: Close all other apps before testing
4. **Multiple runs**: Some tests can be flaky; verify with 2-3 runs
5. **Publisher ID**: Must obtain from Microsoft Partner Center before final build

## Testing on Different Systems

### Windows 10 1809+
- Minimum required version for Store submission
- Most conservative testing environment
- Tests basic UWP API compliance

### Windows 11
- Enhanced features available
- More strict validation in some areas
- Tests modern Windows APIs

**Recommendation**: Test on Windows 10 1809 first to ensure broadest compatibility.

## Next Steps After WACK Passes

1. ✅ Review any warnings (not blockers, but should fix if possible)
2. ✅ Install MSIX locally and test manually
3. ✅ Verify on Windows 10 1809 and Windows 11
4. ✅ Check Windows Event Viewer for runtime errors
5. ✅ Test all game features work correctly
6. ✅ Obtain Publisher ID from Partner Center
7. ✅ Update `publisher` in `pubspec.yaml`
8. ✅ Rebuild MSIX with correct publisher ID
9. ✅ Re-run WACK to verify
10. ✅ Proceed to Microsoft Store submission

## Resources

- **WACK Documentation**: https://learn.microsoft.com/windows/uwp/debug-test-perf/windows-app-certification-kit
- **Store Policies**: https://learn.microsoft.com/windows/apps/publish/store-policies
- **Windows SDK**: https://developer.microsoft.com/windows/downloads/windows-sdk/
- **Partner Center**: https://partner.microsoft.com/dashboard
- **MSIX Packaging**: https://learn.microsoft.com/windows/msix/

## Support

If you encounter issues:

1. Check **WACK_TESTING_GUIDE.md** troubleshooting section
2. Review detailed XML report in `wack_results/`
3. Search error messages on Microsoft Docs
4. Check Microsoft Developer forums
5. Contact Microsoft Developer Support

## Summary

WACK testing is **mandatory** for Microsoft Store submission. This documentation and tooling provides:

- ✅ Comprehensive testing guides
- ✅ Automated testing scripts
- ✅ Common failure solutions
- ✅ CI/CD integration examples
- ✅ Complete deployment workflow

**Time to pass WACK**: Typically 1-2 hours including fixes

**Pass rate**: ~80% on first try with proper configuration

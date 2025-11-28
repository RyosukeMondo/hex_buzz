# Google Play Store Deployment Guide

This document describes how to deploy HexBuzz to Google Play Store, both manually and autonomously via CLI/API.

## Quick Reference

```bash
# Deploy to internal testing (full rebuild)
./tool/deploy/build_and_deploy.sh internal

# Deploy existing AAB to internal testing
export GOOGLE_PLAY_KEY_FILE=~/.config/gcloud/play-store-key.json
./tool/deploy/deploy_play_store.py --aab build/app/outputs/bundle/release/app-release.aab --track internal

# Deploy to production
./tool/deploy/build_and_deploy.sh production
```

## Application Info

| Property | Value |
|----------|-------|
| Application ID | `blog.techvisual.hexbuzz` |
| App Name | HexBuzz |
| GCP Project | `serotonin-charge` |
| Service Account | `play-store-deploy@serotonin-charge.iam.gserviceaccount.com` |

## File Locations

| File | Path | Purpose |
|------|------|---------|
| Release Keystore | `~/.android-keys/hexbuzz-release.jks` | Signs release builds (BACKUP THIS!) |
| Key Properties | `android/key.properties` | Keystore config (gitignored) |
| Service Account Key | `~/.config/gcloud/play-store-key.json` | API authentication |
| Built AAB | `build/app/outputs/bundle/release/app-release.aab` | Upload artifact |

## Deployment Tracks

| Track | Command | Review | Use Case |
|-------|---------|--------|----------|
| `internal` | `./tool/deploy/build_and_deploy.sh internal` | No | Quick testing, dev builds |
| `alpha` | `./tool/deploy/build_and_deploy.sh alpha` | No | Closed testing |
| `beta` | `./tool/deploy/build_and_deploy.sh beta` | No | Open testing |
| `production` | `./tool/deploy/build_and_deploy.sh production` | Yes | Public release |

## Version Management

Before each deployment, increment the version in `pubspec.yaml`:

```yaml
version: 1.0.1+2  # Format: major.minor.patch+versionCode
```

- `1.0.1` = Version name (shown to users)
- `+2` = Version code (must increment for each upload)

## Autonomous Deployment Steps

### 1. Update Version
```bash
# Edit pubspec.yaml and increment version
# Example: 1.0.0+1 → 1.0.1+2
```

### 2. Build and Deploy
```bash
./tool/deploy/build_and_deploy.sh internal
```

This script will:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Build release AAB with `flutter build appbundle --release`
4. Upload to specified track via Google Play API

### 3. Verify in Play Console
Check deployment status at:
https://play.google.com/console/u/0/developers/5560257795228784654/app/4974507702201498933/tracks/internal-testing

## Manual Deployment (First Time or Troubleshooting)

1. Build AAB:
   ```bash
   flutter build appbundle --release
   ```

2. Go to Play Console → HexBuzz → テストとリリース → 内部テスト

3. Click 新しいリリースを作成

4. Upload `build/app/outputs/bundle/release/app-release.aab`

5. Complete release notes and publish

## Initial Setup (One-Time)

This section documents the initial setup for future reference.

### 1. Create Release Keystore
```bash
mkdir -p ~/.android-keys
keytool -genkey -v \
  -keystore ~/.android-keys/hexbuzz-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias hexbuzz \
  -dname "CN=HexBuzz, OU=Mobile, O=Tech Visual, L=Tokyo, ST=Tokyo, C=JP" \
  -storepass YOUR_PASSWORD \
  -keypass YOUR_PASSWORD
```

### 2. Create key.properties
```bash
cat > android/key.properties << 'EOF'
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=hexbuzz
storeFile=/home/rmondo/.android-keys/hexbuzz-release.jks
EOF
```

### 3. Enable Google Play API (via gcloud)
```bash
gcloud config set project serotonin-charge
gcloud services enable androidpublisher.googleapis.com
```

### 4. Create Service Account
```bash
gcloud iam service-accounts create play-store-deploy \
  --display-name="Play Store Deploy" \
  --description="Service account for deploying apps to Google Play Store"
```

### 5. Download Service Account Key
```bash
gcloud iam service-accounts keys create ~/.config/gcloud/play-store-key.json \
  --iam-account=play-store-deploy@serotonin-charge.iam.gserviceaccount.com
chmod 600 ~/.config/gcloud/play-store-key.json
```

### 6. Grant Access in Play Console
1. Go to Play Console → Settings → Users & Permissions (ユーザーと権限)
2. Click "Invite new users" (新しいユーザーを招待)
3. Enter: `play-store-deploy@serotonin-charge.iam.gserviceaccount.com`
4. Grant Admin permissions
5. Click Invite

### 7. First Manual Upload (Required)
The Google Play API only works after at least one AAB has been uploaded manually via the Play Console UI.

## Troubleshooting

### "Package not found" Error
- First AAB must be uploaded manually via Play Console
- Check application ID matches `blog.techvisual.hexbuzz`

### "Version code already used" Error
- Increment the version code in `pubspec.yaml`
- The `+N` suffix must be higher than any previous upload

### Authentication Errors
- Verify `GOOGLE_PLAY_KEY_FILE` is set correctly
- Check service account has permissions in Play Console
- Permissions may take up to 24 hours to propagate

### Build Failures with R8
- Check `android/app/proguard-rules.pro` for missing rules
- Add `-dontwarn` for missing classes

### Lost Keystore
**CRITICAL**: If `~/.android-keys/hexbuzz-release.jks` is lost, you cannot update the app.
- Always backup the keystore file
- Store password securely (password manager recommended)

## Environment Variables

Add to `~/.bashrc` for convenience:
```bash
export GOOGLE_PLAY_KEY_FILE=~/.config/gcloud/play-store-key.json
```

## For AI Agents

When deploying a new version:

1. **Check current version**: `grep "version:" pubspec.yaml`
2. **Increment version**: Edit `pubspec.yaml`, increment both version name and code
3. **Build and deploy**: `./tool/deploy/build_and_deploy.sh internal`
4. **Verify**: Check output for "Deployed version X to internal"

Key files to never commit:
- `android/key.properties` (contains passwords)
- `~/.android-keys/` (keystore)
- `~/.config/gcloud/play-store-key.json` (API credentials)

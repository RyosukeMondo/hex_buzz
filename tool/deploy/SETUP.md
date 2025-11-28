# Google Play Store Deployment Setup

## One-time Setup Steps

### 1. Create App in Play Console (First time only)

1. Go to [Play Console](https://play.google.com/console)
2. Click "Create app"
3. Fill in:
   - App name: **HexBuzz**
   - Default language: English (or your preference)
   - App or game: **Game**
   - Free or paid: **Free** (or paid)
4. Complete the declarations and click "Create app"

### 2. Create Service Account for API Access

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing one
3. Enable the **Google Play Android Developer API**:
   - Go to APIs & Services > Enable APIs
   - Search for "Google Play Android Developer API"
   - Click Enable

4. Create a Service Account:
   - Go to IAM & Admin > Service Accounts
   - Click "Create Service Account"
   - Name: `play-store-deploy`
   - Click "Create and Continue"
   - Skip role assignment (we'll do this in Play Console)
   - Click "Done"

5. Create JSON Key:
   - Click on the service account you created
   - Go to Keys tab
   - Add Key > Create new key > JSON
   - Download and save securely (e.g., `~/.config/gcloud/play-store-key.json`)

### 3. Grant API Access in Play Console

1. Go to [Play Console](https://play.google.com/console)
2. Go to Settings > API access
3. Click "Link" next to your Google Cloud project
4. Find your service account and click "Manage Play Console permissions"
5. Grant permissions:
   - **Releases**: Admin (manage production/testing releases)
   - Click "Invite user"
6. Apply permissions to your app

### 4. Initial Manual Upload (Required)

**Important**: The first AAB upload must be done manually via Play Console.

1. In Play Console, go to your app
2. Go to Release > Production (or Testing > Internal testing)
3. Click "Create new release"
4. Upload the AAB: `build/app/outputs/bundle/release/app-release.aab`
5. Complete the store listing (description, screenshots, etc.)
6. Submit for review

After the first manual upload, the API can be used for subsequent uploads.

## Automated Deployment

Once setup is complete:

```bash
# Set environment variable
export GOOGLE_PLAY_KEY_FILE=~/.config/gcloud/play-store-key.json

# Build and deploy to internal testing
./tool/deploy/build_and_deploy.sh internal

# Or deploy to production
./tool/deploy/build_and_deploy.sh production
```

### Track Options

- `internal` - Internal testing (immediate, no review)
- `alpha` - Closed testing
- `beta` - Open testing
- `production` - Production release (requires review)

## Troubleshooting

### "App not found" error
- Make sure the first AAB was uploaded manually
- Check that service account has correct permissions

### "Version code already used" error
- Increment `version` in `pubspec.yaml`
- The version code (build number) must be higher than any previous upload

### Authentication errors
- Verify the JSON key file path is correct
- Check that the service account has API access in Play Console

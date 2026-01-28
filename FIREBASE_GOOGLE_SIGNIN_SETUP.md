# 🔐 Firebase Google Sign-In Setup Guide

## Current Status

✅ **Firebase Options Configured** (`lib/firebase_options.dart`)
- Project: `hexbuzz-game`
- Project Number: `384062554696`
- API Key: `AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc`
- Auth Domain: `hexbuzz-game.firebaseapp.com`

⚠️ **Google Sign-In NOT configured yet** - Follow steps below

---

## 🎯 What Needs to Be Done

Google Sign-In requires browser-based configuration in the Firebase Console.
The error "null check operator used on a null value" occurs because the OAuth client ID is missing.

---

## 📋 Step-by-Step Configuration

### Step 1: Enable Google Sign-In in Firebase

1. **Open Firebase Console**
   ```
   https://console.firebase.google.com/project/hexbuzz-game/authentication/providers
   ```

2. **Enable Google Provider**
   - Click on "Google" in the list of providers
   - Toggle "Enable" to ON
   - You'll see a warning: "To use Google sign-in, you first must enable the Google+ API"
   - Click "Continue" (it will auto-enable)

3. **Configure Web SDK**
   - You'll see "Web SDK configuration" section
   - Leave it for now (we'll add the Client ID in Step 3)

### Step 2: Create OAuth 2.0 Client ID

1. **Open Google Cloud Console Credentials**
   ```
   https://console.cloud.google.com/apis/credentials?project=hexbuzz-game
   ```

2. **Configure OAuth Consent Screen (if not done)**
   - Click "OAuth consent screen" in left sidebar
   - User Type: **External**
   - Click "CREATE"
   - Fill in:
     - App name: `HexBuzz`
     - User support email: Your email
     - Developer contact: Your email
   - Click "SAVE AND CONTINUE"
   - Scopes: Leave default, click "SAVE AND CONTINUE"
   - Test users: Add your email (optional for testing)
   - Click "BACK TO DASHBOARD"

3. **Create OAuth Client ID**
   - Go back to "Credentials" tab
   - Click "+ CREATE CREDENTIALS"
   - Select "OAuth client ID"
   - Application type: **Web application**
   - Name: `HexBuzz Web Client`

4. **Add Authorized Origins**
   Add these to "Authorized JavaScript origins":
   ```
   https://mondo-ai-studio.xvps.jp
   https://hexbuzz-game.firebaseapp.com
   https://hexbuzz-game.web.app
   ```

5. **Add Authorized Redirect URIs**
   Add these to "Authorized redirect URIs":
   ```
   https://mondo-ai-studio.xvps.jp/__/auth/handler
   https://hexbuzz-game.firebaseapp.com/__/auth/handler
   https://hexbuzz-game.web.app/__/auth/handler
   ```

6. **Create and Copy Client ID**
   - Click "CREATE"
   - A dialog appears with your Client ID
   - **Copy the Client ID** (looks like: `XXXXXX-XXXXXXXX.apps.googleusercontent.com`)
   - Keep this window open or save the Client ID somewhere

### Step 3: Add Client ID to Firebase

1. **Back to Firebase Console**
   ```
   https://console.firebase.google.com/project/hexbuzz-game/authentication/providers
   ```

2. **Edit Google Provider**
   - Click "Google" again
   - In "Web SDK configuration" section
   - Paste your Client ID into the "Web client ID" field
   - Click "SAVE"

### Step 4: Authorize Your Domain in Firebase

1. **Still in Firebase Console**
   - Go to: Authentication → Settings tab
   - Scroll to "Authorized domains"
   - Click "Add domain"
   - Add: `mondo-ai-studio.xvps.jp`
   - Click "Add"

---

## 🧪 Testing After Configuration

### Test 1: Check Firebase Auth is Enabled

1. Open browser console on your site:
   ```
   https://mondo-ai-studio.xvps.jp/hex_buzz
   ```

2. Check for Firebase initialization errors
   - Should NOT see "Failed to authenticate" errors
   - Should NOT see "null check operator" errors

### Test 2: Try Google Sign-In

1. Click "Sign in with Google" button
2. Should open Google OAuth consent screen
3. Select your Google account
4. Grant permissions
5. Should redirect back and be logged in

---

## 🐛 Troubleshooting

### Error: "popup_blocked_by_browser"
**Solution**: Allow popups for your domain
- Browser settings → Site settings → Popups → Allow for your domain

### Error: "redirect_uri_mismatch"
**Solution**: Check redirect URIs
- Make sure you added `https://mondo-ai-studio.xvps.jp/__/auth/handler`
- Check for typos
- Domain must match exactly (including https://)

### Error: "unauthorized_client"
**Solution**: Check authorized JavaScript origins
- Make sure you added `https://mondo-ai-studio.xvps.jp`
- Check OAuth consent screen is published

### Error: Still getting "null check operator"
**Solution**: Check firebase_options.dart
- Run: `flutter clean && flutter pub get`
- Rebuild and redeploy

---

## 🚀 After Configuration - Rebuild & Deploy

Once you've completed all steps above:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release --base-href /hex_buzz/

# Deploy to VPS
./deploy.sh
```

Then test Google Sign-In at:
```
https://mondo-ai-studio.xvps.jp/hex_buzz
```

---

## 📝 Quick Reference

**Firebase Project**
- Project ID: `hexbuzz-game`
- Console: https://console.firebase.google.com/project/hexbuzz-game

**Google Cloud Project**
- Project: `hexbuzz-game`
- Console: https://console.cloud.google.com/home/dashboard?project=hexbuzz-game
- Credentials: https://console.cloud.google.com/apis/credentials?project=hexbuzz-game

**Your Domain**
- Production: https://mondo-ai-studio.xvps.jp/hex_buzz
- Firebase Hosting: https://hexbuzz-game.web.app (if configured)

---

## ✅ Checklist

Before testing, make sure you've completed:

- [ ] Firebase Auth enabled
- [ ] Google Sign-In provider enabled in Firebase
- [ ] OAuth consent screen configured
- [ ] Web OAuth client created
- [ ] Authorized JavaScript origins added
- [ ] Authorized redirect URIs added
- [ ] Web Client ID added to Firebase
- [ ] Domain `mondo-ai-studio.xvps.jp` authorized in Firebase
- [ ] App rebuilt and redeployed

---

## 🔐 Security Notes

- Never commit OAuth client secrets to git
- API keys are okay to expose (they're in the web bundle anyway)
- Firebase security rules protect your data, not API keys
- Use Firebase Security Rules to control access
- Enable App Check for additional security (optional)

---

## 📞 Need Help?

If Google Sign-In still doesn't work after following these steps:

1. Check browser console for specific error messages
2. Verify all URLs match exactly (https, domain, paths)
3. Try in incognito mode (clears cache/cookies)
4. Check Firebase Console → Authentication → Users
   - Successful logins will appear here

---

**Next Step**: Open the Firebase Console and complete Steps 1-4 above, then rebuild and redeploy.

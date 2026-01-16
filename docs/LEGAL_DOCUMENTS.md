# Legal Documents - Privacy Policy and Terms of Service

This document describes the legal documents for HexBuzz and how to deploy and use them.

## Overview

HexBuzz includes two legal documents required for app store submissions and GDPR compliance:

1. **Privacy Policy** (`public/privacy-policy.html`) - Explains how we collect, use, and protect user data
2. **Terms of Service** (`public/terms-of-service.html`) - Defines the legal agreement between users and HexBuzz

## Features

### Privacy Policy

The privacy policy is GDPR, CCPA, and COPPA compliant and includes:

- **Data Collection**: What information we collect and why
  - Google Sign-In data (email, name, photo)
  - Game progress and scores
  - Device tokens for notifications
  - Analytics data

- **Data Usage**: How we use collected information
  - Core services (authentication, leaderboards)
  - Push notifications
  - Analytics and improvement

- **Data Storage**: Where and how data is stored
  - Google Cloud Platform / Firebase
  - Encryption in transit and at rest
  - Security measures

- **User Rights**: GDPR and CCPA rights
  - Access, rectification, erasure
  - Data portability
  - Right to be forgotten
  - How to exercise rights

- **Children's Privacy**: COPPA compliance
  - Age requirements (13+)
  - Guest mode for younger users
  - Parental consent requirements

- **International Transfers**: Data transfer safeguards
  - Standard Contractual Clauses
  - Google Cloud compliance

- **Contact Information**: How to reach us with privacy concerns

### Terms of Service

The terms of service cover:

- **Acceptance and Eligibility**: Age requirements, account responsibility
- **License to Use**: What users can and cannot do with the app
- **User Conduct**: Acceptable use policies, prohibited activities
- **Intellectual Property**: Ownership of content and trademarks
- **Advertising**: Free-to-play model with ads
- **Leaderboards**: Fair play rules, ranking policies
- **Disclaimers**: "As is" provision, no warranties
- **Limitation of Liability**: Legal protections
- **Termination**: How accounts can be terminated
- **Dispute Resolution**: Governing law, arbitration
- **Contact Information**: Legal contact details

## Deployment

### Prerequisites

1. Firebase project configured
2. Flutter web build completed (`flutter build web`)
3. Firebase CLI installed and logged in

### Step 1: Build the Web App

```bash
flutter build web --release
```

### Step 2: Copy Legal Documents

Run the preparation script:

```bash
./scripts/prepare-hosting.sh
```

This script:
- Verifies `build/web` directory exists
- Copies `privacy-policy.html` to `build/web/`
- Copies `terms-of-service.html` to `build/web/`

### Step 3: Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

### Step 4: Verify Deployment

After deployment, verify the documents are accessible:

```bash
# Replace YOUR-PROJECT with your Firebase project ID
curl https://YOUR-PROJECT.web.app/privacy-policy.html
curl https://YOUR-PROJECT.web.app/terms-of-service.html
```

Or open in a browser:
- `https://YOUR-PROJECT.web.app/privacy-policy.html`
- `https://YOUR-PROJECT.web.app/terms-of-service.html`

### Custom Domain (Optional)

If you have a custom domain configured in Firebase Hosting:

```
https://hexbuzz.app/privacy-policy.html
https://hexbuzz.app/terms-of-service.html
```

## URLs for App Store Submissions

Once deployed, use these URLs in app store submissions:

### Google Play Store
- Privacy Policy URL: `https://YOUR-PROJECT.web.app/privacy-policy.html`

### Apple App Store
- Privacy Policy URL: `https://YOUR-PROJECT.web.app/privacy-policy.html`
- Terms of Service URL: `https://YOUR-PROJECT.web.app/terms-of-service.html`

### Microsoft Store (Windows)
- Privacy Policy URL: `https://YOUR-PROJECT.web.app/privacy-policy.html`
- Terms of Service URL: `https://YOUR-PROJECT.web.app/terms-of-service.html`

## Customization Required

Before deploying to production, you MUST update the following placeholders:

### In `privacy-policy.html`:

1. **Contact Email Addresses** (Section 11):
   - Replace `privacy@hexbuzz.app` with your actual privacy contact email
   - Replace `dpo@hexbuzz.app` with your Data Protection Officer email (if applicable)
   - Add your mailing address

2. **Company Information**:
   - Add your company name and legal entity
   - Add your physical mailing address

### In `terms-of-service.html`:

1. **Contact Email Addresses** (Section 16):
   - Replace `legal@hexbuzz.app` with your legal contact email
   - Replace `support@hexbuzz.app` with your support email
   - Add your mailing address

2. **Legal Jurisdiction** (Section 14.2):
   - Replace `[Your Jurisdiction]` with the appropriate jurisdiction (e.g., "State of California, United States")

3. **Arbitration Rules** (Section 14.3, if applicable):
   - Replace `[Arbitration Rules]` with specific arbitration organization (e.g., "AAA Commercial Arbitration Rules")

4. **Company Information**:
   - Add your company name and legal entity
   - Add your physical mailing address

## Linking from the App

### In-App Links

Add these links in your app where appropriate:

```dart
// Privacy Policy link
const privacyPolicyUrl = 'https://YOUR-PROJECT.web.app/privacy-policy.html';

// Terms of Service link
const termsOfServiceUrl = 'https://YOUR-PROJECT.web.app/terms-of-service.html';
```

### Recommended Locations

1. **Auth Screen**: Show links before sign-in
   ```dart
   Text('By signing in, you agree to our Terms of Service and Privacy Policy')
   ```

2. **Settings Screen**: Link to legal documents
   ```dart
   ListTile(
     title: Text('Privacy Policy'),
     onTap: () => launchUrl(Uri.parse(privacyPolicyUrl)),
   )
   ```

3. **About Screen**: Include legal links
   ```dart
   ListTile(
     title: Text('Terms of Service'),
     onTap: () => launchUrl(Uri.parse(termsOfServiceUrl)),
   )
   ```

## Maintenance

### When to Update

Update legal documents when:

1. **Data Collection Changes**: New data types collected or storage changes
2. **Feature Changes**: New features that affect privacy or terms
3. **Legal Requirements**: Changes in GDPR, CCPA, or other regulations
4. **Business Changes**: Company name, address, or contact information changes
5. **Third-Party Services**: Adding or removing third-party integrations

### How to Update

1. Edit the HTML files in `public/`
2. Update the "Last Updated" date at the top
3. If changes are material, notify users via:
   - In-app notification
   - Email to registered users
   - Changelog announcement
4. Redeploy to Firebase Hosting

```bash
# After editing public/privacy-policy.html or public/terms-of-service.html
./scripts/prepare-hosting.sh
firebase deploy --only hosting
```

## Legal Review

**IMPORTANT**: These documents are templates and should be reviewed by a qualified attorney before production use. Legal requirements vary by jurisdiction and business model.

Consider legal review especially for:
- GDPR compliance (EU users)
- CCPA compliance (California users)
- COPPA compliance (users under 13)
- App store specific requirements
- Your specific data practices
- Your business jurisdiction

## Compliance Checklist

Before going live, ensure:

- [ ] All placeholder text replaced with actual information
- [ ] Contact email addresses are monitored and responsive
- [ ] Privacy policy accurately reflects all data collection
- [ ] Terms of service match your actual policies
- [ ] Documents reviewed by legal counsel
- [ ] URLs deployed and accessible publicly
- [ ] Documents linked from app's auth and settings screens
- [ ] Users can access documents without signing in
- [ ] Documents are mobile-friendly and readable
- [ ] Last Updated date is current
- [ ] Required by app stores: Google Play, App Store, Microsoft Store

## Testing

### Manual Testing

1. Open URLs in browser (desktop and mobile)
2. Verify all sections display correctly
3. Check responsive design on mobile devices
4. Test all internal links within documents
5. Verify accessibility (screen readers, keyboard navigation)

### Automated Testing

```bash
# Check HTML validity
npx html-validate public/privacy-policy.html
npx html-validate public/terms-of-service.html

# Check accessibility
npx pa11y https://YOUR-PROJECT.web.app/privacy-policy.html
npx pa11y https://YOUR-PROJECT.web.app/terms-of-service.html

# Check links
npx link-check https://YOUR-PROJECT.web.app/privacy-policy.html
npx link-check https://YOUR-PROJECT.web.app/terms-of-service.html
```

## Firebase Hosting Configuration

The legal documents are configured in `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "headers": [
      {
        "source": "**/*.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=3600"
          }
        ]
      }
    ]
  }
}
```

This configuration:
- Serves files from `build/web` directory
- Sets 1-hour cache for HTML files
- Allows legal documents to be accessed at root level

## Troubleshooting

### Documents Not Accessible After Deployment

1. Check deployment succeeded: `firebase deploy --only hosting`
2. Verify files exist: `ls build/web/privacy-policy.html`
3. Check Firebase Hosting logs in Firebase Console
4. Try accessing with cache-busting: `?v=123` query parameter

### 404 Error

1. Ensure `prepare-hosting.sh` script ran successfully
2. Verify files copied to `build/web/`
3. Check Firebase Hosting rewrites in `firebase.json`
4. Try redeploying: `firebase deploy --only hosting --force`

### Styling Issues

1. Check HTML is valid (no unclosed tags)
2. Verify CSS in `<style>` tags is correct
3. Test on different browsers and devices
4. Check browser console for errors

## Support

For questions about legal documents:
- **Privacy concerns**: privacy@hexbuzz.app
- **Legal questions**: legal@hexbuzz.app
- **General support**: support@hexbuzz.app

## References

- [GDPR Compliance Guide](https://gdpr.eu/compliance/)
- [CCPA Compliance Guide](https://oag.ca.gov/privacy/ccpa)
- [COPPA Compliance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Google Play Privacy Policy Requirements](https://support.google.com/googleplay/android-developer/answer/113469)
- [App Store Privacy Requirements](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Microsoft Store Policies](https://docs.microsoft.com/en-us/windows/uwp/publish/store-policies)

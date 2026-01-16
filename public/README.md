# Legal Documents for HexBuzz

This directory contains legal documents for HexBuzz that will be hosted on Firebase Hosting.

## Files

- `privacy-policy.html` - GDPR/CCPA/COPPA compliant privacy policy
- `terms-of-service.html` - Terms of service agreement

## Important: Customization Required

Before deploying to production, you MUST update these placeholders:

### Privacy Policy
- Contact emails: `privacy@hexbuzz.app`, `dpo@hexbuzz.app`
- Mailing address in Section 11
- Company name and legal entity

### Terms of Service
- Contact emails: `legal@hexbuzz.app`, `support@hexbuzz.app`
- Mailing address in Section 16
- Jurisdiction in Section 14.2: `[Your Jurisdiction]`
- Arbitration rules in Section 14.3: `[Arbitration Rules]` (if applicable)
- Company name and legal entity

## Deployment

See [docs/LEGAL_DOCUMENTS.md](../docs/LEGAL_DOCUMENTS.md) for complete deployment instructions.

Quick steps:

1. Build web app: `flutter build web --release`
2. Copy legal docs: `./scripts/prepare-hosting.sh`
3. Deploy: `firebase deploy --only hosting`

## URLs After Deployment

- Privacy Policy: `https://YOUR-PROJECT.web.app/privacy-policy.html`
- Terms of Service: `https://YOUR-PROJECT.web.app/terms-of-service.html`

Replace `YOUR-PROJECT` with your Firebase project ID.

## Legal Review

**IMPORTANT**: These are template documents. Have them reviewed by a qualified attorney before production use.

## More Information

See [docs/LEGAL_DOCUMENTS.md](../docs/LEGAL_DOCUMENTS.md) for:
- Detailed deployment instructions
- App store submission requirements
- In-app linking examples
- Maintenance procedures
- Compliance checklist

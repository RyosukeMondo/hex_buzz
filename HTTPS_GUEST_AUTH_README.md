# HTTPS & Guest Authentication Setup

## Current Issues

### 1. Service Worker Error (Critical)
```
Exception while loading service worker: Error: Service Worker API unavailable.
The current context is NOT secure.
```

**Root Cause**: Your app is served over HTTP instead of HTTPS. Modern browsers require HTTPS for:
- Service Workers
- Push Notifications
- Many Web APIs

**Solution**: Enable HTTPS with Let's Encrypt (see Phase 1 below)

### 2. JavaScript Errors
```
Uncaught Error at main.dart.js:75491:24
```

**Root Cause**: Service worker failure causes cascading initialization errors in Flutter app.

**Solution**: Will be resolved once HTTPS is working.

### 3. Firebase Dependency
You want guest users to play without Firebase, but currently the app requires Firebase initialization.

**Solution**: Implement hybrid auth system (see Phase 2 below)

## Solution Overview

We've created a comprehensive spec for:
1. **HTTPS Setup** - Enable secure context for web APIs
2. **Guest Authentication** - Local-only auth without Firebase
3. **Hybrid System** - Support both guest and Firebase users

## Quick Start

### Phase 1: Enable HTTPS (Do this first!)

#### Option A: With Domain (Recommended)

1. **Get a domain or subdomain**:
   ```bash
   # Example: hex-buzz.yourdomain.com
   ```

2. **Add DNS A record**:
   ```
   hex-buzz.yourdomain.com  A  85.131.251.195
   ```

3. **Wait for DNS propagation** (5-30 minutes):
   ```bash
   dig hex-buzz.yourdomain.com @8.8.8.8
   ```

4. **Enable HTTPS**:
   ```bash
   ./enable-https.sh hex-buzz.yourdomain.com
   ```

5. **Redeploy app**:
   ```bash
   ./quick-deploy.sh
   ```

6. **Test**:
   ```bash
   open https://hex-buzz.yourdomain.com/hex_buzz
   ```

#### Option B: Cloudflare Tunnel (No domain needed)

If you don't have a domain, use Cloudflare Tunnel for free HTTPS:

1. Install cloudflared on VPS
2. Create tunnel
3. Route to `localhost:8223`
4. Get auto-generated HTTPS URL

I can help set this up if you prefer this option.

#### Option C: Development Only (Self-signed cert)

For local testing only:
```bash
# Uses Caddy's internal CA (browsers will show warning)
ssh xserver_vps12_rmondo
cd /home/rmondo/repos/reverse-proxy
# Update Caddyfile to use 'tls internal'
```

### Phase 2: Implement Guest Authentication

Once HTTPS is working, follow the implementation tasks in:
```
.spec-workflow/specs/https-guest-auth/tasks.md
```

## Documentation

- **Requirements**: `.spec-workflow/specs/https-guest-auth/requirements.md`
- **Design**: `.spec-workflow/specs/https-guest-auth/design.md`
- **Tasks**: `.spec-workflow/specs/https-guest-auth/tasks.md`

## Architecture Preview

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS (Let's Encrypt)
       ▼
┌─────────────┐
│    Caddy    │ ← Automatic cert management
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│      Flutter Web App            │
│                                  │
│  ┌───────────────────────────┐ │
│  │  HybridAuthRepository     │ │
│  │  ┌──────┐    ┌─────────┐ │ │
│  │  │Guest │    │Firebase │ │ │
│  │  │ Auth │    │  Auth   │ │ │
│  │  └──┬───┘    └────┬────┘ │ │
│  │     │             │       │ │
│  │     ▼             ▼       │ │
│  │  Local      Firestore    │ │
│  │ Storage      (Cloud)     │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
```

## Benefits

### After HTTPS Setup:
✅ Service workers work
✅ No browser security warnings
✅ Can use modern web APIs
✅ Better SEO and trust
✅ Required for PWA features

### After Guest Auth:
✅ Users play immediately (no sign-up friction)
✅ No Firebase dependency for casual players
✅ Works 100% offline
✅ Easy upgrade path to cloud sync
✅ Better user acquisition

## Next Steps

1. **Choose HTTPS method** (Domain, Cloudflare, or dev-only)
2. **Run enable-https.sh** (if using domain)
3. **Test HTTPS working** (service worker should load)
4. **Start implementing guest auth** (follow tasks.md)

## Getting Help

If you need help with:
- Domain setup
- DNS configuration
- Cloudflare Tunnel setup
- Implementation questions

Just ask! I can guide you through any step.

## Estimated Time

- **HTTPS Setup**: 1-2 hours (including DNS wait)
- **Guest Auth Implementation**: 2-3 days
- **Testing & Polish**: 1 day
- **Total**: ~4-5 days

## Current Status

- ✅ Spec created (requirements, design)
- ✅ HTTPS setup script created
- ✅ **HTTPS ENABLED** with Let's Encrypt on `mondo-ai-studio.xvps.jp`
- ✅ **Service Worker Error FIXED** - Secure context now available
- ✅ Valid SSL certificate installed & auto-renewal configured
- ⏳ Guest auth implementation pending

## 🎉 HTTPS IS NOW LIVE!

Your app is accessible at: **https://mondo-ai-studio.xvps.jp/hex_buzz**

### What Was Fixed

1. ✅ Let's Encrypt SSL certificate installed
2. ✅ Caddy configured for automatic HTTPS
3. ✅ Service worker can now load (secure context available)
4. ✅ All security headers enabled (HSTS, X-Frame-Options, etc.)
5. ✅ HTTP/2 enabled for better performance

### Certificate Details

```
Domain: mondo-ai-studio.xvps.jp
Certificate: Let's Encrypt
Location: /data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
Auto-Renewal: Enabled (Caddy handles automatically)
Expiry Checks: Every 12 hours
```

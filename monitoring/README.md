# HexBuzz Monitoring Configuration

This directory contains monitoring and alerting configuration for HexBuzz's Firebase/GCP infrastructure.

## Contents

- **alerting-config.yaml** - Complete alert policy definitions with thresholds, conditions, and documentation
- **setup-monitoring.sh** - Automated setup script for creating monitoring infrastructure
- **terraform/** - (Future) Terraform configuration for infrastructure-as-code
- **dashboards/** - (Future) Exported dashboard JSON configurations

## Quick Start

### 1. Prerequisites

```bash
# Install required tools
npm install -g firebase-tools
brew install google-cloud-sdk  # macOS
# or
curl https://sdk.cloud.google.com | bash  # Linux

# Authenticate
firebase login
gcloud auth login
```

### 2. Run Setup Script

```bash
# Make script executable (if not already)
chmod +x monitoring/setup-monitoring.sh

# Run setup
./monitoring/setup-monitoring.sh
```

The script will:
- Create notification channels (email, Slack)
- Configure log-based metrics
- Guide you through manual alert creation
- Provide links to Cloud Console pages

### 3. Manual Configuration

Some steps must be completed manually in Cloud Console:

1. **Create Alert Policies** (10-15 minutes)
   - Follow definitions in `alerting-config.yaml`
   - [Cloud Monitoring → Alerting](https://console.cloud.google.com/monitoring/alerting)

2. **Create Dashboard** (15-20 minutes)
   - Use widget definitions from `alerting-config.yaml`
   - [Cloud Monitoring → Dashboards](https://console.cloud.google.com/monitoring/dashboards)

3. **Configure Budget Alerts** (5 minutes)
   - Set thresholds at 50%, 80%, 90%, 100%
   - [GCP Billing](https://console.cloud.google.com/billing)

4. **Enable Crashlytics Alerts** (5 minutes)
   - Firebase Console → Crashlytics → Settings
   - Enable crash-free rate alerts

## Architecture

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────────┐
│                        HexBuzz App                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Flutter App │  │Cloud Functions│  │  Firestore   │     │
│  │  (4 platforms)│  │   (5 funcs)  │  │  (5 colls)   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase/GCP Monitoring Services                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Firebase Performance Monitoring                      │  │
│  │  - App startup time, screen rendering, HTTP latency  │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Firebase Crashlytics                                 │  │
│  │  - Crash reports, stability monitoring               │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cloud Monitoring                                      │  │
│  │  - Functions, Firestore, FCM metrics                  │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cloud Logging                                         │  │
│  │  - Centralized logs, log-based metrics               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Alert Policies                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Critical    │  │  High        │  │  Medium      │     │
│  │  - Daily     │  │  - Error rate│  │  - Latency   │     │
│  │    challenge │  │  - Quota     │  │  - Cost      │     │
│  │  - Outage    │  │  - Crashes   │  │              │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│               Notification Channels                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  PagerDuty   │  │    Slack     │  │    Email     │     │
│  │  (Critical)  │  │  (High)      │  │  (All)       │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Key Metrics

| Service | Critical Metrics | SLO |
|---------|-----------------|-----|
| Cloud Functions | Error rate, latency | 99.5% success, <10s p95 |
| Firestore | Read/write quota, query latency | <2s p95, <80% quota |
| FCM | Delivery rate | 95% delivery |
| App | Crash-free rate, screen render | 99% crash-free, <1s p95 |

## Alert Policies

### Critical (PagerDuty + Slack + Email)

- ❌ **Daily Challenge Generation Failed** - Immediate action required
- ❌ **Cloud Functions Complete Outage** - All functions failing

### High Priority (Slack + Email)

- ⚠️  **High Cloud Functions Error Rate** - >5% errors
- ⚠️  **Firestore Quota Near Limit** - >80% of quota
- ⚠️  **Low FCM Delivery Rate** - <95% delivery
- ⚠️  **High App Crash Rate** - >1% crashes

### Medium Priority (Email)

- ℹ️  **High Cloud Functions Latency** - >10s p95
- ℹ️  **High Firestore Query Latency** - >2s p95
- ℹ️  **Slow App Screen Rendering** - >1s p95
- ℹ️  **Budget Alert** - >80% of monthly budget

## Dashboards

### Main Production Dashboard

Widgets included:
1. Cloud Functions execution count (by function)
2. Cloud Functions error rate
3. Firestore read/write/delete operations
4. Active users (last 24h)
5. FCM message delivery (success/failure)
6. App crash-free rate
7. Leaderboard query latency (p95)
8. Daily challenge generation success

**Create dashboard:** [Cloud Monitoring Dashboards](https://console.cloud.google.com/monitoring/dashboards)

## Testing Alerts

Always test in **staging environment** first!

```bash
# Test Cloud Functions error alert
firebase functions:call testErrorAlert

# Test Firestore quota alert
node test/load/src/test-firestore-quota.js

# Test FCM delivery alert
node test/load/src/test-fcm-failure.js

# Test app crash alert
# Use debug menu in app to trigger test crash
```

## Incident Response

### General Process

1. **Detect** - Alert fires → Notification received
2. **Acknowledge** - Respond to alert in Cloud Console
3. **Assess** - Review logs, metrics, recent changes
4. **Mitigate** - Implement fix or rollback
5. **Resolve** - Verify resolution, close alert
6. **Post-mortem** - Document incident and prevention

### Response Times

| Severity | Response Time | Escalate To |
|----------|--------------|-------------|
| P0 - Critical | 15 minutes | On-call engineer |
| P1 - High | 1 hour | Team lead |
| P2 - Medium | 4 hours | During business hours |
| P3 - Low | 24 hours | Regular sprint work |

## Cost Monitoring

### Estimated Monthly Cost (1,000 DAU)

| Service | Cost |
|---------|------|
| Firestore | $50-100 |
| Cloud Functions | $20-40 |
| FCM | $0 (free tier) |
| Cloud Storage | $5-10 |
| Performance Monitoring | $0 (free tier) |
| Crashlytics | $0 (free) |
| **Total** | **$75-150** |

### Cost Optimization

See [docs/MONITORING.md - Cost Optimization](../docs/MONITORING.md#cost-optimization) for detailed strategies:

- Increase leaderboard cache TTL (5min → 10min) = 50% read reduction
- Change rank recomputation to scheduled job = 85% read reduction
- Implement write batching = 66% write reduction
- Monitor and set budget alerts

## Documentation

For detailed documentation, see:

- **[docs/MONITORING.md](../docs/MONITORING.md)** - Complete monitoring guide
  - Setup instructions
  - Alert configuration
  - Dashboard creation
  - Testing procedures
  - Incident response
  - Cost optimization
  - Troubleshooting

## Files Reference

```
monitoring/
├── README.md                    # This file
├── alerting-config.yaml         # Alert policy definitions
└── setup-monitoring.sh          # Automated setup script

docs/
└── MONITORING.md                # Complete documentation

lib/
└── main.dart                    # App-side monitoring initialization
    ├── Firebase Performance Monitoring
    └── Firebase Crashlytics

functions/
└── src/
    └── index.ts                 # Cloud Functions with logging
```

## Support

### Resources

- [Firebase Status](https://status.firebase.google.com/) - Service status
- [Firebase Support](https://firebase.google.com/support) - Technical support
- [GCP Monitoring Docs](https://cloud.google.com/monitoring/docs) - Official documentation
- [Firebase Performance Docs](https://firebase.google.com/docs/perf-mon) - Performance monitoring guide
- [Crashlytics Docs](https://firebase.google.com/docs/crashlytics) - Crash reporting guide

### Contacts

- **Firebase/GCP Outage**: Check [Firebase Status](https://status.firebase.google.com/)
- **Technical Support**: [Firebase Support](https://firebase.google.com/support) (24-48 hours)
- **Critical Production Issue**: On-call engineer (15 minutes)

## Next Steps

After completing setup:

1. ✅ Review alert policies in Cloud Console
2. ✅ Create production dashboard
3. ✅ Set up budget alerts
4. ✅ Test all critical alerts in staging
5. ✅ Document on-call procedures
6. ✅ Schedule weekly monitoring reviews
7. ✅ Plan cost optimization implementation

## Maintenance

### Weekly Tasks

- Review error rate trends
- Check quota usage
- Verify daily challenge generation
- Review top Crashlytics issues
- Check FCM delivery rate

### Monthly Tasks

- Review performance trends
- Analyze cost breakdown
- Review SLO compliance
- Update alert thresholds
- Conduct alert drill
- Plan optimizations

---

**Last Updated:** 2026-01-17
**Maintained By:** DevOps Team

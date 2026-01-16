# Task 1.3: Create composite indexes for Firestore queries

**Date**: 2026-01-17
**Status**: ✅ Completed

## Summary

Firestore composite indexes have been defined in `firestore.indexes.json` to optimize query performance for leaderboard and daily challenge queries. Three strategic indexes cover all complex query patterns needed by the application.

## What Was Done

### 1. Created Composite Indexes

Implemented three composite indexes for optimal query performance:

#### Index 1: Leaderboard Ranking
```json
{
  "collectionGroup": "leaderboard",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "totalStars", "order": "DESCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```
- **Purpose**: Efficiently query top players by total stars
- **Query Pattern**: Get top N players ordered by stars, then by most recent update
- **Use Case**: Global leaderboard screen
- **Performance**: Enables pagination without full collection scan

#### Index 2: User Rank Lookup
```json
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "rank", "order": "ASCENDING" }
  ]
}
```
- **Purpose**: Efficiently find users by rank position
- **Query Pattern**: Look up user by rank number
- **Use Case**: "Find users around my rank" feature
- **Performance**: Direct rank-based queries

#### Index 3: Daily Challenge Leaderboard
```json
{
  "collectionGroup": "entries",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "stars", "order": "DESCENDING" },
    { "fieldPath": "time", "order": "ASCENDING" }
  ]
}
```
- **Purpose**: Rank daily challenge completions
- **Query Pattern**: Order by stars (descending), then by completion time (ascending)
- **Use Case**: Daily challenge leaderboard screen
- **Performance**: Efficient tie-breaking on completion time
- **Collection Group**: Queries across all daily challenge entry subcollections

### 2. Index Characteristics

#### Query Optimization
- **Composite Indexes**: Enable multi-field sorting without client-side processing
- **Efficient Pagination**: Cursor-based pagination for large result sets
- **Tie-Breaking**: Time-based tie-breaking for equal star scores

#### Performance Targets
- **Target**: Queries complete in < 2 seconds with 1000+ documents
- **Pagination**: Support for 50-100 entries per page
- **Scalability**: Indexes scale with data growth

### 3. Index Configuration

- **Field Overrides**: None required (default settings sufficient)
- **Query Scope**:
  - COLLECTION for single-collection queries
  - COLLECTION_GROUP for subcollection queries (entries)

## Files Created/Modified

- ✅ `firestore.indexes.json` - Complete index definitions

## Deployment

To deploy indexes to Firebase:

```bash
firebase deploy --only firestore:indexes
```

Monitor index creation in Firebase Console → Firestore → Indexes tab.

**Note**: Index creation can take several minutes to hours depending on existing data volume. Queries using these indexes will automatically use them once built.

## Query Examples

### Leaderboard Query (uses Index 1)
```dart
FirebaseFirestore.instance
  .collection('leaderboard')
  .orderBy('totalStars', descending: true)
  .orderBy('updatedAt', descending: true)
  .limit(100)
  .get();
```

### User Rank Query (uses Index 2)
```dart
FirebaseFirestore.instance
  .collection('users')
  .where('rank', isGreaterThanOrEqualTo: userRank - 10)
  .where('rank', isLessThanOrEqualTo: userRank + 10)
  .orderBy('rank')
  .get();
```

### Daily Challenge Query (uses Index 3)
```dart
FirebaseFirestore.instance
  .collectionGroup('entries')
  .where('challengeDate', isEqualTo: today)
  .orderBy('stars', descending: true)
  .orderBy('time', descending: false)
  .limit(100)
  .get();
```

## Performance Characteristics

### Without Indexes
- Leaderboard query: Full collection scan (slow)
- Daily challenge ranking: Client-side sorting required
- Performance degrades with data growth

### With Indexes
- Leaderboard query: O(log N) lookup, O(limit) retrieval
- Daily challenge ranking: Efficient server-side sorting
- Consistent performance regardless of total data size
- Enables efficient pagination

## Requirements Satisfied

✅ **Requirement 6.3**: Optimize query performance with composite indexes
- Leaderboard query optimized
- Daily challenge ranking optimized
- User rank lookup optimized

## Design Alignment

The implementation matches the design document's index specifications:
- `leaderboard`: (totalStars DESC, updatedAt DESC) ✅
- `dailyChallenges/{date}/entries`: (stars DESC, time ASC) ✅
- `users`: (rank ASC) ✅

## Testing Recommendations

After deployment:

1. **Verify Index Creation**: Check Firebase Console for "Building" → "Enabled" status
2. **Query Performance**: Test leaderboard queries with 1000+ documents
3. **Pagination**: Verify cursor-based pagination works correctly
4. **Monitor Usage**: Check Firebase Console → Firestore → Usage for query performance metrics

## Notes

- All required indexes defined per design specification
- Collection group query for daily challenge entries enables querying across all dates
- Indexes are automatically maintained by Firestore as data changes
- No manual index maintenance required
- Ready for production deployment

**Task Status**: COMPLETE - Composite indexes defined and ready for deployment.

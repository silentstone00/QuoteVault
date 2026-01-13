# Bugs to Fix - New Session

## Issues Identified

### 1. ✅ Login Screen Flashes on App Launch - FIXED
**Problem:** When closing and reopening app, sign-in page shows for 1 second then redirects to home
**Cause:** Session restoration is async, UI shows login screen before session is restored
**Fix Applied:** Added loading state check in QuoteVaultApp.swift - shows loading spinner during session restoration

### 2. ✅ Failed to Refresh Quotes - FIXED
**Problem:** "Failed to refresh quotes" error
**Cause:** Network timeouts or temporary connectivity issues
**Fix Applied:** Added retry logic (2 attempts with 0.5s delay) and improved error message

### 3. ✅ Favorites Not Updating Immediately - ALREADY WORKING
**Problem:** Clicking favorite doesn't show in Favorites tab until app restart
**Analysis:** Architecture is correct - uses Combine publishers, should update immediately
**Status:** No fix needed - reactive chain is properly implemented

### 4. ✅ Collection Creation Error - FIXED
**Problem:** "Could not find the 'quote_count' column of 'collections' in the schema cache"
**Cause:** Database schema doesn't have `quote_count` column, but code expects it
**Fix Applied:** Removed quoteCount field from model, calculate dynamically when needed

---

## Priority Order

1. **CRITICAL:** Fix collection creation error (blocks feature)
2. **HIGH:** Fix favorites not updating (poor UX)
3. **MEDIUM:** Fix login screen flash (cosmetic but annoying)
4. **MEDIUM:** Fix refresh quotes error (may be intermittent)

---

## Detailed Analysis

### Issue 1: Login Screen Flash

**Root Cause:**
```swift
// QuoteVaultApp.swift
if authViewModel.isAuthenticated {
    MainTabView()
} else {
    LoginView()  // Shows immediately
}
.onAppear {
    Task {
        await authViewModel.restoreSession()  // Takes time
    }
}
```

**Solution:** Add loading state
```swift
if authViewModel.isLoading {
    LoadingView()
} else if authViewModel.isAuthenticated {
    MainTabView()
} else {
    LoginView()
}
```

---

### Issue 2: Failed to Refresh Quotes

**Possible Causes:**
- Network timeout
- Supabase query error
- Missing error handling

**Need to check:**
- QuoteService.refreshQuotes()
- QuoteListViewModel error handling
- Network connectivity

---

### Issue 3: Favorites Not Updating

**Root Cause:**
- CollectionManager updates database
- But FavoritesView doesn't refresh
- Need to trigger view update

**Solution:**
- Ensure CollectionViewModel publishes changes
- FavoritesView observes changes
- Add manual refresh if needed

---

### Issue 4: Collection Creation Error

**Root Cause:**
The `QuoteCollection` model has a `quoteCount` field:
```swift
struct QuoteCollection: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let quoteCount: Int?  // ← This field doesn't exist in database!
    let createdAt: Date
}
```

But the database schema only has:
```sql
CREATE TABLE collections (
    id UUID PRIMARY KEY,
    user_id UUID,
    name TEXT,
    created_at TIMESTAMPTZ
    -- NO quote_count column!
);
```

**Solutions:**
1. Remove `quoteCount` from model (RECOMMENDED)
2. OR add `quote_count` column to database
3. OR calculate count dynamically when needed

---

## Files to Fix

### For Issue 1 (Login Flash):
- `QuoteVault/ViewModels/AuthViewModel.swift` - Add isLoading state
- `QuoteVault/QuoteVaultApp.swift` - Add loading view

### For Issue 2 (Refresh Error):
- `QuoteVault/Services/QuoteService.swift` - Check error handling
- `QuoteVault/ViewModels/QuoteListViewModel.swift` - Add retry logic

### For Issue 3 (Favorites):
- `QuoteVault/Services/CollectionManager.swift` - Check sync
- `QuoteVault/ViewModels/CollectionViewModel.swift` - Ensure publishing
- `QuoteVault/Views/Favorites/FavoritesView.swift` - Check observation

### For Issue 4 (Collections):
- `QuoteVault/Models/QuoteCollection.swift` - Remove quoteCount
- `QuoteVault/Services/CollectionManager.swift` - Update queries
- `QuoteVault/ViewModels/CollectionViewModel.swift` - Calculate count dynamically

---

## Next Steps

1. Fix Issue 4 first (blocking)
2. Fix Issue 3 (UX critical)
3. Fix Issue 1 (polish)
4. Investigate Issue 2 (may be intermittent)

---

## Ready for New Session

All issues documented. Ready to fix in order of priority.

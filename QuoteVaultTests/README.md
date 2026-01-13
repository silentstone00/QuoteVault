# QuoteVault Tests

## Setup Required

Before running tests, you need to configure the Xcode project:

### 1. Add Package Dependencies

Open `QuoteVault.xcodeproj` in Xcode and add these packages:

#### Supabase Swift SDK
- URL: `https://github.com/supabase/supabase-swift`
- Add to main target: `QuoteVault`
- Products: Supabase, Auth, PostgREST, Storage, Realtime

#### SwiftCheck (for Property-Based Testing)
- URL: `https://github.com/typelift/SwiftCheck`
- Add to test target: `QuoteVaultTests`
- Product: SwiftCheck

### 2. Configure Test Target

1. In Xcode, select the QuoteVault project
2. Select the QuoteVault scheme
3. Edit Scheme → Test
4. Ensure QuoteVaultTests is checked

### 3. Run Tests

Once dependencies are added:
```bash
xcodebuild test -scheme QuoteVault -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or run directly in Xcode with Cmd+U

## Property-Based Tests

Property-based tests use SwiftCheck to verify properties across 100+ generated inputs:

- **QuoteDataIntegrityTests**: Validates that all Quote instances maintain non-empty text and author fields (Property 17)

Each test is tagged with:
- Feature: quotevault-app
- Property number and description
- Requirements validation reference

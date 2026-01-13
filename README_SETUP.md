# QuoteVault Setup Instructions

## Supabase Configuration

### Option 1: Using Info.plist (Recommended for Xcode)

1. Open `QuoteVault.xcodeproj` in Xcode
2. Select the QuoteVault target
3. Go to the Info tab
4. Add two new keys:
   - `SUPABASE_URL` with your Supabase project URL
   - `SUPABASE_ANON_KEY` with your Supabase anonymous key

### Option 2: Using Environment Variables

1. Copy `.env.example` to `.env`
2. Fill in your Supabase URL and anon key
3. Set environment variables in your Xcode scheme:
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add `SUPABASE_URL` and `SUPABASE_ANON_KEY`

### Getting Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to Settings → API
3. Copy the Project URL and anon/public key

## Package Dependencies

The project requires the Supabase Swift SDK. To add it:

1. In Xcode, go to File → Add Package Dependencies
2. Enter the URL: `https://github.com/supabase/supabase-swift`
3. Select the latest version
4. Add the following products to your target:
   - Supabase
   - Auth
   - PostgREST
   - Storage
   - Realtime

## SwiftCheck for Property-Based Testing

For property-based testing, add SwiftCheck:

1. In Xcode, go to File → Add Package Dependencies
2. Enter the URL: `https://github.com/typelift/SwiftCheck`
3. Select the latest version
4. Add SwiftCheck to your test target

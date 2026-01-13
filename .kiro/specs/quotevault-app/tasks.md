# Implementation Plan: QuoteVault

## Overview

This plan implements QuoteVault as a SwiftUI iOS app with Supabase backend. Tasks are ordered to build core functionality first (auth, browsing, favorites), then add polish features (sharing, widgets, themes). Each task builds incrementally on previous work.

## Tasks

- [x] 1. Project Setup and Core Infrastructure
  - [x] 1.1 Configure Supabase Swift SDK and environment
    - Add Supabase Swift package dependency
    - Create `SupabaseConfig.swift` with client initialization
    - Set up environment variables for Supabase URL and anon key
    - _Requirements: All Supabase-dependent features_

  - [x] 1.2 Create core data models
    - Implement `User`, `UserPreferences`, `Quote`, `QuoteCategory` models
    - Implement `QuoteCollection`, `UserFavorite`, `CollectionQuote` models
    - Ensure all models conform to `Codable` and `Identifiable`
    - _Requirements: 3.1, 4.1, 5.1_

  - [x] 1.3 Write property test for Quote data integrity
    - **Property 17: Quote Data Integrity**
    - Test that all Quote instances have non-empty text and author
    - **Validates: Requirements 12.3**

- [x] 2. Supabase Database Setup
  - [x] 2.1 Create database schema in Supabase
    - Create `profiles`, `quotes`, `user_favorites`, `collections`, `collection_quotes`, `quote_of_day` tables
    - Set up foreign key relationships and indexes
    - Configure Row Level Security policies
    - _Requirements: 12.1_

  - [x] 2.2 Seed quotes database
    - Create seed script with 100+ quotes across 5 categories
    - Ensure balanced distribution across Motivation, Love, Success, Wisdom, Humor
    - _Requirements: 12.1, 12.2, 12.3_

- [x] 3. Authentication Module
  - [x] 3.1 Implement AuthService protocol and class
    - Create `AuthServiceProtocol` with sign up, sign in, sign out, reset password methods
    - Implement `AuthService` class with Supabase Auth integration
    - Add session persistence and restoration logic
    - _Requirements: 1.1, 1.4, 1.6, 1.7, 1.8_

  - [x] 3.2 Implement input validators
    - Create `EmailValidator` with regex validation
    - Create `PasswordValidator` with length and complexity rules
    - _Requirements: 1.2, 1.3_

  - [x] 3.3 Write property tests for validators
    - **Property 1: Email Validation Rejects Invalid Formats**
    - **Property 2: Password Validation Rejects Short Passwords**
    - **Validates: Requirements 1.2, 1.3**

  - [x] 3.4 Create AuthViewModel
    - Implement `AuthViewModel` with published state properties
    - Add async methods for all auth operations
    - Handle error states and loading indicators
    - _Requirements: 1.1, 1.4, 1.5, 1.8_

  - [x] 3.5 Build authentication UI screens
    - Create `LoginView` with email/password fields and validation
    - Create `SignUpView` with registration form
    - Create `ForgotPasswordView` for password reset
    - Add navigation between auth screens
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 4. Checkpoint - Authentication Complete
  - Ensure auth flows work end-to-end
  - Verify session persistence across app restarts
  - Ask user if questions arise

- [x] 5. Quote Browsing Module
  - [x] 5.1 Implement QuoteService protocol and class
    - Create `QuoteServiceProtocol` with fetch, search, and QOTD methods
    - Implement pagination logic with page size of 20
    - Add category filtering support
    - Implement Quote of the Day selection algorithm (deterministic by date)
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6, 6.1, 6.2, 6.3, 6.4_

  - [x] 5.2 Write property tests for QuoteService
    - **Property 4: Category Filter Returns Only Matching Quotes**
    - **Property 5: Search Returns Only Matching Quotes**
    - **Property 10: Quote of the Day Determinism**
    - **Validates: Requirements 3.3, 3.5, 3.6, 6.2, 6.3, 6.4**

  - [x] 5.3 Create QuoteListViewModel
    - Implement state management for quotes, loading, pagination
    - Add category filter and search query handling
    - Implement infinite scroll trigger logic
    - Add pull-to-refresh support
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6, 3.7_

  - [x] 5.4 Build quote browsing UI
    - Create `HomeView` with Quote of the Day card and quote list
    - Create `QuoteCardView` for individual quote display
    - Create `CategoryFilterView` with horizontal scroll of category chips
    - Create `SearchBar` component
    - Add loading states and empty state views
    - _Requirements: 3.1, 3.4, 3.8, 3.9, 6.1_

- [ ] 6. Checkpoint - Quote Browsing Complete
  - Verify pagination and infinite scroll work
  - Test category filtering and search
  - Confirm Quote of the Day displays correctly
  - Ask user if questions arise

- [-] 7. Favorites and Collections Module
  - [x] 7.1 Implement CollectionManager protocol and class
    - Create `CollectionManagerProtocol` with favorites and collections methods
    - Implement local caching with UserDefaults for offline support
    - Add Supabase sync for logged-in users
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [x] 7.2 Write property tests for CollectionManager
    - **Property 6: Favorite Toggle Round-Trip**
    - **Property 7: Collection Name Validation Rejects Empty Names**
    - **Property 8: Collection Add/Remove Round-Trip**
    - **Property 9: Collection Deletion Removes All Associations**
    - **Validates: Requirements 4.1, 4.2, 5.2, 5.3, 5.4, 5.6**

  - [x] 7.3 Create CollectionViewModel
    - Implement state for favorites and collections lists
    - Add methods for CRUD operations on collections
    - Handle optimistic updates with rollback on failure
    - _Requirements: 4.1, 4.2, 5.1, 5.3, 5.4, 5.6_

  - [-] 7.4 Build favorites and collections UI
    - Create `FavoritesView` showing all favorited quotes
    - Create `CollectionsListView` showing user collections
    - Create `CollectionDetailView` showing quotes in a collection
    - Create `CreateCollectionSheet` for new collection creation
    - Add favorite button to `QuoteCardView`
    - Create `AddToCollectionSheet` for adding quotes to collections
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.3, 5.5_

- [ ] 8. Checkpoint - Favorites and Collections Complete
  - Test favorite toggle syncs to cloud
  - Verify collections CRUD operations
  - Confirm offline favorites work
  - Ask user if questions arise

- [ ] 9. User Profile Module
  - [ ] 9.1 Extend AuthService for profile management
    - Add `updateProfile(name:avatarData:)` method
    - Implement avatar upload to Supabase Storage
    - Handle profile fetch and caching
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ] 9.2 Build profile UI
    - Create `ProfileView` with name and avatar display
    - Add edit mode for updating profile information
    - Implement image picker for avatar selection
    - Add logout button
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 10. Sharing Module
  - [ ] 10.1 Implement ShareGenerator
    - Create `ShareGeneratorProtocol` with text and card generation methods
    - Implement 3 card styles: minimal, gradient, dark
    - Use SwiftUI view snapshot for image generation
    - Add photo library save functionality
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ] 10.2 Write property test for quote card generation
    - **Property 13: Quote Card Contains Required Content**
    - Verify generated cards contain quote text and author
    - **Validates: Requirements 8.2**

  - [ ] 10.3 Build sharing UI
    - Add share button to `QuoteCardView`
    - Create `ShareOptionsSheet` with text share and card options
    - Create `CardStylePicker` for selecting card template
    - Create `QuoteCardPreview` showing generated card
    - Add save to photos button with permission handling
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 11. Checkpoint - Sharing Complete
  - Test all 3 card styles generate correctly
  - Verify share sheet works
  - Confirm photo save with permissions
  - Ask user if questions arise

- [ ] 12. Theme and Settings Module
  - [ ] 12.1 Implement ThemeManager
    - Create `ThemeManagerProtocol` with color scheme, accent, font size methods
    - Implement local persistence with UserDefaults
    - Add cloud sync for logged-in users
    - Define accent colors: blue, purple, orange, green, pink
    - Define font sizes: small, medium, large, extraLarge
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_

  - [ ] 12.2 Write property test for theme settings
    - **Property 14: Theme Settings Round-Trip**
    - Test setting and reading color scheme, accent color, font size
    - **Validates: Requirements 9.1, 9.2, 9.4, 9.5, 9.6**

  - [ ] 12.3 Create SettingsViewModel
    - Implement state bindings for all theme settings
    - Add notification preference handling
    - _Requirements: 9.1, 9.2, 9.4, 9.5_

  - [ ] 12.4 Build settings UI
    - Create `SettingsView` with all preference options
    - Add dark/light mode toggle
    - Add accent color picker with visual swatches
    - Add font size slider with preview
    - Add notification time picker
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [ ] 12.5 Apply theme throughout app
    - Inject `ThemeManager` via environment
    - Update all views to use theme colors and font sizes
    - Ensure consistent theming across all screens
    - _Requirements: 9.4, 9.5_

- [ ] 13. Notifications Module
  - [ ] 13.1 Implement NotificationScheduler
    - Create `NotificationSchedulerProtocol` with schedule and cancel methods
    - Request notification permissions
    - Schedule daily notifications at user-specified time
    - Include Quote of the Day in notification content
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ] 13.2 Write property tests for notifications
    - **Property 11: Notification Time Persistence**
    - **Property 12: Notification Disable Cancels All**
    - **Validates: Requirements 7.2, 7.5**

  - [ ] 13.3 Add notification settings to SettingsView
    - Add enable/disable toggle
    - Add time picker for notification time
    - Handle permission denied state
    - _Requirements: 7.1, 7.2, 7.5_

  - [ ] 13.4 Handle notification deep links
    - Configure app to handle notification taps
    - Navigate to Quote of the Day on notification tap
    - _Requirements: 7.4_

- [ ] 14. Checkpoint - Settings and Notifications Complete
  - Test theme changes apply everywhere
  - Verify notification scheduling works
  - Confirm settings persist and sync
  - Ask user if questions arise

- [ ] 15. Widget Module
  - [ ] 15.1 Create Widget Extension target
    - Add WidgetKit extension to Xcode project
    - Configure App Groups for data sharing
    - Set up shared UserDefaults for QOTD data
    - _Requirements: 10.1, 10.4_

  - [ ] 15.2 Implement QuoteWidgetProvider
    - Create `TimelineProvider` with placeholder, snapshot, and timeline methods
    - Fetch Quote of the Day from shared storage
    - Configure daily timeline refresh
    - _Requirements: 10.1, 10.2_

  - [ ] 15.3 Write property test for widget timeline
    - **Property 15: Widget Displays Correct QOTD**
    - Verify widget entry matches Quote of the Day for date
    - **Validates: Requirements 10.2**

  - [ ] 15.4 Build widget UI
    - Create `QuoteWidgetEntryView` with quote display
    - Support small and medium widget sizes
    - Apply consistent styling with main app
    - _Requirements: 10.1, 10.4_

  - [ ] 15.5 Configure widget deep linking
    - Add URL scheme for widget taps
    - Handle deep link in main app to show QOTD
    - _Requirements: 10.3_

- [ ] 16. Offline Support Module
  - [ ] 16.1 Implement local caching
    - Add CoreData or UserDefaults caching for quotes
    - Cache Quote of the Day for offline access
    - Store pending sync operations
    - _Requirements: 11.1, 11.3_

  - [ ] 16.2 Write property test for offline mode
    - **Property 16: Offline Mode Displays Cached Quotes**
    - Verify cached quotes display when offline
    - **Validates: Requirements 11.1**

  - [ ] 16.3 Add network monitoring
    - Implement `NetworkMonitor` using NWPathMonitor
    - Publish connectivity state to views
    - Trigger sync when connectivity restored
    - _Requirements: 11.2, 11.3_

  - [ ] 16.4 Add offline UI indicators
    - Show offline banner when disconnected
    - Display appropriate error messages for failed requests
    - _Requirements: 11.2, 11.4_

- [ ] 17. Navigation and App Structure
  - [ ] 17.1 Implement main tab navigation
    - Create `MainTabView` with Home, Favorites, Collections, Settings tabs
    - Add tab bar icons and labels
    - Handle auth state for tab visibility
    - _Requirements: All UI requirements_

  - [ ] 17.2 Wire up app entry point
    - Update `QuoteVaultApp.swift` with environment objects
    - Add auth state routing (login vs main app)
    - Configure appearance and theme on launch
    - _Requirements: 1.7_

- [ ] 18. Final Polish and Testing
  - [ ] 18.1 Add loading and error states throughout
    - Ensure all async operations show loading indicators
    - Add retry buttons for failed operations
    - _Requirements: 3.8, 11.4_

  - [ ] 18.2 Implement pull-to-refresh everywhere
    - Add refresh capability to all list views
    - _Requirements: 3.7_

  - [ ] 18.3 Run full property test suite
    - Execute all property tests with 100+ iterations
    - Fix any failing properties
    - Document test coverage

- [ ] 19. Final Checkpoint
  - Run complete app flow testing
  - Verify all features work together
  - Ensure no crashes or major bugs
  - Ask user if questions arise

## Notes

- All tasks including property-based tests are required
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation before moving to next feature area
- Property tests use SwiftCheck library as specified in design document
- Widget requires App Groups configuration in Xcode for data sharing

# Requirements Document

## Introduction

QuoteVault is a full-featured quote discovery and collection iOS app built with SwiftUI and Supabase. The app enables users to browse, save, and share inspirational quotes with cloud sync, personalization features, and home screen widgets.

## Glossary

- **Quote_Service**: The backend service responsible for fetching, storing, and managing quotes from Supabase
- **Auth_Service**: The authentication service handling user registration, login, logout, and session management via Supabase Auth
- **Collection_Manager**: The component managing user-created quote collections and favorites
- **Notification_Scheduler**: The component responsible for scheduling and managing local push notifications
- **Widget_Provider**: The WidgetKit timeline provider that supplies quote data to home screen widgets
- **Theme_Manager**: The component managing app appearance including dark/light mode and accent colors
- **Share_Generator**: The component responsible for generating shareable quote cards as images

## Requirements

### Requirement 1: User Authentication

**User Story:** As a user, I want to create an account and securely log in, so that my quotes and preferences sync across devices.

#### Acceptance Criteria

1. WHEN a user submits valid email and password on the sign-up screen, THE Auth_Service SHALL create a new user account in Supabase
2. WHEN a user submits invalid email format during sign-up, THE Auth_Service SHALL display a validation error message
3. WHEN a user submits a password shorter than 8 characters, THE Auth_Service SHALL reject the registration and display password requirements
4. WHEN a user enters valid credentials on the login screen, THE Auth_Service SHALL authenticate the user and navigate to the home screen
5. WHEN a user enters invalid credentials, THE Auth_Service SHALL display an authentication error message
6. WHEN a user requests password reset, THE Auth_Service SHALL send a reset email to the provided address
7. WHEN the app launches with a valid stored session, THE Auth_Service SHALL automatically restore the user session
8. WHEN a user taps logout, THE Auth_Service SHALL clear the session and navigate to the login screen

### Requirement 2: User Profile Management

**User Story:** As a user, I want to manage my profile information, so that I can personalize my account.

#### Acceptance Criteria

1. WHEN a user navigates to the profile screen, THE App SHALL display the user's name and avatar
2. WHEN a user updates their display name, THE Auth_Service SHALL persist the change to Supabase
3. WHEN a user selects a new avatar image, THE Auth_Service SHALL upload and update the avatar in Supabase storage
4. IF the avatar upload fails, THEN THE Auth_Service SHALL display an error message and retain the previous avatar

### Requirement 3: Quote Browsing and Discovery

**User Story:** As a user, I want to browse and discover quotes, so that I can find inspiration and wisdom.

#### Acceptance Criteria

1. WHEN the home screen loads, THE Quote_Service SHALL fetch and display a paginated list of quotes
2. WHEN a user scrolls to the bottom of the quote list, THE Quote_Service SHALL fetch the next page of quotes (infinite scroll)
3. WHEN a user selects a category filter, THE Quote_Service SHALL display only quotes matching that category
4. THE App SHALL provide at least 5 categories: Motivation, Love, Success, Wisdom, and Humor
5. WHEN a user enters a search keyword, THE Quote_Service SHALL filter quotes containing that keyword in text or author
6. WHEN a user searches by author name, THE Quote_Service SHALL display all quotes by that author
7. WHEN a user performs pull-to-refresh, THE Quote_Service SHALL reload the current quote list from the server
8. WHILE quotes are loading, THE App SHALL display a loading indicator
9. WHEN no quotes match the current filter or search, THE App SHALL display an empty state message

### Requirement 4: Favorites Management

**User Story:** As a user, I want to save my favorite quotes, so that I can easily access them later.

#### Acceptance Criteria

1. WHEN a user taps the favorite button on a quote, THE Collection_Manager SHALL add the quote to the user's favorites
2. WHEN a user taps the favorite button on an already-favorited quote, THE Collection_Manager SHALL remove it from favorites
3. WHEN a user navigates to the favorites screen, THE Collection_Manager SHALL display all favorited quotes
4. WHEN a user favorites a quote while logged in, THE Collection_Manager SHALL sync the favorite to Supabase
5. WHEN a user logs in on a new device, THE Collection_Manager SHALL restore all previously favorited quotes

### Requirement 5: Custom Collections

**User Story:** As a user, I want to organize quotes into custom collections, so that I can group related quotes together.

#### Acceptance Criteria

1. WHEN a user creates a new collection with a name, THE Collection_Manager SHALL create the collection in Supabase
2. WHEN a user attempts to create a collection with an empty name, THE Collection_Manager SHALL display a validation error
3. WHEN a user adds a quote to a collection, THE Collection_Manager SHALL associate the quote with that collection
4. WHEN a user removes a quote from a collection, THE Collection_Manager SHALL remove the association
5. WHEN a user views a collection, THE Collection_Manager SHALL display all quotes in that collection
6. WHEN a user deletes a collection, THE Collection_Manager SHALL remove the collection and all quote associations

### Requirement 6: Daily Quote Feature

**User Story:** As a user, I want to see a featured quote each day, so that I receive daily inspiration.

#### Acceptance Criteria

1. WHEN the home screen loads, THE Quote_Service SHALL display the Quote of the Day prominently
2. THE Quote_Service SHALL select a different Quote of the Day each calendar day
3. WHEN the calendar day changes, THE Quote_Service SHALL update the Quote of the Day
4. THE Quote_Service SHALL use server-side logic or deterministic selection to ensure consistency across devices

### Requirement 7: Push Notifications

**User Story:** As a user, I want to receive daily quote notifications, so that I'm reminded to check my daily inspiration.

#### Acceptance Criteria

1. WHEN a user enables daily notifications, THE Notification_Scheduler SHALL schedule a local notification for the daily quote
2. WHEN a user sets a preferred notification time, THE Notification_Scheduler SHALL schedule notifications at that time
3. WHEN a scheduled notification fires, THE Notification_Scheduler SHALL display the Quote of the Day
4. WHEN a user taps a notification, THE App SHALL open to the Quote of the Day
5. WHEN a user disables notifications, THE Notification_Scheduler SHALL cancel all pending notifications

### Requirement 8: Quote Sharing

**User Story:** As a user, I want to share quotes with others, so that I can spread inspiration.

#### Acceptance Criteria

1. WHEN a user taps share on a quote, THE App SHALL present the system share sheet with quote text
2. WHEN a user selects "Share as Card", THE Share_Generator SHALL create a styled image with the quote and author
3. THE Share_Generator SHALL provide at least 3 different card style templates
4. WHEN a user taps save card, THE Share_Generator SHALL save the quote card image to the device photo library
5. IF photo library access is denied, THEN THE App SHALL display a permission request message

### Requirement 9: Theme and Personalization

**User Story:** As a user, I want to customize the app appearance, so that it matches my preferences.

#### Acceptance Criteria

1. WHEN a user toggles dark mode, THE Theme_Manager SHALL switch the app to dark color scheme
2. WHEN a user toggles light mode, THE Theme_Manager SHALL switch the app to light color scheme
3. THE Theme_Manager SHALL provide at least 2 accent color options beyond the default
4. WHEN a user selects an accent color, THE Theme_Manager SHALL apply it throughout the app
5. WHEN a user adjusts font size, THE Theme_Manager SHALL update quote text display size
6. WHEN a user changes any setting, THE Theme_Manager SHALL persist the preference locally
7. WHEN a user is logged in, THE Theme_Manager SHALL sync preferences to their Supabase profile

### Requirement 10: Home Screen Widget

**User Story:** As a user, I want a home screen widget showing the daily quote, so that I can see inspiration without opening the app.

#### Acceptance Criteria

1. THE Widget_Provider SHALL display the current Quote of the Day on the home screen widget
2. WHEN the calendar day changes, THE Widget_Provider SHALL update the widget with the new Quote of the Day
3. WHEN a user taps the widget, THE App SHALL open and navigate to the Quote of the Day
4. THE Widget_Provider SHALL support at least one widget size (small, medium, or large)

### Requirement 11: Offline Handling

**User Story:** As a user, I want the app to work offline, so that I can access quotes without internet.

#### Acceptance Criteria

1. WHEN the device is offline, THE App SHALL display cached quotes from local storage
2. WHEN the device is offline, THE App SHALL display an offline indicator
3. WHEN the device regains connectivity, THE App SHALL sync any pending changes to Supabase
4. IF a network request fails, THEN THE App SHALL display an appropriate error message

### Requirement 12: Data Seeding

**User Story:** As a developer, I want the database seeded with quotes, so that users have content to browse.

#### Acceptance Criteria

1. THE Supabase database SHALL contain at least 100 quotes
2. THE quotes SHALL be distributed across all 5 categories (Motivation, Love, Success, Wisdom, Humor)
3. Each quote SHALL have text content and an author attribution

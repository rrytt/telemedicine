# Changelog

All notable changes to the telemedicine app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Doctor dashboard with appointment queue management
- Accept/reject appointment functionality with per-appointment processing states
- Doctor chat interface with real-time messaging
- Clinical notes editing and persistence
- File/document upload and management in chat
- Close session functionality for completed appointments
- Unread message indicators in appointment queue
- Agora video calling integration
- Theme selection (Light/Dark/System) with persistence
- Admin dashboard for user management
- Patient appointment booking and chat interface
- **Image display support in doctor chat messages**

### Fixed
- Per-appointment button state management in doctor dashboard
- Message loading and error states in doctor chat
- Clinical note controller persistence across rebuilds
- Debug print statements removed from production code
- Undefined context error in doctor chat close session button
- Unused import in app.dart
- Deprecated Radio widget usage replaced with modern SegmentedButton
- **Removed obsolete files from project root (doctor_dashboard_view.dart, chat_view.dart, doctor_dashboard_binding.dart)**

### Changed
- Replaced deprecated RadioListTile with ListTile + Radio for theme selection
- Improved UI state feedback for loading, errors, and processing states

### Technical Details
- **Framework**: Flutter with GetX for state management
- **Backend**: Supabase for authentication, database, and real-time features
- **Video Calls**: Agora RTC SDK integration
- **Architecture**: Modular structure with separate controllers for doctor, patient, and admin roles

### Known Issues
- None currently identified

---

## Development Notes
- Completed doctor module integration and missing features
- All major workflows (appointment management, chat, video calls, notes) are functional
- Static analysis passes with zero issues
- App builds successfully for Android
- **Project cleaned up - removed obsolete files**
- **Ready for testing and deployment**
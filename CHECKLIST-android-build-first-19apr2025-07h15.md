# Android-First Build Strategy Checklist - 19 Apr 2025, 07:15 EDT

## Overview
This checklist follows an Android-first build strategy to fix the Robinpedia app build issues. After attempting a web-first approach, we discovered platform compatibility issues with dart:ffi, which is not available on web. We've revised our strategy to focus on Android build first, with web implementation as a separate phase.

## Build Strategy Revision

### Phase 1: Platform Compatibility Issue (Critical)
- [x] Identified major issue: dart:ffi is not available on web platform <!-- Discovered 19 Apr 2025, 07:00 EDT -->
- [ ] Create platform-specific implementation strategy

### Phase 2: Implementation Options
Option A: Create Web-Specific Version
- [ ] Create conditional imports for FFI code
- [ ] Implement web-specific stubs for native functionality
- [ ] Use feature detection to handle platform differences

Option B: Focus on Android Build First
- [ ] Fix Android-specific build issues
- [ ] Implement web version as a separate phase

### Phase 3: Completed Fixes
- [x] Fix regex syntax in html_sanitizer.dart (line 286) <!-- Completed 19 Apr 2025, 06:45 EDT -->
- [x] Fix named parameter with underscore in content_extractor.dart (line 185) <!-- Completed 19 Apr 2025, 06:50 EDT -->
- [x] Fix duplicate DownloadInfo import in zim_download_screen.dart <!-- Completed 19 Apr 2025, 06:55 EDT -->

### Phase 4: Remaining Issues
- [ ] Fix Map<String, DownloadInfo> type error in zim_download_screen.dart
- [x] Fix Element.attributes.forEach parameter types in html_sanitizer.dart <!-- Completed 19 Apr 2025, 07:20 EDT -->
- [x] Fix searchEntries method not defined in ZimReader <!-- Completed 19 Apr 2025, 07:25 EDT -->
- [ ] Fix nullable String title parameter in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs HtmlPaddings type mismatch in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs Margins type mismatch in zim_reader_screen.dart
- [ ] Fix onLinkTap callback parameter types in zim_reader_screen.dart

## Revised Strategy: Android-First Approach

### Phase 5: Android Build Focus
- [ ] Fix Android-specific build issues
- [ ] Run flutter build apk --debug to verify Android build
- [ ] Test on Android emulator or device

### Phase 6: Web Implementation (Future Phase)
- [ ] Create platform-specific conditional imports
- [ ] Implement web stubs for FFI functionality
- [ ] Test web-specific implementation

## Final Verification
- [ ] Verify Android build works correctly
- [ ] Update documentation with platform compatibility notes
- [ ] Create separate branch for web implementation
- [ ] Merge Android fixes back to main branch

## Notes
- We're working on the `fix/web-build-first` branch (will rename to reflect Android-first approach)
- Initial web-first approach revealed platform compatibility issues with dart:ffi
- Revised strategy: Focus on Android build first, then implement web version separately
- Need to implement platform-specific code to handle FFI availability differences
- Priority is to get a clean Android build first, then address web compatibility

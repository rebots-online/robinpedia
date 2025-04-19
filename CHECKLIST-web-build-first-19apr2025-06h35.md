# Web-First Build Strategy Checklist - 19 Apr 2025, 06:35 EDT

## Overview
This checklist follows a web-first build strategy to fix the Robinpedia app build issues. We'll first get the web build working, then extend fixes to Android.

## Web Build Issues

### Phase 1: Critical Syntax Errors (Web Build Blockers)
- [ ] Fix regex syntax in html_sanitizer.dart (line 286)
- [ ] Fix named parameter with underscore in content_extractor.dart (line 185)
- [ ] Fix duplicate DownloadInfo import in zim_download_screen.dart

### Phase 2: Type Errors (Web Build)
- [ ] Fix Map<String, DownloadInfo> type error in zim_download_screen.dart
- [ ] Fix Element.attributes.forEach parameter types in html_sanitizer.dart
- [ ] Fix searchEntries method not defined in ZimReader
- [ ] Fix nullable String title parameter in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs HtmlPaddings type mismatch in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs Margins type mismatch in zim_reader_screen.dart
- [ ] Fix onLinkTap callback parameter types in zim_reader_screen.dart

### Phase 3: Web Build Testing
- [ ] Run flutter build web --debug to verify web build
- [ ] Test basic web functionality
- [ ] Fix any web-specific issues

## Android Build Issues

### Phase 4: Android-Specific Issues
- [ ] Fix any Android-specific build issues
- [ ] Run flutter build apk --debug to verify Android build
- [ ] Test on Android emulator or device

## Final Verification
- [ ] Verify all fixes work on both web and Android
- [ ] Update documentation
- [ ] Merge back to main branch

## Notes
- We're working on the `fix/web-build-first` branch
- Web build is faster for debugging and will help identify issues more quickly
- After web build is working, we'll extend fixes to Android
- Priority is to get a clean build first, then test functionality

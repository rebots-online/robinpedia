# Build Issues Checklist - 19 Apr 2025, 06:30 EDT

## Overview
This checklist tracks the issues that need to be fixed to make the app build successfully. We've created a new branch `fix/build-issues` to address these problems.

## Build Issues

### Syntax and Parsing Issues
- [ ] Fix regex syntax in html_sanitizer.dart (line 286)
- [ ] Fix named parameter with underscore in content_extractor.dart (line 185)
- [ ] Fix duplicate DownloadInfo import in zim_download_screen.dart

### Type Errors
- [ ] Fix Map<String, DownloadInfo> type error in zim_download_screen.dart
- [ ] Fix Element.attributes.forEach parameter types in html_sanitizer.dart
- [ ] Fix searchEntries method not defined in ZimReader
- [ ] Fix nullable String title parameter in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs HtmlPaddings type mismatch in zim_reader_screen.dart
- [ ] Fix EdgeInsets vs Margins type mismatch in zim_reader_screen.dart
- [ ] Fix onLinkTap callback parameter types in zim_reader_screen.dart

## Testing & Verification
- [ ] Build web version for faster debugging
- [ ] Fix issues one by one, verifying each fix
- [ ] Run flutter build apk --debug to verify Android build
- [ ] Test app functionality after fixes

## Notes
- We're working on the `fix/build-issues` branch
- After all issues are fixed, we'll merge back to the main branch
- Priority is to get a clean build first, then test functionality

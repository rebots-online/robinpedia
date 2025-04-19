# Robinpedia Android Dev Build Checklist
# Device: Samsung Z Fold
# Date: 16 April 2025, 11:54 EDT

## Checklist Items

- [ ] Validate local Flutter/Android environment (toolchain, device connectivity)
- [ ] Switch to cleanup/remove-placeholders branch and update codebase
- [ ] Correct main.dart to use ZimDownloadScreen on Android/native, ZimDownloadPlaceholder on web
- [ ] Disable file_picker in pubspec.yaml for Android build (workaround known issue)
- [ ] Run flutter pub get to refresh dependencies
- [ ] Catalog and prioritize all build errors from latest build log
- [x] Fix regex and syntax errors in html_sanitizer.dart  <!-- Completed 16 Apr 2025, 12:32 EDT -->
- [x] Resolve duplicate/extraneous method declarations in content_extractor.dart  <!-- Completed 16 Apr 2025, 12:52 EDT -->
- [x] Define or correct LzmaBinding in zim_reader.dart  <!-- Completed 16 Apr 2025, 17:56 EDT -->
- [ ] Correct constructor arguments for DownloadInfo in zim_download_screen.dart
- [ ] Implement or remove getFilePathForZim usage in zim_download_screen.dart
- [ ] Define _sanitizer and _clusterManager in content_extractor.dart or correct their usage
- [ ] Fix type mismatches and ensure all method signatures are correct
- [ ] Resolve FFI/type argument issues in abstract_ffi_binding.dart
- [ ] Re-run build after each fix to verify progress
- [ ] Verify codebase alignment with hybrid Knowledge Graph (hKG) and update hKG if needed
- [ ] Push all fixes and update this checklist with progress markers
- [ ] Build and deploy to Z Fold (flutter run or flutter build apk)
- [ ] Verify app launches and UI adapts to foldable device
- [ ] Test ZIM file opening, navigation, and content rendering
- [ ] Document any issues or blockers encountered
- [ ] Mark checklist items as complete, in progress, or tested as per conventions

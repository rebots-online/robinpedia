# Robinpedia Android Dev Build Checklist
# Device: Samsung Z Fold
# Date: 16 April 2025, 11:54 EDT

## Checklist Items

- [ ] Validate local Flutter/Android environment (toolchain, device connectivity)
- [ ] Switch to cleanup/remove-placeholders branch and update codebase
- [ ] Correct main.dart to use ZimDownloadScreen on Android/native, ZimDownloadPlaceholder on web
- [ ] Verify codebase alignment with hybrid Knowledge Graph (hKG) and update hKG if needed
- [ ] Disable file_picker in pubspec.yaml for Android build (workaround known issue)
- [ ] Run flutter pub get to refresh dependencies
- [ ] Push commit with updated main.dart and checklist
- [ ] Build and deploy to Z Fold (flutter run or flutter build apk)
- [ ] Verify app launches and UI adapts to foldable device
- [ ] Test ZIM file opening, navigation, and content rendering
- [ ] Document any issues or blockers encountered
- [ ] Mark checklist items as complete, in progress, or tested as per conventions

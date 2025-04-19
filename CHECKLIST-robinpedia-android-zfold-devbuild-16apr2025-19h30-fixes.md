# Robinpedia Android Dev Build Checklist
# Device: Samsung Z Fold
# Date: 16 April 2025, 19:30 EDT
# Updated: Fixed placeholder content and constructor issues

## Checklist Items

### Environment Setup
- [x] Validate local Flutter/Android environment (toolchain, device connectivity) <!-- Completed 16 Apr 2025, 18:30 EDT -->
- [x] Switch to cleanup/remove-placeholders branch and update codebase <!-- Completed 16 Apr 2025, 18:30 EDT -->
- [x] Correct main.dart to use ZimDownloadScreen on Android/native, ZimDownloadPlaceholder on web <!-- Completed 16 Apr 2025, 18:30 EDT -->
- [x] Disable file_picker in pubspec.yaml for Android build (workaround known issue) <!-- Completed 16 Apr 2025, 18:30 EDT -->
- [x] Run flutter pub get to refresh dependencies <!-- Completed 16 Apr 2025, 18:30 EDT -->

### Critical Issues (Placeholder Content Fix)
- [x] Catalog and prioritize all build errors from latest build log <!-- Completed 16 Apr 2025, 18:30 EDT -->
- [x] Fix regex and syntax errors in html_sanitizer.dart <!-- Completed 16 Apr 2025, 12:32 EDT -->
- [x] Resolve duplicate/extraneous method declarations in content_extractor.dart <!-- Completed 16 Apr 2025, 12:52 EDT -->
- [x] Define or correct LzmaBinding in zim_reader.dart <!-- Completed 16 Apr 2025, 17:56 EDT -->
- [x] Fix fallback to placeholder content in zim_reader.dart's getContentByUrl method <!-- Completed 16 Apr 2025, 19:15 EDT -->
- [x] Fix EnhancedClusterManager constructor to properly handle parameters <!-- Completed 16 Apr 2025, 19:20 EDT -->
- [ ] Complete cluster decompression implementation in enhanced_cluster_manager.dart
- [ ] Implement proper error handling in cluster_manager.dart
- [ ] Fix LZMA decompression in lzma_decompression.dart

### Secondary Issues
- [ ] Correct constructor arguments for DownloadInfo in zim_download_screen.dart
- [ ] Implement or remove getFilePathForZim usage in zim_download_screen.dart
- [ ] Define _sanitizer and _clusterManager in content_extractor.dart or correct their usage
- [ ] Fix type mismatches and ensure all method signatures are correct
- [ ] Resolve FFI/type argument issues in abstract_ffi_binding.dart

### Testing & Deployment
- [ ] Re-run build after each fix to verify progress
- [ ] Verify codebase alignment with hybrid Knowledge Graph (hKG) and update hKG if needed
- [ ] Push all fixes and update this checklist with progress markers
- [ ] Build and deploy to Z Fold (flutter run or flutter build apk)
- [ ] Verify app launches and UI adapts to foldable device
- [ ] Test ZIM file opening, navigation, and content rendering
- [ ] Document any issues or blockers encountered
- [ ] Mark checklist items as complete, in progress, or tested as per conventions

## Root Cause Analysis

The dev builds are showing placeholders instead of actual ZIM content due to:

1. In `lib/src/zim/zim_reader.dart`, the `getContentByUrl` method falls back to `_getSampleContent(url)` in the catch block
2. The cluster decompression implementation in `enhanced_cluster_manager.dart` is incomplete
3. Error handling in the ZIM content extraction pipeline needs improvement
4. LZMA decompression may not be properly integrated with the native libraries

## Implementation Plan

1. First fix the fallback to placeholder content by properly handling errors
   - ✅ Modified `getContentByUrl` to throw errors instead of falling back to placeholders
   - ✅ Fixed `EnhancedClusterManager` constructor to properly handle parameters

2. Complete the cluster decompression implementation
   - [ ] Implement proper cluster decompression in `enhanced_cluster_manager.dart`
   - [ ] Add better error handling for decompression failures

3. Ensure proper integration with LZMA native libraries
   - [ ] Fix LZMA decompression in `lzma_decompression.dart`
   - [ ] Add verification test for LZMA binding

4. Test with actual ZIM files to verify content rendering
   - [ ] Build and deploy to test device
   - [ ] Test with sample ZIM files
   - [ ] Document any remaining issues

## Changes Made (16 Apr 2025, 19:30 EDT)

1. Fixed `getContentByUrl` method in `zim_reader.dart` to throw errors instead of falling back to placeholder content
   - This ensures that the UI can properly handle errors and display appropriate messages
   - Removed the automatic fallback to sample content which was hiding real issues

2. Fixed `EnhancedClusterManager` constructor in `enhanced_cluster_manager.dart`
   - Updated parameter list to match what's expected in `zim_reader.dart`
   - Added proper initialization of cluster offsets from the ZIM file
   - Improved error handling during initialization

3. Next steps:
   - Complete the cluster decompression implementation
   - Fix LZMA decompression integration
   - Test with actual ZIM files

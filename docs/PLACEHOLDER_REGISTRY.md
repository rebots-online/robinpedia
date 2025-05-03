# Placeholder Data Registry

**Date**: May 3, 2025  
**Author**: Robin L. M. Cheung, MBA  
**Copyright**: (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

This registry tracks all authorized placeholder data in the Robinpedia project, following the [Placeholder Data Policy](../../RobinsAI.World-Admin/docs/PLACEHOLDER_DATA_POLICY.md).

| ID | Location | Purpose | Issue | Target Removal Date | Owner | Status |
|----|----------|---------|-------|---------------------|-------|--------|
| 1  | `lib/src/services/zim_catalog_service.dart` | Fallback ZIM catalog items | #1 | 2025-06-01 | @rebots-online | Active |
| 2  | `lib/src/screens/zim_download_screen.dart` | Sample language and category data | #2 | 2025-06-01 | @rebots-online | Active |
| 3  | `lib/src/services/zim_download_service.dart` | Mock download functionality | #3 | 2025-06-15 | @rebots-online | Active |

## Details

### 1. ZIM Catalog Service Fallback Data

**Location**: `lib/src/services/zim_catalog_service.dart`

**Purpose**: Provides fallback ZIM catalog items when the API call fails or returns invalid data.

**Implementation Notes**:
- Used only when all API endpoints fail or return invalid data
- Contains sample ZIM files with realistic metadata
- Download URLs point to actual files that exist on the Kiwix servers

**Removal Plan**:
1. Implement robust error handling for API responses
2. Add proper XML parsing for the Kiwix catalog format
3. Implement local caching of previously fetched catalog data
4. Add user-facing error messages for API failures

### 2. ZIM Download Screen Sample Data

**Location**: `lib/src/screens/zim_download_screen.dart`

**Purpose**: Provides sample language and category data for filtering ZIM files.

**Implementation Notes**:
- Used as initial values before API data is loaded
- Used as fallback when language/category API calls fail

**Removal Plan**:
1. Implement proper language and category fetching from the API
2. Add local caching of language and category data
3. Improve error handling for language and category API calls

### 3. ZIM Download Service Mock Functionality

**Location**: `lib/src/services/zim_download_service.dart`

**Purpose**: Provides mock download functionality for testing the download UI.

**Implementation Notes**:
- Simulates download progress, pausing, resuming, and completion
- Used during development and testing of the download UI

**Removal Plan**:
1. Implement actual file download functionality
2. Add proper download progress tracking
3. Implement pause/resume functionality
4. Add error handling for download failures

# Changelog

All notable changes to Robinpedia will be documented in this file.

## [Unreleased]

### Added
- Modern storage handling with SAF support
- Z-Fold specific optimizations
- USB storage monitoring and recovery
- Multiple payment gateway support (Chargebee)
- Prepper-focused features planning
- Enhanced offline capabilities
- Basic ZIM file header reading functionality
  - Successfully reads and validates magic number (0x44D495A)
  - Extracts version information, article counts, and pointer positions
  - Verified with test against real ZIM file
- Resilient Download Manager
  - Handles network failures, storage issues
  - Cosmic ray bit flip detection
  - Solar flare EMI resistance
  - Plausible deniability features
  - Resume capability
- Knowledge Engagement System
  - "Did You Know?" nudges
  - Time-aware content suggestions
  - Comprehensive disclaimers
  - Late-night learning mode
- Cozy UI Experience
  - Ambient particle effects
  - Warm, inviting color scheme
  - Night-friendly dark mode
  - Progress depth tracking
  - Firefly-like knowledge particles
  - Responsive animations
- Article Content System
  - HTML content parsing
  - Image extraction and caching
  - Link processing
  - Secure storage
  - Memory caching
- Cozy Article Viewer UI
  - Time-aware theming
  - Night mode with starry background
  - Ambient animations
  - Comfortable reading layout
  - Smart scroll handling
  - Share prompts
- Offline capabilities with background sync
  - Added SyncManager for handling offline operations
  - Implemented offline queue for article operations
  - Added offline status indicator in UI
  - Enhanced sharing with offline queue support
- Full-text search with ranking
  - Implemented search indexing
  - Added relevance-based ranking
  - Integrated with offline storage
- Secure storage enhancements
  - Added proper key management
  - Implemented file encryption
  - Enhanced data security
- Article parser improvements
  - Added image caching
  - Enhanced link handling
  - Improved offline content preparation

### Changed
- Updated project vision to focus on knowledge resilience
- Expanded storage support for various Android devices
- Improved error handling for storage operations
- Enhanced documentation with prepper focus
- Updated implementation status tracking to use [ ], [/], [X], and [✓] notation
  - [ ] Not started
  - [/] In progress
  - [X] Code complete but untested
  - [✓] Tested and battle-proven
- Enhanced security with plausible deniability
- Improved night mode for late sessions
- Optimized knowledge delivery timing
- Simplified initial implementation to get basic app running
  - Removed complex dependencies temporarily
  - Basic UI with welcome message
  - Material 3 design system
  - Dark/light theme support
- Updated ArticleViewer with offline support
- Enhanced SharePrompt with offline capabilities
- Modified KnowledgeSharing to handle offline operations
- Updated database schema for offline queue

### Technical
- Implemented Storage Access Framework (SAF)
- Added USB storage monitoring
- Created flexible payment architecture
- Enhanced Z-Fold device support
- Reduced dependencies to core essentials:
  - provider: For state management
  - path_provider: For file system access
  - cupertino_icons: For iOS-style icons

### Security
- Added comprehensive disclaimers
- Implemented secure storage
- Enhanced metadata anonymization

### Next Steps
- Re-add features incrementally:
  1. Basic article storage and retrieval
  2. HTML content rendering
  3. Offline support
  4. Secure storage for private content
  5. Night mode optimizations

## [0.1.0] - 2025-01-24

### Added
- Basic ZIM file parser
- Download manager with resume capability
- Cross-platform Flutter foundation
- Initial documentation structure
- Storage system architecture

### Technical
- Flutter project setup
- Android configuration
- Basic ZIM parsing implementation
- Download manager with progress tracking
- Storage access management

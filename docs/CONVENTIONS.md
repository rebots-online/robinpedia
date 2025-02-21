# Robinpedia Development Conventions

## Code Organization

### Directory Structure
```
lib/
├── core/           # Core functionality and utilities
├── features/       # Feature-specific implementations
├── models/         # Data models and state management
├── screens/        # UI screens and widgets
├── services/       # Service layer implementations
│   ├── knowledge_graph/  # Knowledge graph components
│   ├── library/         # ZIM library management
│   ├── payment/         # Payment processing
│   └── sync/            # Offline sync and queue management
└── themes/         # Theme and styling definitions
```

### File Naming
- Snake case for files: `download_manager.dart`
- Pascal case for classes: `DownloadManager`
- Camel case for variables and functions: `downloadFile()`
- Knowledge graph entities: `EntityTypeName`
- Test files: `*_test.dart`

## Coding Standards

### General
- Use strong-mode analysis
- Enable and respect all lint rules in `analysis_options.yaml`
- Maximum line length: 80 characters
- Use meaningful variable names
- Implement error handling for all async operations
- Use const constructors when possible
- Prefer final variables

### Knowledge Graph Conventions
- Entity names must be unique and descriptive
- Relationships should use active voice
- Include metadata for all entities
- Document relationship types
- Implement healing strategies
- Use typed relationships
- Cache graph queries appropriately

### Engagement System Standards
- Achievement IDs follow pattern: `category_achievement_name`
- Knowledge nudges must be non-intrusive
- Social sharing respects privacy settings
- Achievement triggers must be measurable
- Implement cooldown periods for notifications
- Document gamification elements
- Track engagement metrics

### Offline Capabilities

### Sync Operations
- Always queue operations that modify data when offline
- Use the SyncManager for all network-dependent operations
- Implement proper error handling and retry mechanisms
- Provide clear feedback about sync status to users

### Data Storage
- Use Drift for structured data storage
- Implement proper encryption for sensitive data
- Cache images and heavy content for offline use
- Clean up old cached data periodically

### UI Guidelines
- Show offline status clearly in the UI
- Provide feedback for queued operations
- Handle errors gracefully with user-friendly messages
- Support seamless online/offline transitions

### Documentation
- Every public API must have dartdoc comments
- Include code examples in complex functions
- Document state management decisions
- Add TODO comments with ticket numbers
- Knowledge graph changes must be documented
- Document engagement triggers
- Include metrics for features

### Testing
- Unit tests for all business logic
- Widget tests for UI components
- Integration tests for critical flows
- Graph consistency tests
- Achievement trigger tests
- Engagement metric tests
- Maintain 80%+ code coverage

## State Management
- Use Provider for simple state
- Bloc pattern for complex state
- Keep state close to where it's used
- Document state flow in comments
- Graph state management
- Achievement state tracking
- Engagement state monitoring

## Error Handling
- Use Result type for operations
- Log all errors with context
- User-friendly error messages
- Graceful degradation
- Graph consistency errors
- Achievement tracking errors
- Network resilience

## Performance Guidelines
- Lazy load when possible
- Cache appropriately
- Minimize rebuilds
- Profile regularly
- Optimize graph queries
- Batch achievement updates
- Monitor engagement metrics

## Architecture Support

### Android Architecture Support
The app supports the following Android architectures:

- **ARM64 (arm64-v8a)**
  - Primary architecture for modern Android devices
  - Optimized for performance and energy efficiency
  - Used in most current smartphones and tablets

- **ARM32 (armeabi-v7a)**
  - Legacy support for older ARM devices
  - Ensures compatibility with budget devices
  - Important for accessibility in developing markets

- **x86_64**
  - Support for Intel/AMD 64-bit processors
  - Used in Android emulators and some tablets
  - Important for development and testing

- **x86**
  - Legacy Intel/AMD 32-bit support
  - Maintains compatibility with older x86 devices
  - Used in some older tablets and development environments

### iOS Architecture Support
- **ARM64**
  - Modern iOS devices
  - Optimized for Apple Silicon

### Desktop Support
- **Windows**: x86_64
- **macOS**: ARM64, x86_64
- **Linux**: x86_64, ARM64

### APK Distribution
- Split APKs enabled for optimized downloads
- Universal APK available for broader compatibility
- Play Store will serve the appropriate version based on device architecture

## Git Workflow
- Feature branches from master
- Conventional commits
- PR reviews required
- Squash merge to master
- Document knowledge graph changes
- Track engagement feature additions

## Deviation Notes
- Custom ZIM parser implementation instead of using existing libraries
- Flutter-specific architecture patterns
- Offline-first approach affecting state management
- Custom knowledge graph implementation
- Engagement system architecture

## Project-Specific Conventions

- **Documentation Style**: All documentation will follow the [Google Developer Documentation Style Guide](https://developers.google.com/style).

- **Code Style**: Dart code will adhere to the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide.

- **Commit Messages**: Commit messages should follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

- **Branching Strategy**: We will use a simplified version of [Gitflow](https://datasift.github.io/gitflow/IntroducingGitFlow.html), with `main` representing the production-ready code and feature branches for new development.

## Deviations from All-Project SOPs

- *Currently, there are no deviations from the all-project SOPs.*

## Rationale
These conventions are designed to ensure code consistency, readability, and maintainability. They support our vision by promoting collaboration and knowledge sharing.

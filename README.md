# Robinpedia

Copyright (C)2025 Robin L. M. Cheung. All rights reserved.

NB: While a more final implementation is intended to be open-sourced, there are concepts not intended to be 'out in the wild' as yet.
Thus, the bulk of the repo will remain privately-hosted until a later date.

Your offline knowledge companion - a cozy space for learning and sharing knowledge.

## INTRODUCTION
 
 - This represents a 'clean room'-inspired implementation insofar as the basic ZIM reader concept is implemented as part of this de novo codebase
 - Intended to overcome technical and licencing limitations of existing efforts

### Departures

 - Technical Issues: Android storage issues deriving from older implementations and Googe Play Store policy changes that are somewhat complex to back out anda change directions
 - Licence Issues: some existing repos are encumbered by strict 'Copyleft' licence regimes, which can cause unintended restrictive side effects

### Innovations

 - However, it is redesigned beyond navigation of ZIM files as a standard website archival format, preferring to anticipate than to retrofit:
 - We implement pragmatic innovations, such as an annotation and navigation system that anticipates our imminent migration to a Knowledge Graph-based representation of the information
 - Annotations, thus are intended to be regarded as a derivate of, but still part of, an overall Knowledge Graph paradigm and considered when synthesizing across enmeshed knowledge
 - Measures of internal consistency, self-healing, and quantitative synthesis across the knowledge graph (1st order) and across its derivatives (2nd order) are anticipatively incorporated in the design
 - Inspired by other 'offline crowdsourcepedia readers,' popular amongst 'prepper culture' in particular;


## Features

### 🌟 Core Features
- Beautiful and comfortable article reading experience
- Smart content organization and discovery
- Secure offline storage with encryption
- Full-text search with relevance ranking

### 🔄 Offline Capabilities
- Seamless offline/online transitions
- Background sync for queued operations
- Offline article viewing and sharing
- Automatic image caching
- Conflict resolution

### 🎯 Knowledge Management
- Intelligent article parsing
- Smart content suggestions
- Knowledge path tracking
- Achievement system

### 🤝 Social Features
- Knowledge sharing with offline queue
- Community engagement
- Learning achievements
- Progress tracking

## Getting Started

### Prerequisites
- Flutter SDK >=3.5.4
- Dart SDK >=3.5.4
- Android Studio / VS Code with Flutter extension

### Installation
1. Clone the repository:
```bash
git clone https://github.com/rebots-online/robinpedia-flutter.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Architecture

### Core Components
- **ArticleManager**: Handles article loading and caching
- **SyncManager**: Manages offline operations and sync
- **SearchService**: Provides full-text search capabilities
- **SecureStorage**: Handles encrypted data storage

### Data Flow
1. User requests content
2. App checks local cache
3. If offline, serves cached content
4. If online, syncs pending operations
5. Updates local cache with new content

## Contributing

Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Documentation

- [Architecture & Diagrams](docs/DIAGRAMS.md)
- [Development Conventions](docs/CONVENTIONS.md)
- [Development Roadmap](ROADMAP.md)
- [Deployment Guide](docs/DEPLOYMENT_20250204.md)
- [Future Features](docs/FUTURE_FEATURES.md)
- [User Guide](docs/USER_GUIDE.md)
- [API Documentation](docs/API.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

## Development Status

This project is in active development with regular updates and feature additions. See [ROADMAP.md](ROADMAP.md) for planned features and improvements.

## License

Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved. 
See LICENSE_NON_COMMERCIAL.md and LICENSE_COMMERCIAL.md for licensing details.
While a more final implementation is intended to be open-sourced, there are concepts not intended to be 'out in the wild' as yet.
Thus, the bulk of the repo will remain privately-hosted until a later date.

## Contact

- Author: Robin L. M. Cheung, MBA
- Email: robinpedia@RobinsAI.World
- Website: robinpedia.RobinsAI.World
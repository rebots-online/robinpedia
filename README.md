# Robinpedia

Your offline knowledge companion - a cozy space for learning and sharing knowledge.

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

Copyright (C) 2025 Robin L. M. Cheung, MBA
See LICENSE_NON_COMMERCIAL.md and LICENSE_COMMERCIAL.md for licensing details.

## Contact

- Author: Robin L. M. Cheung, MBA
- Email: robinpedia@robin.bio
- Website: www.robin.bio/robinpedia

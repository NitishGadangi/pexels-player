# Pexels Player

An iOS video discovery app with an Instagram-style full-screen video feed. Built with UIKit, Combine, and Swift Package Manager in a fully modular architecture.

The app fetches popular videos from the [Pexels API](https://www.pexels.com/api/), displays them in a 3-column grid, and lets users tap into a vertical-scrolling video player with quality switching, play/pause, mute, and auto-advance.

## Video Walthrough

> TBD: Video recording

## Architecture

### Modular SPM Monorepo

All modules are defined in a single `Package.swift` at the project root. The Xcode project links against these local SPM libraries — no CocoaPods or external dependencies.

Each feature follows an **Interface / Implementation** split:
- **Interface module** (e.g. `HomeInterface`) — public protocols and models with zero dependencies. Other modules depend only on interfaces, never on concrete implementations.
- **Implementation module** (e.g. `Home`) — coordinators, view models, view controllers, repositories. Depends on its own interface + shared libraries.

This enforces clean module boundaries and prevents circular dependencies at compile time.

### MVVM + Coordinator within each module

```
Coordinator (builds the screen, handles navigation)
    |
ViewModel (business logic, state management)
    |
ViewController (UI rendering, user input)
    |
UseCase → Repository → NetworkService
```

- **ViewModel** exposes `actionHandler` (PassthroughSubject for user actions) and `statePublisher` (AnyPublisher for UI state). The ViewController sends actions and subscribes to state — unidirectional data flow via Combine.
- **Coordinator** implements the interface's `Buildable` protocol, creates all dependencies, and acts as the ViewModel's `NavigationDelegate`. It never touches UIKit views directly — it delegates navigation to the `SharedRouter`.
- **ViewController** is purely presentation — it renders state and forwards user input as actions. No business logic, no data storage.

> TBD: Feature level modules overview

### App Composition

`CompositionRoot` is the single DI container. It creates all services in `init()`, assembles coordinators with `LazyRouter` (a private class that breaks the circular coordinator-router dependency), and wires everything together in `assembleAndStart()`.

`SharedRouter` owns the navigation controller and maps `Route` enum cases to the correct coordinator's `build()` method. All cross-feature navigation flows through the router — coordinators never push or present directly.

`AppConfigurator` handles global appearance setup (navigation bar, tab bar theming).

## Module Overview

### Features
| Module | Description |
|--------|-------------|
| `Home` | 3-column video grid with infinite scroll pagination |
| `VideoFeed` | Full-screen vertical video player with AVPlayer pool (3 instances), quality switching, play/pause, mute, progress bar, auto-advance |
| `SavedItems` | Placeholder screen for future saved videos feature |

### Libraries
| Module | Description |
|--------|-------------|
| `NetworkLib` | Protocol-based networking with Combine. Endpoint protocol, URLSession implementation, per-endpoint headers |
| `UIComponents` | BaseViewController, RemoteImageView, LoadingView, AppTheme, layout/animation extensions, shared transition animator |
| `CacheLib` | Two-tier image cache (in-memory NSCache + disk persistence) |
| `LoggingLib` | Protocol-based logging with level filtering and console output |

### Shared
| Module | Description |
|--------|-------------|
| `SharedModelsInterface` | Video, VideoFile, VideoUser, VideoQuality models + VideoPaginationManagerProtocol |
| `SharedRouterInterface` | Route enum, NavigationStyle, SharedRouterProtocol |
| `SharedRouter` | Concrete router implementation with UINavigationControllerDelegate for custom transitions |

## Dependency Graph

> TBD: Dependency Graph

## Future Scope

- **DiffableDataSource** for Home grid — smoother updates without full `reloadData()`
- **Video caching** — cache downloaded video segments to reduce bandwidth
- **Video prefetching** — preload next video's first few seconds for instant playback
- **Saved Items** — persist liked/bookmarked videos with local storage
- **Improved error recovery** — retry with exponential backoff on 429 rate limits
- **Unit test coverage** — expand ViewModel and service tests across all modules

## Running the Project

1. Clone the repository
2. Open `PexelsPlayer.xcodeproj` in Xcode 15+
3. Add your Pexels API key in `Modules/Home/Home/Sources/Data/PexelsEndpoint.swift` — replace the value in the `Authorization` header
4. Build and run on a simulator or device (iOS 16+)

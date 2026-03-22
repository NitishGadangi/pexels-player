# Pexels Player

An iOS video discovery app with an Instagram-style full-screen video feed. Built with UIKit, Combine, and Swift Package Manager in a fully modular architecture.

The app fetches popular videos from the [Pexels API](https://www.pexels.com/api/), displays them in a 3-column grid, and lets users tap into a vertical-scrolling video player with quality switching, play/pause, mute, and auto-advance.

## Video Walthrough

https://github.com/user-attachments/assets/6db92cde-6e51-4ff4-9900-a9e20f07894d

**Watch on youtube: https://www.youtube.com/shorts/cX498il-N0o**


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

<img src="https://github.com/user-attachments/assets/a49b9f0d-f726-45e1-b48e-c20f10c2bc81" alt="02-feature-module-structure" width="800" />


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

<img src="https://github.com/user-attachments/assets/bfe32e52-f7d0-4971-bd57-b1778e9e35d3" alt="pexels-player-dependency-graph" style="max-width: 100%; height: auto;" />


## Key Design Decisions

### Single VideoPaginationManager

A single `VideoPaginationManager` instance is shared between Home and VideoFeed. It is created by `HomeCoordinator` and passed by reference to `VideoFeedCoordinator` when the user taps a video. This means both screens read from and paginate against the same data — no duplication, no re-fetching. When the user scrolls deep into the VideoFeed and triggers the next page, those new videos are also available when they return to the Home grid.

The protocol (`VideoPaginationManagerProtocol`) lives in `SharedModelsInterface` so both feature interfaces can reference it without depending on each other.

### VideoPlayerPool (3 Instances)

AVPlayer is resource-heavy — creating one per cell would exhaust memory quickly. `VideoPlayerPool` maintains exactly **3 AVPlayer + AVPlayerLayer pairs** and reuses them as the user scrolls:

1. If a player is already assigned to the requested video index, return it.
2. If a free (unassigned) player exists, assign it.
3. Otherwise, reclaim the player **furthest from the currently visible index** — pause it, nil out its item, remove its layer, and reassign.

On cell reuse, the `AVPlayerLayer` is stripped from the cell's container to prevent stale video frames from appearing on recycled cells.

### VideoPlayerManager

`VideoPlayerManager` is the orchestration layer that sits between the pool and the ViewModel. It handles:

- **Quality selection** — uses `QualityPreferenceService` to pick the best `VideoFile` for the user's preferred quality (HD by default), with fallback to adjacent tiers.
- **Playback lifecycle** — creates `AVPlayerItem`, assigns it to a pooled player, observes item status (buffering → ready → playing/failed), and reports state changes via a Combine subject.
- **Progress tracking** — periodic time observer updates a progress subject that drives the UI progress bar.
- **Cleanup** — invalidates KVO observations and removes time observers before preparing a new video, preventing stale callbacks from old items.

The ViewModel never touches AVPlayer directly — it sends play/pause/mute commands to `VideoPlayerManager` and reacts to its state publisher.

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

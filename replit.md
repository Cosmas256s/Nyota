# Nyota - Math is Easy

A Flutter-based educational mobile web application for children to learn mathematics.

## Overview

Nyota (meaning "star" in Swahili) is an interactive math learning platform with:
- Dual dashboards for parents and children
- Gamified math activities (Counting, Shapes, Basic Math, Advanced Math)
- Firebase authentication
- Text-to-speech support

### Shapes Activity — 3 Sub-Activities (Magrид-style)
When a child opens Shapes from the planner, they land in a visually rich hub with three sub-activities:
1. **Shape Hunt** (`shapes_find_shape.dart`) — Find all hidden instances of a target shape scattered across a complex scene; develops visual discrimination
2. **Shape Pairs** (`shapes_find_pairs.dart`) — Tap two matching shapes in a grid (shapes vary in color & size to reinforce that shape identity persists across variations)
3. **Shape Patterns** (`shapes_patterns.dart`) — Observe a sequence of shapes (AB, ABC, AABB) and choose what comes next

### Landing Page & Navigation
- **Landing page (`landing_screen.dart`):** Warm gradient background, floating animated pastel dots (CustomPainter), `learn.png` hero image with floating bounce animation, animated NYOTA letter-by-letter title (gradient terracotta shader), "Welcome to Your Learning Adventure! ⭐" subtitle, animated Log In / Sign Up buttons with press-scale effect and Sign Up pulse.
- **AuthWrapper** now shows `LandingPage` (not login) for unauthenticated users.
- **`lib/widgets/nav_buttons.dart`:** `AnimatedBackButton` (circle pill with bounce-on-press, auto-pops or custom onTap) and `AnimatedForwardButton` (filled pill with arrow, loading state). Both are added to Login and Signup screens (top-left `Positioned` inside a `Stack`).

## Tech Stack

- **Framework:** Flutter (web build)
- **Language:** Dart
- **Backend:** Firebase (Auth, Core)
- **State Management:** Provider
- **UI:** Google Fonts (Fredoka), flutter_screenutil

## Project Structure

- `lib/` - Dart source code
  - `main.dart` - Entry point, Firebase init, routing
  - `models/` - Data models
  - `screens/` - UI screens (auth, dashboards, activities)
  - `services/` - Business logic (auth, API, storage)
  - `constants/` - App-wide constants
- `assets/` - Images, fonts
- `build/web/` - Built Flutter web output (served on port 5000)
- `web/` - Flutter web template files
- `serve.py` - Python HTTP server to serve the built web app

## Running the App

The app runs as a Flutter web application served by Python's HTTP server.

1. Build: `flutter build web --release`
2. Serve: `python serve.py` (runs on port 5000)

The "Start application" workflow handles this automatically.

## Dependency Notes

- `google_fonts` pinned to `^6.3.2` (Flutter 3.32.0 installed via Nix is not compatible with `^8.0.2` which requires Dart SDK >=3.9.0)
- Flutter installed as Nix system dependency

## Firebase Configuration

Firebase is configured via `google-services (1).json`. The app requires Firebase Auth to be set up in the Firebase Console for authentication to work.

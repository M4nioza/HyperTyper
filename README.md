# HyperTyper

A modern macOS typing practice application built with Swift and SwiftUI that helps users improve their typing speed and accuracy through interactive exercises and games.

## Features

### 🎮 Game Modes

- **Level Mode**: Progressive difficulty levels that unlock as you improve
- **Timed Mode**: Test your skills against the clock (1 or 5 minute options)
- **Adaptive Training**: Automatically focuses on keys you struggle with

### ⌨️ Keyboard Support

- Multiple keyboard layouts:
  - QWERTY
  - Dvorak
  - Colemak
- Virtual on-screen keyboard with visual key highlighting
- Finger guidance for proper typing technique

### 📊 Statistics & Progress Tracking

- Real-time WPM (Words Per Minute) tracking
- Accuracy percentage monitoring
- Per-key error statistics
- Session summaries with performance trends
- Level progression with best scores

### 👥 User Management

- Multiple user profiles with customizable avatars
- Individual progress tracking per user
- Data export/import functionality (JSON format)

### 🎨 Modern UI

- Native macOS look and feel
- Clean, distraction-free interface
- Visual feedback for correct/incorrect typing
- Responsive layout with proper window sizing

## Technologies Used

- **SwiftUI**: Modern declarative UI framework for macOS
- **Combine**: Reactive programming for game state management
- **Core Data**: Persistent storage for user profiles and statistics
- **AppKit Integration**: Low-level keyboard event capture via NSViewRepresentable

## Project Structure

```
HyperTyper/
├── App/
│   └── HyperTyperApp.swift        # App entry point
├── Models/
│   ├── Layout.swift               # Keyboard layout definitions
│   └── User.swift                 # User and statistics models
├── Views/
│   ├── ContentView.swift         # Main content container
│   ├── TypingView.swift           # Core typing game interface
│   ├── UserSelectionView.swift   # Profile selection screen
│   ├── StatisticsView.swift       # Performance analytics
│   └── VirtualKeyboard.swift      # On-screen keyboard
├── Logic/
│   ├── TypingGame.swift           # Game logic and state
│   ├── UserManager.swift          # User profile management
│   ├── WordGenerator.swift        # Word generation for exercises
│   └── WordsData.swift            # Word dictionary
└── Persistence/
    └── Persistence.swift          # Core Data setup
```

## Getting Started

### Prerequisites

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/M4nioza/HyperTyper.git
   ```

2. Open the project in Xcode:
   ```bash
   open HyperTyper.xcodeproj
   ```

3. Select your development team in Signing & Capabilities

4. Build and run (Cmd + R)

## How to Use

1. **Create a Profile**: Launch the app and create a new user profile with your preferred avatar
2. **Select Game Mode**: Choose between Levels, Timed, or Adaptive training
3. **Start Typing**: Type the displayed words as quickly and accurately as possible
4. **Track Progress**: View your statistics after each session to monitor improvement

### Keyboard Shortcuts

- Standard typing applies - just focus on the target words displayed
- Use standard typing techniques; backspace is supported

## Data Storage

- User data is stored locally using Core Data
- Export functionality allows you to backup your progress as a `.exp` file
- Import previously exported data to restore progress

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is for educational/personal use.

## Acknowledgments

- Word lists inspired by common typing practice resources
- Built with SwiftUI and the power of native macOS development
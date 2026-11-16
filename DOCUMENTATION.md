# 📚 Calm Attack - Complete Documentation

> *Your comprehensive guide to understanding, using, and contributing to Calm Attack*

Welcome to the complete documentation for **Calm Attack** - the open-source Flutter app designed to help people manage panic attacks through scientifically-backed grounding techniques.

## 🌟 Table of Contents

- [📖 About This Documentation](#-about-this-documentation)
- [🎯 Project Overview](#-project-overview)
- [🏗️ Architecture](#️-architecture)
- [✨ Features Deep Dive](#-features-deep-dive)
- [🛠️ Development](#️-development)
- [🎨 Design Guidelines](#-design-guidelines)
- [🔒 Privacy & Security](#-privacy--security)
- [📱 Platform Specifics](#-platform-specifics)
- [🤝 Community](#-community)
- [📚 Resources](#-resources)

---

## 📖 About This Documentation

This documentation is designed for:
- 👩‍💻 **Developers** wanting to contribute
- 🎨 **Designers** improving user experience
- 🧠 **Mental Health Professionals** providing feedback
- 👥 **Community Members** understanding the project
- 📱 **Users** wanting to understand features

---

## 🎯 Project Overview

### 🎨 Mission Statement
To provide immediate, accessible, and effective panic attack relief through technology, while maintaining complete user privacy and leveraging community-driven development.

### 🌈 Core Values
- **🔒 Privacy First**: No data collection, completely offline
- **♿ Accessibility**: Usable by everyone, including those with disabilities
- **🧠 Science-Based**: Grounded in proven mental health techniques
- **👥 Community-Driven**: Built by people who understand the struggle
- **💝 Free Forever**: Open source ensures accessibility

### 🎯 Target Users
- People experiencing panic attacks
- Individuals with anxiety disorders
- Mental health support networks
- Healthcare professionals
- Wellness advocates

---

## 🏗️ Architecture

### 📱 Technology Stack
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Audio**: AudioPlayers package
- **Animations**: Flutter built-in animations
- **State Management**: StatefulWidget pattern

### 🗂️ Project Structure
```
Calm-Attack/
├── lib/                      # Main application code
│   ├── main.dart            # App entry point with theming
│   ├── Pages/               # Screen widgets
│   │   ├── start_screen.dart
│   │   ├── breathing_screen.dart
│   │   ├── audio_screen.dart
│   │   ├── smell_screen.dart
│   │   ├── bubble_pop_game_screen.dart
│   │   └── finish_screen.dart
│   ├── core/                # Core architecture (NEW!)
│   │   ├── constants/       # App-wide constants
│   │   │   └── app_constants.dart
│   │   ├── utils/           # Utility functions
│   │   │   ├── audio_utils.dart
│   │   │   ├── navigation_utils.dart
│   │   │   └── session_utils.dart
│   │   └── widgets/         # Reusable UI components
│   │       └── common_widgets.dart
│   ├── Animations/          # Custom animations
│   └── Buttons/             # Legacy UI components
├── assets/                  # Static assets
│   ├── *.png               # Images and icons
│   ├── *.mp3               # Audio files (music and pop sounds)
│   ├── Smell/              # Smell exercise images
├── android/                # Android-specific code
├── ios/                    # iOS-specific code
└── docs/                   # Documentation files
```

### 🔄 App Flow
1. **Start Screen** → Get Started button
2. **Breathing Screen** → 3-3-3 breathing exercise
3. **Audio Screen** → Nature sounds and music  
4. **Smell Screen** → Visual scent imagination  
5. **Bubble Pop Game** → Interactive cognitive engagement
6. **Finish Screen** → Session completion and time tracking

### 🏗️ Architecture Improvements (2025 Refactor)

The codebase underwent major refactoring to improve maintainability and contributor experience:

#### 🎯 **Core Architecture**
- **Constants System**: Centralized colors, text styles, sizes, and asset paths
- **Utility Functions**: Reusable functions for audio, navigation, and session management
- **Common Widgets**: Standardized UI components for consistent design
- **Better Error Handling**: Robust disposal patterns and lifecycle management

#### 🔧 **Key Improvements**
- **Consistent Layout**: All screens now follow the same responsive design pattern
- **Centralized Theming**: Material 3 theming with consistent colors and typography
- **Asset Management**: Organized asset declarations with proper error handling
- **Code Organization**: Modular structure makes it easier for contributors
- **Documentation**: Comprehensive inline documentation for all components

---

## ✨ Features Deep Dive

### 🫁 Breathing Exercise
**Purpose**: Regulate breathing to activate the parasympathetic nervous system

**Technique**: 3-3-3 Breathing Method
- Inhale for 3 seconds
- Hold for 3 seconds  
- Exhale for 3 seconds

**Implementation**:
- Visual breathing guide with expanding/contracting animation
- Dynamic text display (INHALE, HOLD, EXHALE)
- 3-second timing for each phase
- Phase indicators with visual timing display

**Mental Health Basis**: Proven to reduce anxiety by stimulating the vagus nerve

### 🎵 Sound Focus Exercise
**Purpose**: Ground users in the present moment through auditory focus

**Available Sounds**:
- Waves (Ocean sounds)
- Rain (Rainfall ambience)
- Birds (Nature bird sounds)
- Fire (Crackling fire)
- Forest (Forest ambience)
- Wind (Wind sounds)

**Implementation**:
- 6 high-quality audio tracks (music-1.mp3 to music-6.mp3)
- Play/pause controls
- Track selection with visual feedback
- Audio spectrum visualization animation
- Automatic audio cleanup on screen navigation

**Mental Health Basis**: Based on mindfulness and grounding techniques used in CBT

### 🌸 Smell Imagination Exercise
**Purpose**: Engage olfactory memory for calming visualization

**Visual Elements**:
- Beautiful flower and nature imagery (F1.png - F8.png)
- Aesthetically pleasing visual arrangements
- Calming color palettes
- Multiple visual prompts for imagination

**Implementation**:
- High-quality imagery positioned across the screen
- Responsive design adapting to different screen sizes
- Visual-based imagination prompts
- Customizable duration

**Mental Health Basis**: Olfactory system's direct connection to limbic system

### 🫧 Bubble Pop Game
**Purpose**: Interactive cognitive redirection through focused gameplay

**Gameplay**:
- Sequential bubble popping (numbers 1-20)
- Colorful gradient bubbles with satisfying pop sounds
- Non-overlapping bubble placement for clear targeting
- Immediate audio feedback with random pop sound selection

**Implementation**:
- Custom bubble painter with gradient effects and highlights
- Collision detection for proper bubble placement
- Audio player with multiple pop sound variants (pop1.mp3, pop2.mp3, pop3.mp3)
- Responsive design adapting to different screen sizes
- Progress tracking through sequential number system
- Note: Currently resets session time when navigating to finish screen

**Mental Health Basis**: Cognitive engagement therapy and mindful distraction techniques

---

## 🛠️ Development

### 🚀 Getting Started

#### Prerequisites
```bash
# Flutter SDK (3.0+)
flutter --version

# IDE with Flutter plugin
# VS Code, Android Studio, or IntelliJ

# Git for version control
git --version
```

#### Setup Process
```bash
# 1. Fork and clone
git clone https://github.com/YOUR-USERNAME/Calm-Attack.git
cd Calm-Attack

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. Run tests
flutter test
```

### 🧪 Testing Strategy
- **Unit Tests**: Core logic and utilities
- **Widget Tests**: UI components
- **Integration Tests**: Full user flows
- **Accessibility Tests**: Screen reader compatibility
- **Platform Tests**: iOS and Android specific features

### 📦 Dependencies Management
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # State management (currently unused)
  audioplayers: ^6.0.0      # Audio playback
  rive: ^0.13.20            # Animations
  cupertino_icons: ^1.0.2   # iOS-style icons

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0     # Code quality
  flutter_launcher_icons: ^0.13.1  # App icon generation
```

### 🔄 CI/CD Pipeline
- **Code Quality**: Automated linting and formatting
- **Testing**: Unit, widget, and integration tests
- **Security**: Dependency vulnerability scanning
- **Build**: Multi-platform compilation
- **Release**: Automated changelog generation

---

## 🎨 Design Guidelines

### 🌈 Color Palette
```css
/* Primary Colors */
--primary-blue: #052D94     /* Deep calming blue */
--secondary-blue: #1E3A8A   /* Medium blue */
--accent-blue: #3B82F6      /* Bright blue */

/* Neutral Colors */
--background: #FFFFFF       /* Clean white */
--surface: #F8FAFC         /* Light gray */
--text-primary: #1F2937     /* Dark gray */
--text-secondary: #6B7280   /* Medium gray */

/* Semantic Colors */
--success: #10B981          /* Green for completion */
--warning: #F59E0B          /* Orange for attention */
--error: #EF4444            /* Red for errors */
```

### 🎯 Typography
- **Headers**: Bold, clear hierarchy
- **Body Text**: High contrast, readable fonts
- **Interactive Elements**: Clear, actionable text
- **Accessibility**: Minimum 16px font size

### 📐 Layout Principles
- **Whitespace**: Generous spacing to reduce cognitive load
- **Hierarchy**: Clear information architecture
- **Consistency**: Predictable patterns throughout
- **Responsiveness**: Adapts to all screen sizes

### 🎭 Animation Guidelines
- **Subtle**: Non-distracting, calming motions
- **Purposeful**: Animations serve specific functions
- **Accessible**: Respect motion sensitivity preferences
- **Performance**: Smooth 60fps on all devices

---

## 🔒 Privacy & Security

### 🛡️ Privacy Principles
1. **Zero Data Collection**: No personal information gathered
2. **Offline First**: All functionality works without internet
3. **Local Storage Only**: Settings stored on device
4. **No Tracking**: No analytics or usage monitoring
5. **Transparent**: Open source means auditable privacy

### 🔐 Security Measures
- **No Network Requests**: Prevents data leakage
- **Secure Storage**: Device-level encryption for settings
- **No Third-Party SDKs**: Eliminates tracking vectors
- **Code Auditing**: Regular security reviews
- **Vulnerability Response**: Responsible disclosure process

### 📋 Compliance
- **GDPR Compliant**: No personal data processing
- **COPPA Safe**: Suitable for all ages
- **HIPAA Considerations**: Healthcare setting appropriate
- **Accessibility Standards**: WCAG 2.1 AA compliance

---

## 📱 Platform Specifics

### 🤖 Android
- **Minimum SDK**: API 21 (Android 5.0)
- **Target SDK**: Latest stable
- **Permissions**: None
- **App Icon**: Adaptive icon support
- **Material Design**: Platform-appropriate styling

### 🍎 iOS
- **Minimum Version**: iOS 12.0
- **Target Version**: Latest stable
- **Permissions**: Haptic feedback only
- **App Icon**: Multiple sizes provided
- **Human Interface Guidelines**: iOS design patterns

### 🌐 Web (Future)
- **Progressive Web App**: Offline functionality
- **Responsive Design**: All screen sizes
- **Accessibility**: Full keyboard navigation
- **Performance**: Fast loading times

---

## 🤝 Community

### 👥 Contributor Types
- **🧑‍💻 Developers**: Code, architecture, testing
- **🎨 Designers**: UI/UX, visual assets, animations
- **🧠 Mental Health Professionals**: Technique validation, content review
- **📝 Writers**: Documentation, content creation
- **🧪 Testers**: Quality assurance, accessibility testing
- **🌍 Translators**: Internationalization support

### 🏆 Recognition System
- **README Credits**: Contributor listing
- **Release Notes**: Feature acknowledgments
- **GitHub Badges**: Contribution recognition
- **Community Spotlights**: Regular contributor features

### 📋 Contribution Guidelines
- **Code Quality**: Follow Dart conventions
- **Testing**: Include tests with contributions
- **Documentation**: Update docs with changes
- **Mental Health Sensitivity**: Consider vulnerable users
- **Accessibility**: Ensure inclusive design

---

## 📚 Resources

### 🧠 Mental Health Research
- [Grounding Techniques in CBT](https://example.com)
- [3-3-3 Breathing Research](https://example.com)
- [Mindfulness for Anxiety](https://example.com)
- [Panic Attack Management](https://example.com)

### 💻 Technical Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design Guidelines](https://material.io)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/)

### ♿ Accessibility Resources
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [Mobile Accessibility Best Practices](https://example.com)

---

## 📞 Support & Contact

### 🆘 Getting Help
- **GitHub Issues**: Technical problems and bugs
- **GitHub Discussions**: Questions and ideas
- **Email**: [FatimahAlabbas1@outlook.sa](mailto:FatimahAlabbas1@outlook.sa)
- **Documentation**: This comprehensive guide

### 🤝 Contributing
- Read our [Contributing Guide](CONTRIBUTING.md)

---

<div align="center">

## 🌟 Thank You

*Your interest in Calm Attack means the world to us. Whether you're a user finding peace or a contributor building hope, you're part of something beautiful.*

**Together, we're transforming panic into peace, one breath at a time.** 💙

---

*"The best way to take care of the future is to take care of the present moment."* - Thich Nhat Hanh

**Made with 💙 by a person that care**

</div>

<p align="center">
  <img src="https://img.icons8.com/color/96/tractor.png" alt="AgroShare Logo" width="96"/>
</p>

<h1 align="center">🌾 AgroShare</h1>

<p align="center">
  <strong>Smart Farm Equipment Sharing Platform</strong><br/>
  Connecting farmers to affordable agricultural machinery — rent, buy, and share nearby equipment with a few taps.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.6+-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web-green" alt="Platforms"/>
  <img src="https://img.shields.io/badge/Languages-12%20Indian-orange" alt="Languages"/>
  <img src="https://img.shields.io/badge/License-Private-lightgrey" alt="License"/>
</p>

---

## 📖 About

**AgroShare** is a cross-platform Flutter application that empowers small and marginal farmers by enabling peer-to-peer sharing of expensive agricultural equipment. Instead of each farmer investing lakhs in machinery they use only a few days per season, AgroShare connects equipment owners with farmers who need temporary access — reducing costs, increasing utilization, and building stronger farming communities.

### 🎯 Problem Statement

> Over 80% of Indian farmers own less than 2 hectares, making modern farm machinery financially unviable. Equipment sits idle for most of the year while neighboring farmers struggle with manual labor. AgroShare bridges this gap.

### 💡 Solution

A location-aware, multilingual mobile platform where farmers can:
- **Discover** nearby equipment on an interactive map
- **Book** machinery by the hour with transparent pricing
- **List** their own idle equipment to earn passive income
- **Connect** with trusted farming communities for group purchases
- **Learn** best agricultural practices through a curated knowledge hub

---

## ✨ Key Features

### 🗺️ Location-Aware Equipment Discovery
- Interactive **FlutterMap** (OpenStreetMap) displaying nearby equipment within a 2–3 km radius
- Real-time GPS positioning via **Geolocator** with smart caching (last known → low accuracy fallback)
- Tap any equipment pin to view details, distance, and availability
- **Reverse geocoding** to display human-readable location names

### 🚜 Equipment Marketplace
- Dual listing modes — **Rent** (hourly pricing) or **Sell** (fixed price)
- Rich equipment cards showing name, location, distance, rating, review count, price, and availability
- Advanced **search and filter** system (by crop type, task, keyword)
- Location modal with embedded map for each equipment item
- Equipment detail screen with owner information, description, and action buttons

### 📅 Booking Lifecycle Management
- Full booking workflow: **Upcoming → Active → Completed**
- Three-tab booking interface with status-based categorization
- "Start Rental" button to activate upcoming bookings
- "Return Equipment" flow with cost summary and confirmation
- **Review & Rating system** (1–5 stars + optional text review) upon return

### 👥 Community Hub
- Browse and join local farming community groups
- Create new groups with descriptions and member invitations
- Group detail screens with member lists and shared resources
- Community-driven knowledge sharing

### 💬 Real-Time Chat
- Equipment-contextual one-on-one messaging between owners and renters
- Support for text messages, images, and system notifications
- Unread message tracking with real-time Firestore streams
- Chat history persisted in Cloud Firestore

### 🧑‍🌾 Farmer Profiles
- Detailed profile with **Trust Score** (out of 5.0)
- Activity summary: completed rentals, equipment listed, community purchases
- Profile photo upload via **Firebase Storage**
- Editable personal information (name, location, phone)
- "My Equipment" section showing all listed items with edit/remove options

### 📚 Agricultural Knowledge Hub (Explore)
- Curated farming tips, seasonal guides, and best practices
- Agriculture news integration via **News API**
- Rich card-based layout with categorized content

### 🌍 Multilingual Support (12 Indian Languages)
- Full UI localization using JSON-based translation files
- In-app language switcher on the Profile page
- Supported Languages:

| Language | Code | Language | Code |
|----------|------|----------|------|
| English | `en` | Kannada | `kn` |
| Hindi | `hi` | Malayalam | `ml` |
| Bengali | `bn` | Tamil | `ta` |
| Telugu | `te` | Marathi | `mr` |
| Gujarati | `gu` | Punjabi | `pa` |
| Odia | `or` | Urdu | `ur` |

### 🌾 Seasonal Smart Recommendations
- Auto-detects current farming season (Planting / Harvesting / Preparation)
- Displays 2–3 contextually relevant equipment suggestions on the dashboard
- Season-aware tips and booking alerts

### 🔔 Push Notifications
- Firebase Cloud Messaging integration
- Notification types: new messages, booking confirmations, equipment requests, payment receipts, system alerts
- Structured notification model with deep-link data

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point (Firebase init + Firestore seeding)
├── app.dart                     # Root widget with auth-gated routing + i18n
│
├── models/                      # Data layer
│   ├── equipment.dart           # Equipment model with Firestore serialization
│   ├── booking.dart             # Booking model with lifecycle status enum
│   ├── farmer.dart              # Farmer/User profile model with trust score
│   ├── chat.dart                # Chat + ChatMessage models
│   └── notification.dart        # AppNotification model with factory methods
│
├── data/                        # Local data & stores
│   ├── equipment_data.dart      # Dummy equipment data for development
│   ├── booking_store.dart       # In-memory booking state management
│   ├── farmer_data.dart         # Dummy farmer profiles
│   └── report_store.dart        # Report/analytics store
│
├── services/                    # Business logic & external integrations
│   ├── auth_service.dart        # Firebase Auth (login, register, sign-out)
│   ├── firestore_service.dart   # Firestore CRUD operations
│   ├── storage_service.dart     # Firebase Storage (image uploads)
│   ├── chat_service.dart        # Real-time chat via Firestore
│   ├── location_service.dart    # GPS + geocoding with smart caching
│   ├── news_service.dart        # Agriculture news API integration
│   └── notification_service.dart# Firebase Cloud Messaging + local notifications
│
├── screens/                     # UI pages (17 screens)
│   ├── login_screen.dart        # Auth screen (login/register)
│   ├── main_shell.dart          # Root shell with bottom navigation (5 tabs)
│   ├── home_screen.dart         # Dashboard with hero banner, quick actions, seasonal tips
│   ├── explore_screen.dart      # Agriculture knowledge hub
│   ├── find_equipment_screen.dart # Equipment discovery with map, search, filters
│   ├── equipment_detail_screen.dart # Detailed equipment view with booking actions
│   ├── equipment_list_screen.dart # Compact equipment listing
│   ├── booking_screen.dart      # Booking creation form
│   ├── my_bookings_screen.dart  # 3-tab booking lifecycle (Upcoming/Active/History)
│   ├── list_equipment_screen.dart # Owner listing form (rent or sell)
│   ├── community_screen.dart    # Community groups hub
│   ├── create_group_screen.dart # Group creation form
│   ├── group_detail_screen.dart # Group details with members
│   ├── chat_screen.dart         # Real-time messaging
│   ├── map_screen.dart          # Full-screen map view
│   ├── nearby_map_screen.dart   # Nearby equipment map with simulated data
│   └── profile_screen.dart      # User profile, settings, language, logout
│
├── widgets/                     # Reusable UI components
│   ├── ag_button.dart           # Branded primary button
│   ├── ag_card.dart             # Branded card with shadow & radius
│   ├── section_title.dart       # Section header widget
│   ├── equipment_card.dart      # Equipment list card with location + rating
│   ├── equipment_action_sheet.dart # Bottom sheet with rent/buy actions
│   ├── location_map_modal.dart  # Map modal bottom sheet for equipment location
│   └── reactive_helpers.dart    # Loading/Error/Empty state widgets
│
├── theme/                       # Design system
│   ├── app_colors.dart          # Color palette (AgroShare green theme)
│   ├── app_spacing.dart         # Spacing & radius constants
│   └── app_theme.dart           # Material ThemeData configuration
│
├── l10n/                        # Localization
│   ├── app_localizations.dart   # Translation loader and lookup
│   └── locale_provider.dart     # Locale state management with persistence
│
└── utils/
    └── image_picker_util.dart   # Camera/Gallery image picker utility
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.6+ / Dart 3.6+ |
| **Backend** | Firebase (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions) |
| **Maps** | FlutterMap (OpenStreetMap / Leaflet) |
| **Location** | Geolocator + Geocoding |
| **Typography** | Google Fonts (Poppins) |
| **Localization** | JSON-based translations (12 languages) |
| **HTTP** | `http` package for News API |
| **Storage** | SharedPreferences for locale persistence |
| **Image Handling** | image_picker for camera/gallery |

---

## 🚀 Getting Started

### Prerequisites

Ensure the following are installed on your development machine:

- **Flutter SDK** ≥ 3.6.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** ≥ 3.6.0 (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter/Dart plugins
- **Firebase CLI** — [Install Firebase CLI](https://firebase.google.com/docs/cli)
- A **Firebase project** with the following services enabled:
  - Authentication (Email/Password)
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging
  - Cloud Functions (optional, for advanced features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ramith407/AgroShare.git
   cd AgroShare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** authentication
   - Create a **Cloud Firestore** database
   - Enable **Cloud Storage**
   - Download and add platform configuration files:
     - **Android**: Place `google-services.json` in `android/app/`
     - **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`

4. **Set up Android permissions** (already configured)

   The `AndroidManifest.xml` includes:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

6. **Verify code health**
   ```bash
   flutter analyze
   ```
   > Expected result: **No issues found!**

---

## 📱 App Screens Overview

| Screen | Description |
|--------|-------------|
| **Login / Register** | Firebase Auth with email/password, auto-routing to MainShell |
| **Home Dashboard** | Hero banner, GPS location display, quick actions grid, seasonal recommendations, farming tips |
| **Find Equipment** | Interactive map, keyword search, crop/task filters, equipment list with location modals |
| **Equipment Detail** | Full equipment profile with images, specs, owner info, and Book/Buy actions |
| **Booking Form** | Date picker, duration selector, cost calculator, booking confirmation |
| **My Bookings** | Tabbed lifecycle view (Upcoming → Active → Completed) with Start/Return/Review flows |
| **List Equipment** | Owner form to list machinery for Rent or Sale with pricing and descriptions |
| **Explore (Knowledge Hub)** | Agricultural articles, seasonal tips, news feed |
| **Community** | Browse groups, create new groups, group details with members |
| **Chat** | Real-time messaging between equipment owners and renters |
| **Nearby Map** | Full-screen map with simulated nearby equipment pins |
| **Profile** | User info, trust score, activity stats, equipment management, language switcher, logout |

---

## 🎨 Design System

AgroShare uses a custom design system for UI consistency:

| Component | Description |
|-----------|-------------|
| `AgButton` | Primary action button with icon support, green gradient styling |
| `AgCard` | Elevated card with soft shadows, rounded corners, and tap support |
| `SectionTitle` | Consistent section header with optional trailing widget |
| `EquipmentCard` | Rich card for equipment display with location, rating, and distance |
| `ReactiveHelpers` | Loading spinner, error view, and empty state components |

### Color Palette

| Token | Usage |
|-------|-------|
| `primaryGreen` | Primary brand color — buttons, headers, accents |
| `secondaryGreen` | Lighter green — backgrounds, badges, highlights |
| `textDark` | Primary text color |
| `textMuted` | Secondary/descriptive text |
| `textLight` | White text on dark backgrounds |
| `cardBackground` | Card surface color |
| `lightBackground` | Page scaffold background |
| `divider` | Subtle separators |

---

## 🌐 Localization

AgroShare supports **12 Indian languages** out of the box. Translation files are stored as JSON in `assets/translations/`:

```
assets/translations/
├── en.json    # English
├── hi.json    # Hindi
├── bn.json    # Bengali
├── te.json    # Telugu
├── ta.json    # Tamil
├── mr.json    # Marathi
├── gu.json    # Gujarati
├── kn.json    # Kannada
├── ml.json    # Malayalam
├── pa.json    # Punjabi
├── or.json    # Odia
└── ur.json    # Urdu
```

### Adding a New Language

1. Create a new JSON file in `assets/translations/` (e.g., `as.json` for Assamese)
2. Add all translation keys matching the English file
3. Register the locale in `lib/l10n/app_localizations.dart`
4. Add the asset path in `pubspec.yaml`

---

## 🔥 Firebase Configuration

### Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | Farmer profiles with trust scores and activity stats |
| `equipment` | Listed machinery with pricing, location, and availability |
| `bookings` | Booking records with lifecycle status tracking |
| `chats` | Chat threads between users |
| `messages` | Individual chat messages |
| `notifications` | Push notification records |
| `groups` | Community group metadata |

### Security Rules

Ensure your Firestore rules allow authenticated read/write access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📂 Project Structure Summary

```
AgroShare/
├── android/               # Android platform files
├── ios/                   # iOS platform files
├── web/                   # Web platform files
├── assets/
│   ├── images/            # Equipment and hero images (WebP)
│   ├── icon/              # App icon assets
│   └── translations/      # 12 language JSON files
├── lib/                   # Dart source code (see Architecture above)
├── test/                  # Unit and widget tests
├── pubspec.yaml           # Dependencies and asset declarations
├── analysis_options.yaml  # Lint rules
└── README.md              # This file
```

---

## 🧪 Testing

```bash
# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is privately maintained. All rights reserved.

---

## 👨‍💻 Authors

- **Ramith Naik** — *Full-Stack Developer & Project Lead*
- **Tejas RK** — *Full-Stack Developer & Project Lead*
- **Sagar P** — *Full-Stack Developer & Project Lead*
- **Bhavish Gowda** — *Full-Stack Developer & Project Lead*


---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) — Beautiful native apps from a single codebase
- [Firebase](https://firebase.google.com) — Backend-as-a-Service
- [FlutterMap](https://pub.dev/packages/flutter_map) — OpenStreetMap for Flutter
- [Google Fonts](https://fonts.google.com) — Poppins typeface
- [Geolocator](https://pub.dev/packages/geolocator) — Device GPS access

---

<p align="center">
  Made with ❤️ for Indian Farmers
</p>

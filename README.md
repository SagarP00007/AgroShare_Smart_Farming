# AgroShare 🌾🚜

AgroShare is a smart, Flutter-based mobile application designed to empower farmers by providing a peer-to-peer equipment sharing marketplace, AI-driven crop recommendations, and a community platform for collaborative farming.

## Features & Workflow

### 1. **Authentication & Profile**
- **Login/Signup**: Uses standard email authentication via typical provider services (Firebase).
- **Profile**: Farmers can view their total trust score, their listed equipment, their recent bookings, and their group memberships.
- **Localization**: Supports dynamic switching between **English**, **Hindi**, and **Kannada**, ensuring accessibility for regional farmers.

### 2. **Discover & Find Equipment**
- **Map View**: Integrated with `flutter_map`, showing available machinery geographically.
- **List View**: Alternatively view listed machinery (tractors, harvesters, etc.) below the map in a scrolling list.
- **Search & Filters**: Users can filter equipment by farming tasks (e.g., Plowing, Harvesting) or crop types (e.g., Rice, Sugarcane).
- **Booking Flow**: Farmers can either **Borrow** (rent per hour) or **Buy** the equipment. If borrowing, they select dates, times, and a custom or preset duration to confirm their rental.
- **Messaging**: Integrated Chat to directly text the owner for negotiations before buying or inquiring about renting.

### 3. **My Bookings & Rentals**
- **Tabs**: "Upcoming", "Active", and "History".
- **Lifecycle**:
  - *Upcoming*: A rental that is secured. Users tap "Start Rental" to begin.
  - *Active*: The machine is currently in use. When finished, users tap "Return Equipment".
  - *Returning*: Returns require farmers to leave a rating and review for the equipment.
  - *History*: All past rentals and associated ratings are available here.

### 4. **AI-driven Features (Explore)**
- **Weather API**: Integrates with weather metrics to provide data-driven insights.
- **Crop Diagnosis**: Offers image-based crop disease diagnosis or soil analysis stubs using Gemini AI stubs.

### 5. **Farmer Community**
- **Groups**: Allows farmers to join regional or crop-focused groups.
- **Shared Assets**: Some high-value equipments are pooled and managed by the collective members of the group.

## Project Structure

- `lib/models/`: Holds data models (`Equipment`, `Booking`, `Farmer`, `Review`, `LocaleProvider`).
- `lib/screens/`: Contains all full-page UI widgets (Home, Find, Booking, Profile, Chat, Auth).
- `lib/services/`: Core logic abstractions to interface with Firebase (`FirestoreService`, `AuthService`, `StorageService`).
- `lib/widgets/`: Reusable components (`AgButton`, `AgCard`, `ReactiveHelpers`, etc.).
- `lib/theme/`: Shared styling constraints, colors, and margins (`AppColors`, `AppSpacing`).
- `lib/l10n/`: Localization bindings and parsing (`AppLocalizations`).
- `assets/translations/`: Core language `json` definition files (`en.json`, `hi.json`, `kn.json`).

## Architecture Highlights
- Uses a `StreamBuilder` architecture to maintain perfectly real-time syncing between Cloud Firestore and the UI.
- Localized dynamic contexts using `LocaleProviderInherited`.
- Resilient UI components handling empty states and networking errors gracefully via `ReactiveHelpers`.

## Setup & Running

1. Enable Developer Mode on Windows if symlink errors occur (required by some Flutter plugins).
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis to keep consistency:
   ```bash
   flutter analyze
   ```
4. Start debugging on emulator/device:
   ```bash
   flutter run
   ```

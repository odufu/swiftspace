# Swift Space: Technical Documentation

## 1. Overview
Swift Space is a premium, map-first property listing application designed to prioritize location intelligence and user-defined priorities. Unlike traditional grid-only listing apps, Swift Space leads with an interactive discovery experience, unifying geographic context with the detail of property listings.

---

## 2. Core Architecture

### 2.1 Map-First Design System
The application utilizes a **Unified Stack Layout** where the map acts as the persistent foundation. 
- **Files**: `lib/screens/explore_screen.dart`
- **Key Logic**: The UI uses a `Stack` containing a full-screen map background and a `DraggableScrollableSheet` (the "Swift Peek" sheet) for the property grid.

### 2.2 AI Recommendation Service (`AiRecommendationService`)
The recommendation logic ranks properties based on dynamic user priorities (Price, Road Access, Utilities, and Healthcare).
- **Files**: `lib/services/ai_recommendation_service.dart`
- **Scoring**: Uses a weighted normalization algorithm. Weights decrease based on priority order (1st: 1.0, 2nd: 0.8, etc.).
- **Factors**:
    - **Price**: Normalized against the current list range.
    - **Road Access**: ProximityToRoadMeters.
    - **Utilities**: ElectricitySupplyHours + Water availability.
    - **Hospital**: ProximityToHospitalKm.

### 2.3 Legal & Authenticity System
Integrated trust indicators to differentiate between regular and premium (lawyer-verified) listings.
- **Components**: `LegalDocument` models, `Lawyer Seal` badges, and `TermsModal`.
- **Files**: `lib/models/property.dart`, `lib/screens/property_details_screen.dart`.

---

## 3. Map Implementation

### 3.1 Technology Choice: FlutterMap
After evaluating Google Maps, the project standardized on **FlutterMap** with **latlong2** to ensure:
1. **Full Windows/Web/Mobile Support** (no platform restrictions).
2. **Zero API Billing Requirement**.
3. **Animated Widget Support** (Direct injection of Flutter widgets as markers).

### 3.2 Premium Tile Configuration
The app uses three distinct tile layers for a high-end feel:
- **Normal Mode (Light)**: `CartoDB Voyager` (Clean, modern aesthetic).
- **Normal Mode (Dark)**: `CartoDB Dark All` (Sleek, low-glare view).
- **Satellite Mode**: `Esri World Imagery` (Professional-grade high-resolution satellite data).

### 3.3 Custom Marker System
- **Pill Markers**: Used for rentals, displaying the price in a compact pill.
- **House Markers**: Used for sales, creating a distinct visual "home" silhouette.
- **State Logic**: Markers dynamically show the "Legal Seal" (Shield icon) and "Best Offer" crown based on property metadata.

---

## 4. Technical Settings & Dependencies

### 4.1 Key Packages
| Package | Purpose |
| :--- | :--- |
| `flutter_map` | Core map rendering engine |
| `latlong2` | Geographic coordinate math (WGS84) |
| `geolocator` | User location and distanceBetween logic |
| `provider` | State management (Theme, Favorites, Preferences) |
| `lucide_icons` | Premium minimalist iconography system |
| `cached_network_image` | High-performance property image loading |

### 4.2 Platform Support
- **Windows**: Fully supported (primary development environment). Requires `geolocator_windows` for location features.
- **Android/iOS**: Fully supported.
- **Web**: Fully supported.

---

## 5. File Breakdown

### 📂 `lib/models/`
- `property.dart`: The core data model with LatLng coords, legal logic, and mock data generators.

### 📂 `lib/screens/`
- `explore_screen.dart`: The main entry point. Houses the Map-Peek unified layout.
- `property_details_screen.dart`: Implements the 360 viewer, video player, and legal verification UI.
- `agent_dashboard_screen.dart`: Accounting and listing management for agents.

### 📂 `lib/widgets/`
- `custom_marker.dart`: Specialized `CustomPainter` for map icons.
- `best_offer_card.dart`: The premium card used for AI recommendations.
- `property_snippet.dart`: The "peek-a-boo" modal when a marker is tapped.

### 📂 `lib/services/`
- `ai_recommendation_service.dart`: Logic for prioritization and scoring.

---

## 6. Development Notes
- **Coordinates**: Uses `LatLng(double latitude, double longitude)`. 
- **Distance**: Calculated in meters using `Geolocator.distanceBetween()`.
- **Theme**: Supports System, Light, and Dark modes via `ThemeProvider`.

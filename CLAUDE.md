# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OVO RIDE Driver App** - A production-ready Flutter ride-sharing driver application built with Flutter 3.5+ and GetX framework.

This is a complete driver-side application for a ride-sharing platform with real-time ride management, wallet/financial features, scheduled rides, support tickets, and comprehensive driver management.

## Development Commands

### Essential Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>
flutter devices  # List available devices

# Build for production
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle (Play Store)
flutter build ios --release          # iOS build

# Code analysis
flutter analyze

# Clean build artifacts
flutter clean

# Run tests
flutter test

# Update dependencies
flutter pub upgrade
```

### Common Development Workflows

```bash
# Full clean rebuild (when facing build issues)
flutter clean && flutter pub get && flutter run

# Generate missing files (if using build_runner in future)
flutter pub run build_runner build --delete-conflicting-outputs

# Change package name (one-time setup)
flutter pub run change_app_package_name:main com.your.package
```

### Device-Specific Commands

```bash
# Android-specific
flutter run -d android
flutter build apk --split-per-abi  # Smaller APKs for different architectures

# iOS-specific
flutter run -d ios
open ios/Runner.xcworkspace  # Open in Xcode
```

## Architecture Overview

### Three-Layer Clean Architecture

```
Presentation Layer (UI)
        ↓
Data Layer (Business Logic & State Management)
        ↓
Services Layer (API, Firebase, Location, Pusher)
```

**Key Files:**
- Entry point: `lib/main.dart`
- DI setup: `lib/core/di_service/di_services.dart`
- Routing: `lib/core/route/route.dart`
- Environment config: `lib/environment.dart`

### State Management Pattern (GetX)

All business logic follows this controller pattern:

```dart
class ExampleController extends GetxController {
  final ExampleRepo repo;
  ExampleController({required this.repo});

  bool isLoading = false;

  Future<void> loadData() async {
    isLoading = true;
    update();  // Triggers UI rebuild via GetBuilder

    ResponseModel response = await repo.getData();

    if (response.statusCode == 200) {
      // Handle success
    } else {
      CustomSnackBar.error(errorList: [response.message]);
    }

    isLoading = false;
    update();
  }
}
```

**UI Update Pattern:**
```dart
GetBuilder<ExampleController>(
  builder: (controller) => Text(controller.data)
)
```

### Dependency Injection

All dependencies registered in `lib/core/di_service/di_services.dart`:

```dart
// Services
Get.lazyPut(() => ApiClient(sharedPreferences: Get.find()), fenix: true);

// Repositories
Get.lazyPut(() => LoginRepo(apiClient: Get.find()));

// Controllers
Get.lazyPut(() => LoginController(repo: Get.find()));
```

**Key Pattern:** Controllers depend on Repos → Repos depend on ApiClient → ApiClient depends on SharedPreferences

### API Communication

**Centralized API Client:** `lib/data/services/api_service.dart`

All API calls go through repositories using this pattern:

```dart
class ExampleRepo {
  final ApiClient apiClient;
  ExampleRepo({required this.apiClient});

  Future<ResponseModel> getData() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.endpointPath}';
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
```

**Response Model Pattern:**
```dart
ResponseModel response = await repo.apiCall();
if (response.statusCode == 200) {
  MyModel model = MyModel.fromJson(jsonDecode(response.responseJson));
} else {
  // Handle error
}
```

**Authentication:**
- Bearer token stored in SharedPreferences
- Tokens automatically included in headers when `passHeader: true`
- Custom `dev-token` header for backend validation

### Navigation

GetX routing with named routes defined in `lib/core/route/route.dart`:

```dart
// Navigate
Get.toNamed(RouteHelper.screenName);
Get.toNamed(RouteHelper.screenName, arguments: data);

// Replace current
Get.offNamed(RouteHelper.screenName);

// Clear stack and navigate
Get.offAllNamed(RouteHelper.screenName);

// Go back
Get.back();
Get.back(result: data);
```

## Key Features & File Locations

### 1. Scheduled Rides (Advanced Feature)

**Purpose:** Drivers create rides in advance, allowing riders to join scheduled trips.

**Key Files:**
- Model: `lib/data/model/scheduled_ride/scheduled_ride_model.dart`
- Repo: `lib/data/repo/scheduled_ride/scheduled_ride_repo.dart`
- Controller: `lib/data/controller/scheduled_ride_controller.dart`
- Screens: `lib/presentation/screens/scheduled_rides/`
- Documentation: `SCHEDULED_RIDES_README.md`

**Operations:** Create, edit, cancel, complete, delete scheduled rides with automatic fare calculation.

### 2. Ride Management

**Controllers:**
- New rides: `lib/data/controller/new_ride_controller.dart`
- Active rides: `lib/data/controller/accept_ride/accept_ride_controller.dart`
- Ride details: `lib/data/controller/ride_details_controller.dart`
- Messaging: `lib/data/controller/ride_messenger_controller.dart`

**Screens:**
- `lib/presentation/screens/rides/` - Main ride screens
- `lib/presentation/screens/ride_history/` - Past rides

### 3. Wallet & Financial

**Controllers:**
- Wallet: `lib/data/controller/my_wallet_controller.dart`
- Deposits: `lib/data/controller/deposit/deposit_controller.dart`
- Withdrawals: `lib/data/controller/withdraw/withdraw_controller.dart`

**Screens:**
- `lib/presentation/screens/deposits/`
- `lib/presentation/screens/withdraw/`

### 4. Driver Profile & Verification

**Controllers:**
- Profile: `lib/data/controller/account/profile_complete_controller.dart`
- KYC: `lib/data/controller/kyc_controller.dart`

**Screens:**
- `lib/presentation/screens/Profile/`
- `lib/presentation/screens/account/`

### 5. Real-time Features

**Firebase Push Notifications:**
- Service: `lib/data/services/push_notification_service.dart`
- Background handler: `lib/main.dart` (_messageHandler)
- FCM token stored in SharedPreferences

**Pusher Integration:**
- Controller: `lib/data/controller/global_pusher_contorller/global_pusher_controller.dart`
- Subscribe to driver-specific channels for real-time ride updates

**Location Services:**
- Google Maps integration throughout the app
- Geolocator for real-time location tracking during rides
- Geocoding for address conversion

## Code Modification Guidelines

### When Adding New Features

1. **Create Model** in `lib/data/model/` if needed
2. **Create Repository** in `lib/data/repo/` for API calls
3. **Create Controller** in `lib/data/controller/` extending GetxController
4. **Register DI** in `lib/core/di_service/di_services.dart`
5. **Add Route** in `lib/core/route/route.dart`
6. **Create UI** in `lib/presentation/screens/`
7. **Add API Endpoint** in `lib/core/utils/url_container.dart`

### When Modifying Controllers

- Always use `update()` after changing state variables to trigger UI rebuild
- Use `isLoading` boolean for loading states
- Handle errors via `CustomSnackBar.error(errorList: [])`
- Follow existing controller patterns for consistency

### When Working with API

- All endpoints defined in `lib/core/utils/url_container.dart`
- Base URL: `https://www.halalfoodalliance.org/mysharingapp.com/api/`
- Use `passHeader: true` for authenticated endpoints
- Use `passHeader: false` for public endpoints (login, register)

### When Adding Reusable Components

- Check `lib/presentation/components/` for existing components
- Follow existing component patterns (buttons, text fields, cards)
- Use app-wide constants from `lib/core/utils/` (colors, dimensions, strings)

### Best Practices

- **Never bypass SSL validation in production** (currently disabled in `main.dart` via MyHttpOverrides)
- **Move sensitive data to environment variables** (Google Maps API key, dev-token)
- **Use SharedPreferenceHelper constants** for all SharedPreferences keys
- **Follow GetX patterns** for state management - don't mix with other approaches
- **Update both Android and iOS configs** when changing package name or Firebase
- **Test on physical devices** for location, maps, and push notifications

## Configuration & Environment

### Environment Variables

File: `lib/environment.dart`

```dart
static const String appName = 'OVO RIDE DRIVER';
static const String version = '1.0.0';
static const String defaultLangCode = "en";
static const String baseCurrency = "\$";
static const String mapKey = "AIzaSyD46zrkUGAvi8RJ4C0xVAZygaH-yiP426I"; // Move to secure config
static const int otpResendSecond = 120;
static const String defaultCountryCode = 'US';
static const String defaultDialCode = '1';
```

### SharedPreferences Keys

All keys defined in `lib/core/helper/shared_preference_helper.dart`:
- `accessTokenKey` - Auth token
- `userIdKey` - User ID
- `fcmDeviceKey` - FCM device token
- `generalSettingKey` - App settings
- Plus 20+ more keys

### Firebase Setup

- Config: `lib/firebase_options.dart`
- Android: `android/app/google-services.json`
- iOS: Configured via CocoaPods

## Testing Requirements

**Before Testing:**
1. Backend API must be running
2. Firebase project configured
3. Google Maps API key active
4. Physical device or emulator with:
   - Location services enabled
   - Google Play Services (Android) or Apple Developer account (iOS)
   - Push notification permissions

**Test Scenarios:**
- Authentication flow (login, register, OTP)
- New ride acceptance and management
- Active ride tracking with live location
- Wallet deposits and withdrawals
- Scheduled rides CRUD operations
- Push notifications (foreground and background)
- Real-time updates via Pusher

## Known Issues & Production Considerations

1. **SSL Certificate Validation Disabled** - Remove `MyHttpOverrides` from `main.dart` for production
2. **Hardcoded API Keys** - Move Google Maps API key and dev-token to secure configuration
3. **Exposed Credentials** - Use environment variables or secure storage for sensitive data
4. **Default Country** - Configured for US; modify in `environment.dart` for other regions
5. **No Dark Mode** - Only light theme implemented in `lib/core/theme/light/light.dart`

## Additional Resources

- **Scheduled Rides Documentation:** `SCHEDULED_RIDES_README.md`
- **Flutter Documentation:** https://flutter.dev/docs
- **GetX Documentation:** https://pub.dev/packages/get
- **Firebase Flutter:** https://firebase.google.com/docs/flutter
- **Google Maps Flutter:** https://pub.dev/packages/google_maps_flutter

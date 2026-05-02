# BMS Campus Reporter (bms_report)

This is a Flutter application designed for BMS College Campus Problem Reporting.

## Tech Stack

### Frontend
* **Framework:** Flutter (Dart)
* **State Management:** Provider (`provider`)
* **UI & Animations:** Material Design, Google Fonts (`google_fonts`), and `flutter_animate` for fluid animations and a futuristic aesthetic.
* **Utilities:** `image_picker` (media uploads), `intl`, `timeago` (date formatting).

### Backend
* **Platform:** Firebase
* **Authentication:** Firebase Auth (`firebase_auth`)
* **Database:** Cloud Firestore (`cloud_firestore`) for real-time NoSQL data storage.
* **Storage:** Firebase Storage (`firebase_storage`) for storing uploaded images.

## Walkthrough & Getting Started

Follow these steps to set up the project, install dependencies, and run the application on your local desktop environment.

### Prerequisites

1. **Flutter SDK:** Ensure you have Flutter installed. Verify by running `flutter --version`. If not installed, follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install).
2. **Native Build Tools:** Because this app runs on the desktop, Flutter requires the native build tools for your specific operating system to compile the application:
   * **Windows:** You must install [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/) (Note: This is different from VS Code). During installation, make sure to select the **"Desktop development with C++"** workload.
   * **macOS:** You must install Xcode from the Mac App Store and run `sudo xcodebuild -license` to agree to the terms.
   * **Linux:** You will need `clang`, `cmake`, `ninja-build`, `pkg-config`, and `libgtk-3-dev`. (e.g., `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`)
3. **Desktop Support Enabled:** Ensure desktop support is enabled for your specific OS.
   * **Windows:** `flutter config --enable-windows-desktop`
   * **macOS:** `flutter config --enable-macos-desktop`
   * **Linux:** `flutter config --enable-linux-desktop`
### Installation Steps

1. **Navigate to the Project Directory**
   Open your terminal and navigate to the folder where you downloaded or cloned the repository:
   ```bash
   cd path/to/MAD-Lab-project-main
   ```

2. **Install Dependencies**
   Run the following command to download all necessary Dart and Flutter packages:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   The application requires Firebase to function. Make sure that the Firebase configuration files (e.g., `firebase_options.dart`, `google-services.json`) are correctly placed. If you are cloning this repository, the configuration might already be integrated, but if you are connecting your own Firebase project, use the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):
   ```bash
   flutterfire configure
   ```

4. **Run the Application on Desktop**
   To launch the application on your desktop, use the run command specific to your operating system:
   ```bash
   # For Windows
   flutter run -d windows
   
   # For macOS
   flutter run -d macos
   
   # For Linux
   flutter run -d linux
   ```
   *Note: You can also open the project in VS Code or Android Studio, select your desktop as the target device, and press Run/Debug.*

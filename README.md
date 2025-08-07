# CurrenSee Pro 💸


**CurrenSee Pro** is a comprehensive, feature-rich currency converter application built with Flutter. It provides real-time exchange rates, advanced analysis tools, and personalized alerts to keep you updated on market movements. With a seamless user experience, robust security features, and a handy home screen widget, CurrenSee Pro is your all-in-one tool for managing global currencies.

---


## ✨ Key Features

A list of the key features that make CurrenSee Pro a powerful currency tool:

- **Real-Time Currency Conversion:** Convert between 100+ global currencies with live exchange rates.
- **Live Rate List:** View all major currency rates against USD at a glance.
- **Target Price Alerts:** Set custom price alerts and receive instant push and email notifications when your target is met.
- **Advanced User Authentication:** Secure login/signup with Email/Password and Google Sign-In.
- **Biometric Lock:** Protect your app with advanced fingerprint or Face ID authentication that works reliably, even when the app is resumed from the background.
- **Currency News & Analysis:** Stay informed with the latest financial news and market trends.
- **World Clock:** Keep track of time across different financial centers.
- **Interactive Chat Bot:** Get quick answers and assistance with an integrated chat bot.
- **Home Screen Widget:** Convert currencies and view live rates directly from your home screen without opening the app.
- **Multi-Rate View:** Compare multiple currency pairs simultaneously.
- **Robust Backend:** Powered by Firebase for real-time data, authentication, and server-side notifications.
- **Smart Network Handling:** Smart connectivity checks to ensure the app works smoothly online and provides relevant information offline.

---

## 🚀 Tech Stack & Dependencies

- **Platform:** Flutter
- **Backend:** Firebase (Authentication, Cloud Firestore, Cloud Functions)
- **Key Plugins:**
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
  - `google_sign_in`
  - `http` for API calls
  - `flutter_local_notifications`, `home_widget`
  - `local_auth` for biometric authentication
  - `connectivity_plus` for network status
  - `shared_preferences` for local storage

---

## ⚙️ Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Flutter SDK
- Node.js and npm (for Firebase Functions)
- A code editor like VS Code or Android Studio
- Firebase CLI: `npm install -g firebase-tools`

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/Zain1098/CurrenSee.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd CurrenSee
    ```
3.  **Install Flutter dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Setup Firebase for the Flutter App:**
    - Go to the Firebase Console and create a new project.
    - Add an Android and/or iOS app to your Firebase project.
    - Follow the setup instructions to download the `google-services.json` file for Android and `GoogleService-Info.plist` for iOS.
    - Place `google-services.json` in the `android/app/` directory.
    - Place `GoogleService-Info.plist` in the `ios/Runner/` directory.
    - Enable **Authentication** (Email/Password and Google providers) and **Cloud Firestore**.

5.  **Setup Firebase Cloud Functions:**
    - Navigate to the `functions` directory: `cd functions`
    - Install npm dependencies: `npm install`
    - Authenticate with Firebase: `firebase login`
    - Configure your Firebase project: `firebase use YOUR_PROJECT_ID`
    - **Set up environment variables for email notifications:**
      ```sh
      # Replace with your Gmail and an App Password (https://myaccount.google.com/apppasswords)
      firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
      ```
    - Deploy the functions:
      ```sh
      firebase deploy --only functions
      ```

6.  **Run the app:**
    ```sh
    flutter run
    ```

---

## 🤝 How to Contribute

Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the Branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---


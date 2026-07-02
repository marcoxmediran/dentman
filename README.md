# DentMan

DentMan is a Flutter-based mobile application designed for dental clinics to manage patients, schedule appointments, track treatment histories, and customize the dentist roster.

---

## Getting Started

To run the project, ensure you have Flutter installed and configured on your machine.

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/marcoxmediran/dentman.git
    cd dentman
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

---

## Database Modes: Mock vs. Live Mode

DentMan supports two operating modes, toggled dynamically from the Developer panel on the Login Screen:

1.  **Offline Mock Mode (Default)**:
    *   Runs completely locally using a mock in-memory database.
    *   No external Firebase credentials required.
    *   Pre-seeded with demo patients, appointments, treatment records, and dentists.
    *   **Demo Credentials**:
        *   **Email**: `mock@email.com`
        *   **Password**: `mock123`
2.  **Live Firebase Mode**:
    *   Connects directly to Cloud Firestore and Firebase Authentication.
    *   Starts with clean, empty collections (ready for production/clinic use).
    *   Requires configuring your own Firebase project credentials.

---

## Configuring Your Own Firebase Project (For Developers)

To run in **Live Mode** or deploy your own instance of the application, follow these setup steps:

### 1. Initialize Firebase
Ensure you have the [Firebase CLI](https://firebase.google.com/docs/cli) installed.

1.  **Log in to Firebase**:
    ```bash
    firebase login
    ```
2.  **Install FlutterFire CLI**:
    ```bash
    dart pub global activate flutterfire_cli
    ```
3.  **Configure Firebase Options**:
    ```bash
    flutterfire configure
    ```

### 2. Set Up Cloud Firestore
Ensure Cloud Firestore is enabled in your Firebase project.

1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Navigate to **Firestore Database** and click **Create Database**.
3.  Choose between **Standard** or **Enterprise** and select your preferred location.

### 3. Deploy Security Rules
Deploy these rules to your Firebase project:
```bash
firebase deploy --only firestore:rules
```

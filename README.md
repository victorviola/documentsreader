# iProov Documents Reader

A secure document access platform powered by **iProov's Genuine Presence Assurance (GPA)** technology. This application eliminates the need for passwords by authenticating users through advanced **biometric facial verification**, ensuring a seamless and secure user experience.

The system architecture consists of:
- **Backend**: Built with **Python**, handling core logic and authentication processes. Utilizes **Microsoft SQL Server** for robust and secure data management.
- **Frontend**: Developed using **Flutter**, providing a cross-platform interface (currently tested only on **Android**).

At this stage, the application has been tested exclusively on Android devices, with ongoing development to expand platform support and enhance functionality.

## Backend Features

* Developed with **Python** and **FastAPI**
* Uses **HTTPS** with self-signed certificates
* Enables **GPA-based registration and login** without passwords
* Stores only **non-sensitive data**: email, name, and company
* Fully tested using **Postman** and a **Flutter-based Android app**

## ⚠️ Disclaimer

* Tested in a **local environment on Windows** using **self-signed certificates**
* Requires **network and firewall configuration** to allow Docker containers to be reached from mobile devices
* SMTP tested using **Gmail App Passwords**
* Backend was tested with Postman and Flutter app for enrollment and verification flows
* **Registration verification allows up to 3 facial attempts per email.** However, the same person could bypass this limit by registering with a different email address. This limitation could be improved by fingerprinting the device or combining with other identification methods.
* **UUID entropy:** On containerized environments, especially when multiple containers start from the same state, UUIDv4 generation may result in duplicates if the entropy pool isn't sufficiently randomized. Consider using an entropy seed mechanism or UUIDv7 when uniqueness is critical.

## Prerequisites

1. Edit the `docker-compose.yaml`:

   * Create a **DB password** and replace it in the placeholder {YOUR_PASS_HERE} - Must be a strong password (min 8 digits + numbers + special char).
   * The same password must be present in the `.env` file in the next step

2. Edit the `.env` file in `\DocumentsReaderServer`:

   * Edit and add your **iProov API key and secret**
   * Edit and add your **SMTP server** credentials
   * Edit password for the **database connection string**

3. ⚠️ **Attention** Generate a self-signed certificate (required for HTTPS):

```bash
openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.pem -days 365 -nodes
```

> **Place both `cert.pem` and `cert.key` inside the `\DocumentsReaderServer` folder**

4. Ensure that your Android device is on the **same local network** as your backend server

5. \[Optional] If you're using Gmail as your SMTP server:

   * Enable **2FA** on your Google account
   * Create an **App Password** and use it as the SMTP password in `.env`

6. On **Windows**, you may need to create a **firewall rule** to allow inbound traffic to port 8000 (Docker port forwarding)

## Running the Backend

Run the project using Docker Compose:

```bash
docker compose up --build
```

> This will start the backend and the SQL Server container, execute initial SQL scripts, and expose the backend on `https://localhost:8000`

## Quick Test

**Find your local network IP address**:
   - On your computer or server running the backend, open a terminal or command prompt.
   - Run `ipconfig` (Windows) or `ifconfig`/`ip addr` (Linux/Mac) to find the IPv4 address of your local network (e.g., `192.168.x.x`).
   - Ensure your Android device is connected to the same Wi-Fi network as the backend server.
   - The dockerfile of the server is setup to run in the port 8000
   - \[Optional]Open the app, navigate to **Settings** (top-right corner) on the home screen, and enter the **IP address of the backend** to establish connectivity.

Use `curl` to test the `/auth/register-email` endpoint:

```bash
curl --location 'https://localhost:8000/auth/register-email' \
--header 'Content-Type: application/json' \
--data-raw '{"email": "aaaa@bbb.com"}'
```

**There is a JSON collection in the root folder of this project.**

---

# Frontend

Welcome to the documentation for the Flutter-based mobile application.

The application is developed using **Flutter** and has been tested on **Android** devices. It serves as the frontend interface to interact with the backend, enabling users to register and log in without passwords, relying solely on **biometric authentication** and **GPA (Global Privacy Authentication)**. 

The app **does not store any user data** locally. Its primary purpose is to allow users to read documents after verifying their identity as a real person through biometric authentication.

## ⚠️ Disclaimer

- The APK provided has **not been signed** and is a **debug release** build.
- The app has only been tested on a **Redmi 10C** device running **Android 13**.
- The app is **not perfect** and has been tested to the extent possible. There is significant room for improvement, particularly in the user interface (UI).

## How to Run the App

**Important**: The app only works on **physical Android devices** and **will not function on Android emulators**.

### Option 1: Run from Source
1. Import the project (starting from the `/App` folder) into **Android Studio**.
2. Run `flutter pub get` in the terminal to install dependencies.
3. Ensure **Developer Options** and **USB Debugging** are enabled on your Android device.
4. Connect your device via USB and run `flutter run` to build and install the app.

### Option 2: Install the APK
1. Locate the APK in the `/releases_app` folder.
2. Transfer the APK to your Android device and install it manually (ensure **Install Unknown Apps** is enabled in your device settings).

### Important Setup
After launching the app, navigate to **Settings** (top-right corner) in the app's home screen and configure the **IP address of the backend** to ensure proper connectivity.

## Frontend Features

- **Registration**: Users can register using their email and facial verification to access documents.
- **Login**: Password-less login using email and biometric authentication.
- **Customization**:
  - Choose between **Dark Mode** and **Light Mode**.
  - Switch between **English** and **Portuguese** languages.
  - Configure backend settings and iProov service settings.
- **UX Assets**: The app includes UX assets proprietary to **iProov**.

## Contributing

This project is a work in progress, and contributions are welcome. If you'd like to contribute, please fork the repository, make your changes, and submit a pull request.

---

*Note*: This app is in active development, and I appreciate your feedback to help improve its functionality and user experience.

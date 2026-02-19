# HandSpeaks PRO

> **"Connecting Hands, Connecting Bharat"**

HandSpeaks PRO is a Flutter-based mobile application that bridges the communication gap between Indian Sign Language (ISL) users and people who do not know sign language. The app works in both directions — it can translate live hand gestures (captured by a Raspberry Pi camera) into readable text, and it can convert speech or text back into sign-language illustrations for the deaf community.

Developed as part of **Smart India Hackathon 2024**.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Flutter App Setup](#flutter-app-setup)
  - [Raspberry Pi Setup](#raspberry-pi-setup)
  - [Speech-to-Text Module Setup](#speech-to-text-module-setup)
- [App Screens](#app-screens)
- [Bluetooth Communication](#bluetooth-communication)
- [Configuration](#configuration)
- [Dependencies](#dependencies)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)
- [Future Enhancements](#future-enhancements)
- [License](#license)

---

## Features

### Sign → Abled (Deaf user speaks to hearing user)
- 📡 **Real-time hand gesture translation** via Raspberry Pi 5 + Pi Camera
- 🦾 **MediaPipe hand landmark extraction** — 21 keypoints per hand, up to 2 hands simultaneously
- 🔵 **Bluetooth auto-connect** — phone pairs automatically to the "Handspeaks" device
- 📝 **Raw output display** — shows recognised sign words as they stream in
- ✨ **Generated sentence output** — NLP-assembled readable sentences with animated transitions
- 🔊 **Speaker toggle** — enable/disable audio playback of translated sentences
- 🎮 **Device control panel** — toggle camera, speaker, ToF sensor, microphone, and LED from the app
- 📊 **Device health monitor** — live battery level and connection latency

### Abled → Sign (Hearing user speaks to deaf user)
- 🎤 **Speech-to-text conversion** powered by the [Deepgram](https://deepgram.com/) API
- 🌐 **Embedded React web app** rendered inside a Flutter WebView
- 🔐 **Secure API key storage** using `flutter_secure_storage` (never stored in plain text)

### General
- 🌙 **Glassmorphism UI** — frosted-glass cards with blur effects throughout
- 🔤 **Urbanist font** — full weight range (100–900) for crisp, modern typography
- 🎨 **Consistent theming** — custom colour palette and light theme
- 💫 **Splash screen** with fade + scale animation

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        HandSpeaks PRO                           │
│                                                                 │
│   ┌──────────────────────┐     ┌──────────────────────────┐    │
│   │   Raspberry Pi 5     │     │      Flutter App          │    │
│   │                      │     │                           │    │
│   │  Pi Camera           │     │  Splash → Selection       │    │
│   │      ↓               │     │       ↓          ↓        │    │
│   │  MediaPipe           │     │  Sign→Abled   Abled→Sign  │    │
│   │  (21 landmarks/hand) │     │  ┌─────────┐  ┌────────┐ │    │
│   │      ↓               │     │  │Translate│  │Speech  │ │    │
│   │  JSON Serialisation  │─BT──▶  │Connect  │  │to Text │ │    │
│   │  Bluetooth RFCOMM    │     │  │Illustr. │  │(WebView│ │    │
│   │  Channel 22          │     │  └─────────┘  └────────┘ │    │
│   └──────────────────────┘     └──────────────────────────┘    │
│                                                                 │
│          Speech-to-Text: React/TypeScript + Deepgram API        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
appv1/
│
├── lib/                          # Flutter Dart source code
│   ├── main.dart                 # App entry point
│   ├── bluetooth/
│   │   ├── bluetooth_handler.dart    # BT scan, auto-connect & device list UI
│   │   └── landmark_receiver.dart    # Live hand-landmark data receiver & canvas painter
│   ├── components/
│   │   └── frostedglass.dart         # Reusable frosted-glass card widget
│   ├── pages/
│   │   ├── Splash_page.dart          # Animated splash/loading screen
│   │   ├── Selection_page.dart       # Mode selection (Abled↔Sign)
│   │   ├── Sign_to_abled/
│   │   │   └── HomePage.dart         # Main tabbed home screen (Sign→Abled mode)
│   │   └── Abled_to_Sign/
│   │       ├── HomePage.dart         # Home screen (Abled→Sign mode)
│   │       └── SpeechToTextPage.dart # WebView wrapper for Deepgram speech-to-text
│   ├── tabs/
│   │   ├── home_tab.dart             # Translate tab (raw output + generated sentences)
│   │   ├── device_tab.dart           # Connect/control the Handspeaks hardware
│   │   └── illustration_tab.dart     # Session history / ISL illustration viewer
│   └── theme/
│       ├── app_colors.dart           # Central colour constants
│       └── app_theme.dart            # MaterialApp light theme
│
├── assets/
│   ├── fonts/                    # Urbanist font (weights 100–900)
│   └── web/                      # Pre-built React speech-to-text app (index.html + assets)
│
├── raspberry_pi/                 # Raspberry Pi Python scripts
│   ├── mp_bluetooth_sender.py    # Full version (with GPIO control)
│   ├── mp_bluetooth_simple.py    # Simplified testing version (recommended first)
│   ├── requirements.txt          # Python pip dependencies
│   ├── README.md                 # Detailed Pi setup documentation
│   ├── QUICKSTART.md             # 5-minute quick-start guide
│   └── PROJECT_SUMMARY.md        # Feature summary and data-format reference
│
├── speech-to-text/               # React/TypeScript source for speech-to-text module
│   ├── src/                      # App.jsx, components, styles
│   ├── package.json
│   └── vite.config.js
│
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── test/                         # Flutter widget tests
├── pubspec.yaml                  # Flutter dependencies & asset declarations
└── analysis_options.yaml         # Dart linter configuration
```

---

## Getting Started

### Prerequisites

| Tool | Minimum Version | Notes |
|------|----------------|-------|
| Flutter SDK | 3.9.2 | `flutter --version` |
| Dart SDK | bundled with Flutter | |
| Android Studio / VS Code | any recent | Flutter + Dart plugins required |
| Physical Android device | Android 6.0+ | Bluetooth Classic required |
| Raspberry Pi 5 | — | With Pi Camera Module |
| Python | 3.9+ | For the Pi scripts |
| Node.js | 18+ | Only if rebuilding the speech-to-text web app |

---

### Flutter App Setup

#### 1. Clone the repository

```bash
git clone https://github.com/Shrinidhi857/appv1.git
cd appv1
```

#### 2. Install Flutter dependencies

```bash
flutter pub get
```

#### 3. Connect your Android device

Enable **USB Debugging** on your phone:
- Settings → About Phone → tap *Build Number* 7 times to unlock Developer Options
- Settings → Developer Options → enable *USB Debugging*

Connect via USB and confirm the device is detected:

```bash
flutter devices
```

#### 4. Run the app

```bash
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

#### 5. Android permissions

The app will automatically request the following permissions at runtime:
- **Bluetooth** — for connecting to the Handspeaks device
- **Bluetooth Scan / Connect** (Android 12+) — Nearby Devices permission
- **Location** — required by Android for Bluetooth Classic discovery
- **Microphone** — for the speech-to-text feature

If any permission is denied, go to:  
*Android Settings → Apps → HandSpeaks → Permissions* and enable them manually.

---

### Raspberry Pi Setup

The Raspberry Pi acts as the hardware sensor unit. It captures video from the Pi Camera, uses **MediaPipe** to detect hand landmarks in real time, and streams the data to the phone over **Bluetooth Classic (RFCOMM, channel 22)**.

#### 1. Hardware requirements

- Raspberry Pi 5 (or Pi 4)
- Pi Camera Module (v2 or v3)
- Bluetooth enabled (built-in on Pi 4/5)

#### 2. Enable camera and Bluetooth

```bash
sudo raspi-config
# Interface Options → Camera → Enable
# Interface Options → Bluetooth → Enable
sudo reboot
```

#### 3. Install Python dependencies

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install python3-pip python3-opencv python3-picamera2 -y
pip3 install mediapipe pybluez RPi.GPIO numpy
```

Or use the provided requirements file:

```bash
pip3 install -r raspberry_pi/requirements.txt
```

#### 4. Copy the script to the Pi

```bash
scp raspberry_pi/mp_bluetooth_simple.py pi@<pi_ip_address>:~/
```

#### 5. Run the script

```bash
python3 mp_bluetooth_simple.py
```

Expected startup output:

```
[1/4] Initializing MediaPipe...      ✓ MediaPipe initialized
[2/4] Initializing Camera...         ✓ Camera initialized (640x480)
[3/4] Setting up Bluetooth server... ✓ Bluetooth server ready on channel 22
                                     ✓ Device name: 'Handspeaks'
[4/4] Waiting for Flutter app to connect...
```

Leave this running. The Flutter app will auto-discover and connect to it.

#### Bluetooth data format

Each frame sends a newline-delimited JSON packet:

```json
{
  "timestamp": 1702345678.123,
  "hands_count": 2,
  "hands": [
    {
      "hand_index": 0,
      "label": "Right",
      "confidence": 0.9876,
      "landmarks": [
        { "x": 0.512, "y": 0.456, "z": 0.012 },
        "... (21 landmarks total, index 0–20)"
      ],
      "features": {
        "thumb_distance": 0.234,
        "index_distance": 0.345,
        "hand_size": 0.456
      }
    }
  ]
}
```

**Landmark index map:**

| Index | Joint |
|-------|-------|
| 0 | Wrist |
| 1–4 | Thumb (base → tip) |
| 5–8 | Index finger |
| 9–12 | Middle finger |
| 13–16 | Ring finger |
| 17–20 | Pinky finger |

---

### Speech-to-Text Module Setup

The speech-to-text feature is a **React + TypeScript** web app bundled into the Flutter `assets/web/` folder and rendered through a `WebViewWidget`.

It uses the [Deepgram](https://deepgram.com/) real-time speech-recognition API.

#### Obtaining a Deepgram API key

1. Sign up at [https://deepgram.com](https://deepgram.com) (free tier available)
2. Create a new project and generate an API key

#### Entering the API key in the app

1. Open the app and select **Abled → Sign** mode
2. Navigate to the **Speech to Text** screen
3. A dialog will appear automatically if no key is stored yet
4. Paste your Deepgram API key and tap **Save**

The key is stored securely using `flutter_secure_storage` and never exposed in plain text.

You can update the key at any time via the ⚙️ settings icon in the top-right corner of the Speech to Text screen.

#### (Optional) Rebuilding the web module from source

```bash
cd speech-to-text
npm install
npm run build
# Copy the dist/ output to assets/web/
```

---

## App Screens

### Splash Screen
Animated fade-in and scale transition showing the **HandSpeaks PRO** logo and tagline "Connecting Hands, Connecting Bharat". Navigates automatically to the Selection screen after 3 seconds.

### Selection Screen
Choose your communication direction:
- **Abled → Sign** — hearing person communicates with a deaf/mute person
- **Sign → Abled** — deaf/mute person communicates with a hearing person

Tap a card to select it (highlighted with a green glow), then tap **Continue**.

### Sign → Abled — Home Screen (3 tabs)

| Tab | Icon | Description |
|-----|------|-------------|
| **Translate** | 🔄 | Shows *Raw Output* (individual sign words streaming in) and *Generated Output* (assembled sentences). Includes a link to the Speech-to-Text page. |
| **Connect** | 🔵 | Scan for and connect to the Handspeaks Raspberry Pi device. Shows device health (battery, latency) and control toggles once connected. |
| **Illustration** | 🤟 | Session history — shows past translation sessions. |

### Device Control Panel (Connect tab — connected state)
When connected to the Raspberry Pi, you can toggle:
- 📷 **Camera** — enable/disable the Pi camera
- 🔊 **Speaker** — enable/disable audio output on the Pi
- 📡 **ToF Sensor** — enable/disable the Time-of-Flight sensor
- 🎤 **Microphone** — enable/disable the microphone
- 💡 **LED Indicator** — toggle the status LED

Each toggle sends a command string (e.g., `CAMERA:ON`) to the Pi over Bluetooth.

### Speech-to-Text Screen (Abled → Sign)
A full-screen **WebView** that loads the embedded React app. Tap the microphone button to start listening; Deepgram transcribes speech in real time.

---

## Bluetooth Communication

The app uses `flutter_bluetooth_serial` for **Bluetooth Classic (SPP/RFCOMM)** communication with the Raspberry Pi.

### Auto-connect flow

1. App starts scanning for Bluetooth devices
2. When a device whose name contains `"handspeaks"` (case-insensitive) is found, the app stops scanning and connects automatically
3. If the device is not yet bonded (paired), the app initiates bonding first
4. After connecting, landmark data is received as a continuous newline-delimited JSON stream

### Manual connection

If auto-connect does not trigger:
1. Open the **Connect** tab
2. Tap **Search for Device**
3. Wait for the device list to populate
4. Tap the **Handspeaks** device to connect manually

---

## Configuration

### Python script (`raspberry_pi/mp_bluetooth_sender.py`)

```python
DEVICE_NAME    = "Handspeaks"  # Must match name the Flutter app scans for
BLUETOOTH_PORT = 22            # RFCOMM channel (1–30)
GPIO_PIN       = 26            # GPIO pin for status LED (full version only)

# MediaPipe tuning
min_detection_confidence = 0.7  # Lower = easier to detect, more false positives
min_tracking_confidence  = 0.5  # Lower = smoother tracking, less stable
max_num_hands            = 2    # Maximum simultaneous hands (1 or 2)

send_interval = 3              # Send data every N frames (lower = higher data rate)
```

### Flutter app

No additional configuration files are needed. The app reads from `pubspec.yaml` for assets and fonts.

To change the Bluetooth device name it scans for, search for `'handspeaks'` in:
- `lib/bluetooth/bluetooth_handler.dart`
- `lib/tabs/device_tab.dart`

---

## Dependencies

### Flutter (pubspec.yaml)

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bluetooth_serial` | ^0.4.0 | Bluetooth Classic (SPP) communication |
| `flutter_blue_plus` | ^2.0.2 | Bluetooth LE (future use) |
| `webview_flutter` | ^4.4.2 | Embeds the React speech-to-text app |
| `flutter_secure_storage` | ^9.0.0 | Secure API key storage |
| `google_fonts` | ^6.3.3 | Extended font support (Urbanist, Outfit) |
| `glass` | ^2.0.0+2 | Glassmorphism / frosted-glass effects |
| `permission_handler` | ^12.0.1 | Runtime permission requests |
| `cupertino_icons` | ^1.0.8 | iOS-style icon set |

### Python (Raspberry Pi)

| Package | Version | Purpose |
|---------|---------|---------|
| `mediapipe` | ≥0.10.0 | Hand landmark detection |
| `opencv-python` | ≥4.8.0 | Image processing |
| `picamera2` | ≥0.3.12 | Pi Camera interface |
| `pybluez` | ≥0.30 | Bluetooth RFCOMM server |
| `RPi.GPIO` | ≥0.7.1 | GPIO pin control |
| `numpy` | ≥1.24.0 | Numerical operations |

---

## Troubleshooting

### Flutter / Android

| Issue | Fix |
|-------|-----|
| Bluetooth permission denied | Settings → Apps → HandSpeaks → Permissions → enable Nearby Devices & Location |
| App cannot find device | Ensure the Pi script is running *before* scanning; both Bluetooth radios must be on |
| Connection timeout | Restart Bluetooth on both devices; try manual connection |
| No data after connecting | Ensure hands are visible in the camera frame; check Pi terminal for errors |
| WebView blank / error | Check internet connectivity; verify the Deepgram API key is correct |
| `flutter pub get` fails | Run `flutter clean` then `flutter pub get` again |

### Raspberry Pi

| Issue | Fix |
|-------|-----|
| Camera not detected | Run `vcgencmd get_camera`; if not `detected=1`, re-enable via `raspi-config` and reboot |
| `pybluez` install fails | `sudo apt-get install libbluetooth-dev` then `pip3 install pybluez` |
| `picamera2` import error | `sudo apt-get install python3-picamera2` |
| Bluetooth service not running | `sudo systemctl restart bluetooth` |
| No hands detected | Improve lighting; keep hand fully in frame; lower `min_detection_confidence` |

---

## Performance

| Metric | Value |
|--------|-------|
| Camera resolution | 640 × 480 (configurable) |
| Pi frame rate | ~30 FPS |
| Detection latency | 30–50 ms |
| Bluetooth latency | 50–100 ms |
| End-to-end latency | < 150 ms |
| Data throughput | 10–20 KB/s |
| Max simultaneous hands | 2 |
| Detection confidence | > 70 % (clear visibility) |

---

## Future Enhancements

- [ ] Gesture recognition model (classify ISL alphabets and common words)
- [ ] Hand pose classification with on-device ML
- [ ] Session recording and playback
- [ ] 3D hand skeleton visualisation
- [ ] WebSocket alternative (local Wi-Fi) for lower latency
- [ ] Binary data format to reduce packet size
- [ ] iOS support (pending `flutter_bluetooth_serial` update)
- [ ] Multi-device connection support
- [ ] Offline speech-to-text fallback
- [ ] Text-to-sign illustration animation

---

## License

This project was developed for **Smart India Hackathon 2024**.

**Technologies used:**
- [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) — Google
- [MediaPipe](https://mediapipe.dev/) — Google
- [Picamera2](https://github.com/raspberrypi/picamera2) — Raspberry Pi Foundation
- [PyBluez](https://github.com/pybluez/pybluez) — Open source
- [Deepgram](https://deepgram.com/) — Speech recognition API
- [React](https://react.dev/) & [Vite](https://vitejs.dev/) — Web tooling

---

*For hardware-specific setup details, see [`raspberry_pi/README.md`](raspberry_pi/README.md) and [`raspberry_pi/QUICKSTART.md`](raspberry_pi/QUICKSTART.md).*

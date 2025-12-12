# HandSpeaks - Setup Instructions

## 📋 Quick Setup Checklist

### 1. Flutter App Setup

```bash
cd appv1
flutter pub get
```

**Key Files Locations:**
- `lib/landmark_bus.dart` - Shared singleton ✅
- `lib/bluetooth/landmark_receiver.dart` - Data models ✅  
- `lib/tabs/device_tab.dart` - WebSocket + HTTP polling ✅
- `lib/bluetooth/bluetooth_handler.dart` - Optional standalone page ✅
- `lib/components/glb_hand_mapping_widget.dart` - 3D model subscriber ✅

### 2. Configure Raspberry Pi IP Address

**Option A: Runtime Configuration (Recommended)**
- Open the app → Device Tab
- Enter your RPi IP in the text field
- Tap Connect

**Option B: Code Configuration**
Edit `lib/tabs/device_tab.dart` line 23:
```dart
static const String defaultRPI_IP = "YOUR_RPI_IP_HERE"; // <-- CHANGE THIS
```

### 3. Find Your Raspberry Pi IP
On Raspberry Pi terminal:
```bash
hostname -I
```
Example output: `192.168.1.150`

### 4. Raspberry Pi Server Setup

**Install Dependencies:**
```bash
pip3 install websockets flask mediapipe opencv-python picamera2
```

**Option A: WebSocket Server (Recommended - Real-time)**
```bash
cd raspberry_pi
python3 websocket_server.py
```
Expected output:
```
WebSocket server listening on ws://0.0.0.0:8765
```

**Option B: HTTP Polling Server (Alternative)**
```bash
cd raspberry_pi  
python3 http_api.py
```
Expected output:
```
 * Running on http://0.0.0.0:5000
```

### 5. Android Configuration (Local Testing)

For `ws://` or `http://` on Android 9+, edit:
`android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
android:usesCleartextTraffic="true"
```

### 6. Run the App

```bash
# List devices
flutter devices

# Run on device
flutter run -d <device-id>

# Or simply
flutter run
```

### 7. Connect and Test

**In Device Tab:**
1. Enter RPi IP address
2. Choose mode:
   - **WebSocket** (default) - Best for real-time streaming
   - **HTTP Polling** - Fallback option
3. Tap **Connect**
4. Wait for green status
5. Tap **Start** to begin streaming

**Expected Behavior:**
- Status: "Connected via WS to 192.168.1.XXX"
- Landmark data starts flowing
- Switch to Illustration Tab to see 3D model move

---

## 🔧 Troubleshooting

### Connection Failed
- Verify both devices on same WiFi network
- Check RPi IP with `hostname -I`
- Test connectivity: `ping <rpi-ip>` from phone (use Termux)

### Firewall Issues (Raspberry Pi)
```bash
sudo ufw allow 8765  # WebSocket
sudo ufw allow 5000  # HTTP
sudo ufw status
```

### WebSocket Not Connecting
```bash
# Test from PC
wscat -c ws://<rpi-ip>:8765

# Install wscat if needed
npm install -g wscat
```

### HTTP Polling Not Working
```bash
# Test endpoint
curl http://<rpi-ip>:5000/landmarks
```

### No Landmarks Visible
- Check `raspberry_pi/websocket_server.py` is running
- Verify camera is connected to RPi:
```bash
libcamera-hello
```

---

## 📊 Architecture Overview

```
Flutter App (Device Tab)
    ↓ WebSocket / HTTP
Raspberry Pi Server
    ↓ landmarkBus.processPayload()
LandmarkReceiver (Singleton)
    ↓ Broadcast Stream
├── Illustration Tab (3D Model)
├── GLBHandMappingWidget
└── Other Tabs (Future features)
```

---

## 🎓 For Judges - Quick Demo

### Prerequisites (5 minutes before demo)
1. RPi5 powered on, connected to WiFi
2. Server running: `python3 websocket_server.py`
3. Flutter app installed on phone
4. Note RPi IP address

### Demo Steps (3 minutes)
1. **Launch App**: Open HandSpeaks
2. **Device Tab**: Enter RPi IP → Connect
3. **Show Connection**: Green status, LIVE indicator
4. **Illustration Tab**: Toggle 3D model ON
5. **Perform Gestures**: Wave hand, show tracking accuracy
6. **Highlight Features**: 
   - Real-time latency (<65ms)
   - 21-point landmark tracking
   - Dual mode support (WebSocket/HTTP)

---

## 📦 Dependencies Used

**Flutter Packages:**
- `web_socket_channel: ^3.0.1` - WebSocket communication
- `http: ^1.2.2` - HTTP polling fallback
- `webview_flutter: ^4.4.2` - 3D model rendering
- `vector_math: ^2.1.4` - 3D transformations
- `flutter_bluetooth_serial: ^0.4.0` - Legacy support

**Raspberry Pi Packages:**
- `websockets` - WebSocket server
- `flask` - HTTP REST API
- `mediapipe` - Hand tracking
- `opencv-python` - Image processing
- `picamera2` - Camera interface

---

## 🚀 Production Deployment

**For Production Use:**
1. Replace `ws://` with `wss://` (secure WebSocket)
2. Use TLS certificates on Raspberry Pi
3. Remove `android:usesCleartextTraffic="true"`
4. Implement authentication tokens
5. Add error recovery mechanisms

---

## 📞 Support

**Common Issues:**
- ❓ Connection timeout → Check firewall and network
- ❓ Camera not detected → Run `raspistill -o test.jpg`
- ❓ High latency → Reduce resolution or frame rate
- ❓ App crashes → Check `flutter doctor` and logs

**Debug Logs:**
```bash
# Flutter app
flutter run --verbose

# Python server
python3 websocket_server.py  # Watch terminal output
```

---

**Built for Smart India Hackathon 2025** 🏆

# 🎯 HandSpeaks Implementation Guide

## Your Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WiFi Network (Same Network)               │
│                                                              │
│  ┌──────────────────┐                 ┌──────────────────┐  │
│  │  Raspberry Pi 5  │  <── WiFi ──>  │  Flutter App     │  │
│  │                  │                 │  (Mobile)        │  │
│  │  Landmark Stream │                 │                  │  │
│  │  API Port 8000   │                 │  HTTP Polling    │  │
│  └──────────────────┘                 └──────────────────┘  │
│         ▲                                      │             │
│         │                                      │             │
│   [MediaPipe]                          [3D Visualization]    │
│   21 landmarks                         breen.glb model       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📡 Why This Setup?

### **Single HTTP API Approach (Recommended for You)**

**Your RPi runs ONE server:**
- **`http_api.py`** on port **8000**
- Serves landmark data via `GET /landmarks`
- Receives commands via `POST /command`

**Flutter app:**
- Connects over **WiFi** (same network as RPi)
- Polls `http://192.168.x.x:8000/landmarks` every 250ms
- Sends data to `landmarkBus` → 3D visualization

**Why NOT WebSocket?**
- ✅ Simpler - no persistent connection management
- ✅ More reliable - auto-reconnects on every poll
- ✅ Easier to debug - test with browser
- ✅ Works with your existing port 8000 API

---

## 🗑️ Files You DON'T Need

Since you're using **HTTP only on port 8000**, you can **ignore/delete**:

1. ❌ `raspberry_pi/websocket_server.py` - Not needed (WebSocket approach)
2. ❌ `lib/bluetooth/bluetooth_handler.dart` - Not needed (Bluetooth approach)

**Keep only:**
- ✅ `raspberry_pi/http_api.py` - Your landmark stream server (port 8000)
- ✅ `lib/tabs/device_tab.dart` - HTTP polling client
- ✅ `lib/tabs/illustration_tab.dart` - 3D visualization
- ✅ `lib/components/glb_hand_mapping_widget.dart` - 3D model renderer
- ✅ `lib/landmark_bus.dart` - Shared data bus
- ✅ `lib/bluetooth/landmark_receiver.dart` - Data models only

---

## 🚀 Complete Setup Steps

### **Step 1: Configure RPi IP Address**

**File:** `lib/tabs/device_tab.dart` (Line 23)

```dart
static const String defaultRPI_IP = "192.168.1.100"; // <-- Change to your RPi's WiFi IP
```

**How to find RPi IP:**
```bash
# On Raspberry Pi terminal:
hostname -I
# Output example: 192.168.1.150
```

---

### **Step 2: Start RPi Landmark Stream API**

**On Raspberry Pi:**

```bash
cd raspberry_pi

# Install dependencies (first time only)
pip3 install flask mediapipe opencv-python picamera2 numpy

# Start the landmark stream server
python3 http_api.py
```

**Expected output:**
```
 * Serving Flask app 'http_api'
 * Running on http://0.0.0.0:8000
 * Press CTRL+C to quit
```

**Test it works:**
```bash
# On RPi or from another device:
curl http://localhost:8000/landmarks
```

**Expected response:**
```json
{
  "timestamp": 1234567890.123,
  "hands_count": 1,
  "hands": [{
    "hand_index": 0,
    "label": "Left",
    "confidence": 0.95,
    "landmarks": [
      [0.5, 0.3, -0.02],
      [0.52, 0.28, -0.01],
      // ... 21 landmarks total
    ]
  }]
}
```

---

### **Step 3: Integrate MediaPipe on RPi**

**File:** `raspberry_pi/http_api.py`

Replace the `update_payload()` function with real MediaPipe code:

```python
import cv2
import mediapipe as mp
from picamera2 import Picamera2

# Initialize MediaPipe
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Initialize camera
picam2 = Picamera2()
picam2.configure(picam2.create_preview_configuration(main={"size": (640, 480)}))
picam2.start()

def update_payload():
    """Get real landmarks from camera"""
    global latest_payload
    
    # Capture frame
    frame = picam2.capture_array()
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Process with MediaPipe
    results = hands.process(frame_rgb)
    
    hands_list = []
    if results.multi_hand_landmarks:
        for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
            # Get hand label (Left/Right)
            hand_label = results.multi_handedness[idx].classification[0].label
            confidence = results.multi_handedness[idx].classification[0].score
            
            # Extract 21 landmarks
            landmarks = []
            for landmark in hand_landmarks.landmark:
                landmarks.append({
                    'x': landmark.x,
                    'y': landmark.y,
                    'z': landmark.z
                })
            
            hands_list.append({
                'hand_index': idx,
                'label': hand_label,
                'confidence': confidence,
                'landmarks': landmarks
            })
    
    latest_payload['timestamp'] = time.time()
    latest_payload['hands_count'] = len(hands_list)
    latest_payload['hands'] = hands_list
```

---

### **Step 4: Run Flutter App**

**On your computer (with phone connected):**

```bash
cd appv1

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

**Or build APK:**
```bash
flutter build apk
# Install the APK from: build/app/outputs/flutter-apk/app-release.apk
```

---

### **Step 5: Connect in App**

1. Open app → Go to **Device tab**
2. Enter RPi IP (e.g., `192.168.1.150`)
3. Click **Connect**
4. Status should show: **"✓ Receiving landmarks from RPi"**
5. Go to **Illustration tab**
6. You should see: **"🟢 LIVE - 1 hand(s) detected"**
7. 3D hand model should move with your hand!

---

## 🔧 How It Works (Data Flow)

### **1. RPi Captures Hand**
```
PiCamera2 → Frame → MediaPipe → 21 Landmarks → Flask API (port 8000)
```

### **2. Flutter Polls for Data**
```dart
// device_tab.dart (every 250ms)
http.get('http://192.168.x.x:8000/landmarks')
  → Parse JSON
  → landmarkBus.processPayload(data)
```

### **3. Data Broadcasts to Subscribers**
```dart
// landmark_bus.dart (singleton)
landmarkBus.stream → StreamController → broadcast
```

### **4. 3D Model Updates**
```dart
// illustration_tab.dart
landmarkBus.stream.listen() 
  → GlbHandMappingWidget
  → WebView (model_viewer.html)
  → breen.glb animates
```

---

## 📊 API Endpoint Details

### **GET /landmarks**
**Returns:** Current hand landmark data

**Response Format:**
```json
{
  "timestamp": 1734000000.123,
  "hands_count": 2,
  "hands": [
    {
      "hand_index": 0,
      "label": "Right",
      "confidence": 0.98,
      "landmarks": [
        {"x": 0.5, "y": 0.3, "z": -0.02},  // Wrist
        {"x": 0.52, "y": 0.28, "z": -0.01}, // Thumb CMC
        // ... 19 more landmarks
      ]
    },
    {
      "hand_index": 1,
      "label": "Left",
      "confidence": 0.95,
      "landmarks": [ /* 21 landmarks */ ]
    }
  ]
}
```

### **POST /command**
**Sends:** Control commands to RPi

**Request Format:**
```json
{
  "command": "start"  // or "stop", "CAMERA:ON", etc.
}
```

**Response:**
```json
{
  "status": "ok",
  "command": "start"
}
```

---

## 🐛 Troubleshooting

### **"Polling error" in app**
✅ Check RPi server is running: `python3 http_api.py`  
✅ Verify port 8000 is open (not blocked by firewall)  
✅ Test with browser: `http://192.168.x.x:8000/landmarks`

### **"Connection refused"**
✅ Both devices on same WiFi network  
✅ RPi IP correct in device_tab.dart (line 23)  
✅ No VPN or network isolation enabled

### **"No landmarks yet" in Illustration tab**
✅ Connect in Device tab first  
✅ Click "Start" button  
✅ Verify camera working on RPi  
✅ Check MediaPipe integrated (not using placeholder)

### **3D model not moving**
✅ Wait 2-3 seconds for WebView initialization  
✅ Check at least 21 landmarks detected  
✅ Verify `assets/models/breen.glb` exists  
✅ Run `flutter pub get` to load assets

### **High latency (>200ms)**
✅ Reduce polling interval in device_tab.dart:
```dart
Duration(milliseconds: 100) // Faster polling
```
✅ Use 5GHz WiFi instead of 2.4GHz  
✅ Reduce MediaPipe processing on RPi

---

## ⚙️ Configuration Options

### **Adjust Polling Speed**

**File:** `lib/tabs/device_tab.dart` (Line 73)

```dart
// Faster (10 Hz, more network usage)
void _startPolling({Duration interval = const Duration(milliseconds: 100)})

// Current (4 Hz, balanced)
void _startPolling({Duration interval = const Duration(milliseconds: 250)})

// Slower (2 Hz, less network usage)
void _startPolling({Duration interval = const Duration(milliseconds: 500)})
```

### **Change Port**

**Flutter:** `device_tab.dart` line 24
```dart
static const int API_PORT = 8000; // Change if needed
```

**Python:** `http_api.py` last line
```python
app.run(host='0.0.0.0', port=8000)  # Change if needed
```

---

## 📈 Performance Expectations

| Metric | Value |
|--------|-------|
| **Polling Rate** | 4 Hz (250ms) |
| **Landmark Detection** | 20-30 FPS (RPi) |
| **Network Latency** | 50-100ms (WiFi) |
| **End-to-End Delay** | 150-200ms |
| **3D Frame Rate** | 20-30 FPS |
| **Network Usage** | ~20 KB/s |

---

## 🎓 Summary for Your Setup

### **What You Have:**
- ✅ Raspberry Pi 5 with camera
- ✅ MediaPipe hand tracking (21 landmarks)
- ✅ Flask API on port 8000
- ✅ WiFi connection (same network)
- ✅ Flutter app with 3D visualization

### **How It Works:**
1. RPi runs `http_api.py` on port 8000
2. Flutter polls `/landmarks` every 250ms over WiFi
3. Data flows through `landmarkBus` (singleton)
4. 3D hand model updates in real-time
5. Commands sent back via `POST /command`

### **Key Files:**
- `device_tab.dart` - Connection & polling (update IP line 23)
- `http_api.py` - Landmark stream API (integrate MediaPipe)
- `illustration_tab.dart` - 3D visualization
- `glb_hand_mapping_widget.dart` - 3D model renderer

### **No WebSocket Needed:**
- ✅ HTTP polling is simpler and reliable
- ✅ Works over WiFi (same as WebSocket)
- ✅ Easier to debug and test
- ✅ Good enough for 4 Hz updates

---

**Ready to test!** Start RPi server → Update IP → Run Flutter app → Connect → See live 3D tracking 🚀

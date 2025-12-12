# 🚀 WebSocket Connection Setup - Port 8000

## ✅ Configuration Complete!

Your Flutter app is now configured to connect via **WebSocket** to your RPi at:

```
ws://10.100.169.47:8000
```

---

## 📡 Current Setup

### **Flutter App (device_tab.dart)**
- ✅ IP Address: `10.100.169.47`
- ✅ Protocol: **WebSocket** (ws://)
- ✅ Port: **8000**
- ✅ Auto-reconnect: Yes (with ping/pong)
- ✅ Data format: Supports both wrapped and direct JSON

### **Raspberry Pi Server**
- ✅ File: `raspberry_pi/websocket_server.py`
- ✅ Port: **8000**
- ✅ Protocol: WebSocket
- ✅ Broadcasts landmarks at ~20 FPS

---

## 🚀 How to Start

### **On Raspberry Pi:**

```bash
# Navigate to your project
cd /path/to/your/project/raspberry_pi

# Install dependencies (first time only)
pip3 install websockets

# Start the WebSocket server
python3 websocket_server.py
```

**Expected output:**
```
WebSocket server listening on ws://0.0.0.0:8000
Flutter should connect to: ws://10.100.169.47:8000
```

### **On Flutter App:**

```bash
# Navigate to Flutter project
cd appv1

# Make sure dependencies are installed
flutter pub get

# Run the app
flutter run
```

**In the app:**
1. Go to **Device tab**
2. IP is pre-filled: `10.100.169.47`
3. Click **"Connect"**
4. Status will show: **"✓ Connected via WebSocket to 10.100.169.47:8000"**
5. Go to **Illustration tab** to see 3D visualization

---

## 📊 Message Formats Supported

### **Format 1: Wrapped (with type/payload)**
```json
{
  "type": "LANDMARKS",
  "payload": {
    "timestamp": 1234567890.123,
    "hands_count": 1,
    "hands": [
      {
        "hand_index": 0,
        "label": "Right",
        "confidence": 0.95,
        "landmarks": [
          {"x": 0.5, "y": 0.3, "z": -0.02},
          // ... 21 landmarks
        ]
      }
    ]
  }
}
```

### **Format 2: Direct (unwrapped)**
```json
{
  "timestamp": 1234567890.123,
  "hands_count": 1,
  "hands": [
    {
      "hand_index": 0,
      "label": "Right",
      "confidence": 0.95,
      "landmarks": [
        {"x": 0.5, "y": 0.3, "z": -0.02},
        // ... 21 landmarks
      ]
    }
  ]
}
```

**Both formats work!** The Flutter app will detect and handle both automatically.

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    WiFi Network                         │
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  Raspberry Pi    │◄────────►│  Flutter App     │    │
│  │                  │ WebSocket│                  │    │
│  │  Port 8000       │  ws://   │  Auto-connect    │    │
│  │  (Server)        │          │  + Ping/Pong     │    │
│  └────────┬─────────┘         └────────┬─────────┘    │
│           │                            │               │
│           ▼                            ▼               │
│     MediaPipe                    3D Hand Model         │
│   (21 landmarks)                 (breen.glb)           │
└─────────────────────────────────────────────────────────┘
```

### **Connection Flow:**

1. **RPi starts WebSocket server** on port 8000
2. **Flutter connects** to `ws://10.100.169.47:8000`
3. **Server sends WELCOME** message
4. **Server broadcasts landmarks** ~20 times/second
5. **Flutter receives** → `landmarkBus` → 3D visualization
6. **Flutter sends PING** every 10 seconds (keepalive)
7. **Server responds PONG** (connection stays alive)

---

## 🎮 Commands

### **From Flutter to RPi:**

Flutter can send commands via WebSocket:

```json
{
  "type": "COMMAND",
  "payload": "start"  // or "stop", "CAMERA:ON", etc.
}
```

**In the app:**
- Tap device control buttons (Camera, Speaker, etc.)
- Commands sent automatically via WebSocket

### **Server-Side Handling:**

Update `websocket_server.py` to handle commands:

```python
async def handler(ws):
    async for msg in ws:
        data = json.loads(msg)
        t = data.get('type')
        p = data.get('payload')
        
        if t == 'COMMAND':
            if p == 'start':
                # Start camera/processing
                pass
            elif p == 'stop':
                # Stop camera/processing
                pass
```

---

## 🐛 Troubleshooting

### **"WebSocket connection failed" in app**

✅ Check RPi server is running:
```bash
ps aux | grep websocket_server
```

✅ Test WebSocket manually:
```bash
# Install wscat if needed
npm install -g wscat

# Connect to server
wscat -c ws://10.100.169.47:8000
```

✅ Check firewall:
```bash
# On RPi
sudo ufw allow 8000
# or
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
```

### **"Connection closed" repeatedly**

✅ Check RPi logs for errors
✅ Verify WiFi connection stable
✅ Ensure no other service using port 8000:
```bash
sudo netstat -tulpn | grep 8000
```

### **"No landmarks yet" in app**

✅ Verify server is broadcasting landmarks
✅ Check message format matches expected structure
✅ Look for parsing errors in Flutter debug console

---

## 🔧 Test Commands

### **Test WebSocket Server:**

```bash
# On RPi, in another terminal:
python3 << EOF
import asyncio
import websockets

async def test():
    uri = "ws://localhost:8000"
    async with websockets.connect(uri) as ws:
        msg = await ws.recv()
        print(f"Received: {msg}")

asyncio.run(test())
EOF
```

### **Check Connection:**

```bash
# On RPi:
netstat -an | grep 8000
# Should show ESTABLISHED connections when Flutter is connected
```

---

## 📈 Performance

| Metric | Value |
|--------|-------|
| **Protocol** | WebSocket (ws://) |
| **Port** | 8000 |
| **Broadcast Rate** | ~20 FPS (50ms intervals) |
| **Latency** | 30-80ms (WiFi) |
| **Ping Interval** | 10 seconds |
| **Auto-reconnect** | Yes (Flutter side) |

---

## ✅ Summary

**You're all set!** Your configuration:

- ✅ Flutter connects to `ws://10.100.169.47:8000`
- ✅ RPi WebSocket server on port 8000
- ✅ Real-time landmark streaming
- ✅ Bidirectional communication (commands)
- ✅ Automatic keepalive (ping/pong)

**To start using:**
1. Start RPi server: `python3 websocket_server.py`
2. Run Flutter app: `flutter run`
3. Tap Connect in Device tab
4. See live 3D hand tracking in Illustration tab!

🎉 **Ready for real-time hand tracking!**

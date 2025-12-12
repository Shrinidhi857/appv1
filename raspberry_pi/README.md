# Raspberry Pi Server Requirements

## Installation Commands

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Python packages
pip3 install websockets flask mediapipe opencv-python picamera2 numpy

# Or use requirements.txt
pip3 install -r requirements.txt
```

## requirements.txt

```
websockets>=11.0
flask>=2.3.0
mediapipe>=0.10.0
opencv-python>=4.8.0
picamera2>=0.3.0
numpy>=1.24.0
```

## Server Files

1. **websocket_server.py** - Real-time WebSocket streaming (Recommended)
   - Port: 8765
   - Protocol: ws://
   - FPS: ~20 (configurable)

2. **http_api.py** - HTTP polling fallback
   - Port: 5000
   - Endpoints: 
     - GET /landmarks
     - POST /command

## Running the Server

### WebSocket Server
```bash
python3 websocket_server.py
```

Expected output:
```
WebSocket server listening on ws://0.0.0.0:8765
Client connected
```

### HTTP API Server
```bash
python3 http_api.py
```

Expected output:
```
 * Serving Flask app 'http_api'
 * Running on http://0.0.0.0:5000
```

## MediaPipe Integration

Replace the `get_latest_landmarks()` function in `websocket_server.py` with your actual MediaPipe pipeline:

```python
import mediapipe as mp
import cv2
from picamera2 import Picamera2

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

picam2 = Picamera2()
picam2.configure(picam2.create_preview_configuration(main={"size": (640, 480)}))
picam2.start()

def get_latest_landmarks():
    frame = picam2.capture_array()
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)
    
    payload = {
        "timestamp": time.time(),
        "hands_count": 0,
        "hands": []
    }
    
    if results.multi_hand_landmarks:
        payload["hands_count"] = len(results.multi_hand_landmarks)
        
        for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
            hand_data = {
                "hand_index": idx,
                "label": results.multi_handedness[idx].classification[0].label,
                "confidence": results.multi_handedness[idx].classification[0].score,
                "landmarks": [
                    {"x": lm.x, "y": lm.y, "z": lm.z}
                    for lm in hand_landmarks.landmark
                ],
                "features": {
                    "thumb_distance": calculate_thumb_distance(hand_landmarks),
                    "index_distance": calculate_index_distance(hand_landmarks),
                    "hand_size": calculate_hand_size(hand_landmarks)
                }
            }
            payload["hands"].append(hand_data)
    
    return payload
```

## Firewall Configuration

```bash
# Allow WebSocket port
sudo ufw allow 8765

# Allow HTTP port
sudo ufw allow 5000

# Check status
sudo ufw status
```

## Auto-start on Boot (Optional)

Create systemd service file:
```bash
sudo nano /etc/systemd/system/handspeaks.service
```

Add content:
```ini
[Unit]
Description=HandSpeaks WebSocket Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/appv1/raspberry_pi
ExecStart=/usr/bin/python3 /home/pi/appv1/raspberry_pi/websocket_server.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable handspeaks
sudo systemctl start handspeaks
sudo systemctl status handspeaks
```

## Testing

### Test Camera
```bash
libcamera-hello
# OR
raspistill -o test.jpg
```

### Test Server Locally
```bash
# WebSocket (install wscat: npm install -g wscat)
wscat -c ws://localhost:8765

# HTTP
curl http://localhost:5000/landmarks
```

### Monitor Logs
```bash
# Real-time logs
tail -f /var/log/handspeaks.log

# Or watch terminal output
python3 websocket_server.py
```

## Performance Optimization

### Reduce Latency
```python
# Lower resolution
picam2.configure(picam2.create_preview_configuration(main={"size": (320, 240)}))

# Reduce frame rate
await asyncio.sleep(0.1)  # 10 FPS instead of 20
```

### Optimize MediaPipe
```python
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=1,  # Track only one hand
    min_detection_confidence=0.3,  # Lower threshold
    min_tracking_confidence=0.3
)
```

## Troubleshooting

**Camera not detected:**
```bash
# Enable camera interface
sudo raspi-config
# Interface Options → Camera → Enable
```

**ModuleNotFoundError:**
```bash
pip3 install --upgrade pip
pip3 install -r requirements.txt
```

**Port already in use:**
```bash
# Find and kill process
sudo lsof -i :8765
sudo kill -9 <PID>
```

**Slow performance:**
- Use Ethernet instead of WiFi
- Reduce camera resolution
- Lower frame rate
- Enable hardware acceleration

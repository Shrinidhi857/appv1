#!/usr/bin/env python3
"""
Simplified MediaPipe Hand Landmark to Bluetooth Sender
Test version without GPIO dependencies
"""

from picamera2 import Picamera2
import cv2
import mediapipe as mp
import time
import json
from bluetooth import *

# ---------- Configuration ----------
DEVICE_NAME = "Handspeaks"
BLUETOOTH_PORT = 22

print("=" * 60)
print("MediaPipe Hand Landmark Bluetooth Sender")
print("=" * 60)

# ---------- MediaPipe Initialization ----------
print("\n[1/4] Initializing MediaPipe...")
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.5
)
print("✓ MediaPipe initialized")

# ---------- Picamera2 Initialization ----------
print("\n[2/4] Initializing Camera...")
try:
    picam2 = Picamera2()
    config = picam2.create_video_configuration(
        main={"size": (640, 480), "format": "RGB888"}
    )
    picam2.configure(config)
    picam2.start()
    time.sleep(2)  # Camera warm-up
    print("✓ Camera initialized (640x480)")
except Exception as e:
    print(f"✗ Camera initialization failed: {e}")
    exit(1)

# ---------- Bluetooth Setup ----------
print("\n[3/4] Setting up Bluetooth server...")
try:
    server_sock = BluetoothSocket(RFCOMM)
    server_sock.bind(("", BLUETOOTH_PORT))
    server_sock.listen(1)

    advertise_service(
        server_sock,
        DEVICE_NAME,
        service_id="00001101-0000-1000-8000-00805F9B34FB",
        service_classes=[SERIAL_PORT_CLASS],
        profiles=[SERIAL_PORT_PROFILE]
    )
    print(f"✓ Bluetooth server ready on channel {BLUETOOTH_PORT}")
    print(f"✓ Device name: '{DEVICE_NAME}'")
except Exception as e:
    print(f"✗ Bluetooth setup failed: {e}")
    picam2.stop()
    exit(1)

# ---------- Wait for Connection ----------
print("\n[4/4] Waiting for Flutter app to connect...")
print("→ Open the Flutter app and scan for devices")
print()

try:
    client_sock, client_info = server_sock.accept()
    print(f"✓ Connected to: {client_info}")
    print()
except Exception as e:
    print(f"✗ Connection failed: {e}")
    picam2.stop()
    server_sock.close()
    exit(1)

# ---------- Helper Functions ----------
def extract_landmarks(hand_landmarks):
    """Extract 21 hand landmarks as x,y,z coordinates"""
    landmarks = []
    for lm in hand_landmarks.landmark:
        landmarks.append({
            'x': round(lm.x, 4),
            'y': round(lm.y, 4),
            'z': round(lm.z, 4)
        })
    return landmarks

def calculate_features(landmarks):
    """Calculate gesture features from landmarks"""
    wrist = landmarks[0]
    thumb_tip = landmarks[4]
    index_tip = landmarks[8]
    middle_tip = landmarks[12]
    
    # Calculate distances
    thumb_dist = ((thumb_tip['x'] - wrist['x'])**2 + 
                  (thumb_tip['y'] - wrist['y'])**2)**0.5
    index_dist = ((index_tip['x'] - wrist['x'])**2 + 
                  (index_tip['y'] - wrist['y'])**2)**0.5
    hand_size = ((middle_tip['x'] - wrist['x'])**2 + 
                 (middle_tip['y'] - wrist['y'])**2)**0.5
    
    return {
        'thumb_distance': round(thumb_dist, 4),
        'index_distance': round(index_dist, 4),
        'hand_size': round(hand_size, 4)
    }

def send_data(sock, data):
    """Send JSON data via Bluetooth"""
    try:
        json_str = json.dumps(data) + "\n"
        sock.send(json_str.encode('utf-8'))
        return True
    except Exception as e:
        print(f"✗ Send error: {e}")
        return False

# ---------- Main Processing Loop ----------
print("=" * 60)
print("STREAMING HAND LANDMARKS")
print("=" * 60)
print("Press Ctrl+C to stop\n")

frame_count = 0
send_interval = 3  # Send every 3 frames
hands_detected_count = 0
last_print_time = time.time()

try:
    while True:
        # Capture frame
        frame_rgb = picam2.capture_array()
        
        # Process with MediaPipe
        results = hands.process(frame_rgb)
        
        # Prepare data packet
        hands_data = []
        
        if results.multi_hand_landmarks and results.multi_handedness:
            hands_detected_count = len(results.multi_hand_landmarks)
            
            for idx, (hand_lm, handedness) in enumerate(
                zip(results.multi_hand_landmarks, results.multi_handedness)
            ):
                # Extract data
                landmarks = extract_landmarks(hand_lm)
                features = calculate_features(landmarks)
                hand_label = handedness.classification[0].label
                confidence = round(handedness.classification[0].score, 4)
                
                hands_data.append({
                    'hand_index': idx,
                    'label': hand_label,
                    'confidence': confidence,
                    'landmarks': landmarks,
                    'features': features
                })
        else:
            hands_detected_count = 0
        
        # Send data at intervals
        if frame_count % send_interval == 0:
            packet = {
                'timestamp': time.time(),
                'hands_count': len(hands_data),
                'hands': hands_data
            }
            
            if send_data(client_sock, packet):
                # Print status every 2 seconds
                if time.time() - last_print_time > 2:
                    status = f"[Frame {frame_count:05d}] Hands: {hands_detected_count} | Sent: {len(hands_data)} hand(s)"
                    print(status)
                    last_print_time = time.time()
        
        frame_count += 1
        time.sleep(0.01)  # Small delay to prevent CPU overload

except KeyboardInterrupt:
    print("\n\n✓ Stopped by user")
except Exception as e:
    print(f"\n\n✗ Error: {e}")
finally:
    # ---------- Cleanup ----------
    print("\nCleaning up...")
    hands.close()
    picam2.stop()
    cv2.destroyAllWindows()
    client_sock.close()
    server_sock.close()
    print("✓ Cleanup complete")
    print("\nBye!")

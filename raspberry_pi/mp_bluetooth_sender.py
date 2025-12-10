#!/usr/bin/env python3
"""
MediaPipe Hand Landmark Extraction and Bluetooth Transmission
Sends hand landmark vectors to Flutter app via Bluetooth Serial
"""

from picamera2 import Picamera2
import cv2
import mediapipe as mp
import RPi.GPIO as GPIO
import time
import json
import socket
from bluetooth import *

# ---------- Configuration ----------
DEVICE_NAME = "Handspeaks"
BLUETOOTH_PORT = 22  # RFCOMM channel
GPIO_PIN = 26

# ---------- MediaPipe Initialization ----------
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.5
)

# ---------- Picamera2 Initialization ----------
picam2 = Picamera2()
config = picam2.create_video_configuration(
    main={"size": (960, 720), "format": "RGB888"}
)
picam2.configure(config)
picam2.start()

# ---------- GPIO Setup ----------
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(GPIO_PIN, GPIO.OUT)
GPIO.output(GPIO_PIN, GPIO.HIGH)
print(f"GPIO {GPIO_PIN} is now HIGH")

# ---------- Bluetooth Setup ----------
server_sock = BluetoothSocket(RFCOMM)
server_sock.bind(("", BLUETOOTH_PORT))
server_sock.listen(1)

# Make device discoverable
print(f"Making device '{DEVICE_NAME}' discoverable on channel {BLUETOOTH_PORT}...")
advertise_service(
    server_sock,
    DEVICE_NAME,
    service_id="00001101-0000-1000-8000-00805F9B34FB",  # Serial Port Profile UUID
    service_classes=[SERIAL_PORT_CLASS],
    profiles=[SERIAL_PORT_PROFILE]
)

print("Waiting for Bluetooth connection from Flutter app...")
client_sock, client_info = server_sock.accept()
print(f"Connected to: {client_info}")

# ---------- Helper Functions ----------
def extract_landmark_vector(hand_landmarks):
    """
    Extract hand landmarks as a normalized vector
    Returns: List of 21 landmarks, each with x, y, z coordinates
    """
    landmarks = []
    for landmark in hand_landmarks.landmark:
        landmarks.append({
            'x': round(landmark.x, 4),
            'y': round(landmark.y, 4),
            'z': round(landmark.z, 4)
        })
    return landmarks

def calculate_gesture_features(landmarks):
    """
    Calculate additional features for gesture recognition
    """
    # Example: Calculate finger tip positions relative to wrist
    wrist = landmarks[0]
    thumb_tip = landmarks[4]
    index_tip = landmarks[8]
    middle_tip = landmarks[12]
    ring_tip = landmarks[16]
    pinky_tip = landmarks[20]
    
    features = {
        'thumb_distance': round(
            ((thumb_tip['x'] - wrist['x'])**2 + 
             (thumb_tip['y'] - wrist['y'])**2)**0.5, 4
        ),
        'index_distance': round(
            ((index_tip['x'] - wrist['x'])**2 + 
             (index_tip['y'] - wrist['y'])**2)**0.5, 4
        ),
        'hand_size': round(
            ((middle_tip['x'] - wrist['x'])**2 + 
             (middle_tip['y'] - wrist['y'])**2)**0.5, 4
        )
    }
    return features

def send_landmarks_data(client_sock, hands_data):
    """
    Send landmark data to Flutter app via Bluetooth
    """
    try:
        # Create JSON payload
        payload = {
            'timestamp': time.time(),
            'hands_count': len(hands_data),
            'hands': hands_data
        }
        
        # Convert to JSON string and add newline delimiter
        json_data = json.dumps(payload) + "\n"
        
        # Send via Bluetooth
        client_sock.send(json_data.encode('utf-8'))
        return True
    except Exception as e:
        print(f"Error sending data: {e}")
        return False

# ---------- Main Processing Loop ----------
print("Starting hand landmark detection and transmission...")
print("Press 'q' to quit")

frame_count = 0
send_interval = 2  # Send every 2 frames to reduce data load

try:
    while True:
        # Capture frame from camera
        frame_rgb = picam2.capture_array()
        
        # Process with MediaPipe
        results = hands.process(frame_rgb)
        
        # Prepare data for transmission
        hands_data = []
        
        if results.multi_hand_landmarks and results.multi_handedness:
            for idx, (hand_landmarks, handedness) in enumerate(
                zip(results.multi_hand_landmarks, results.multi_handedness)
            ):
                # Extract landmark vector
                landmarks = extract_landmark_vector(hand_landmarks)
                
                # Calculate additional features
                features = calculate_gesture_features(landmarks)
                
                # Get hand label (Left/Right)
                hand_label = handedness.classification[0].label
                hand_score = round(handedness.classification[0].score, 4)
                
                # Compile hand data
                hand_data = {
                    'hand_index': idx,
                    'label': hand_label,
                    'confidence': hand_score,
                    'landmarks': landmarks,
                    'features': features
                }
                hands_data.append(hand_data)
                
                # Draw landmarks on frame for preview
                frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
                mp_drawing.draw_landmarks(
                    frame_bgr,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing_styles.get_default_hand_landmarks_style(),
                    mp_drawing_styles.get_default_hand_connections_style()
                )
        
        # Send data via Bluetooth (throttled by frame interval)
        if frame_count % send_interval == 0:
            if hands_data:
                success = send_landmarks_data(client_sock, hands_data)
                if success:
                    print(f"✓ Sent {len(hands_data)} hand(s) data")
            else:
                # Send empty data to indicate no hands detected
                send_landmarks_data(client_sock, [])
        
        frame_count += 1
        
        # Display preview (optional - comment out for headless operation)
        if results.multi_hand_landmarks:
            frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
            for hand_landmarks in results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(
                    frame_bgr,
                    hand_landmarks,
                    mp_hands.HAND_CONNECTIONS,
                    mp_drawing_styles.get_default_hand_landmarks_style(),
                    mp_drawing_styles.get_default_hand_connections_style()
                )
            cv2.imshow("MediaPipe Hands - Bluetooth Sender", frame_bgr)
        
        # Check for quit command
        if cv2.waitKey(1) & 0xFF == ord('q'):
            print("\nQuitting...")
            break

except KeyboardInterrupt:
    print("\nInterrupted by user")
except Exception as e:
    print(f"\nError: {e}")
finally:
    # ---------- Cleanup ----------
    print("Cleaning up...")
    hands.close()
    picam2.stop()
    cv2.destroyAllWindows()
    client_sock.close()
    server_sock.close()
    GPIO.output(GPIO_PIN, GPIO.LOW)
    GPIO.cleanup()
    print("Cleanup complete")

import asyncio
import websockets
import json
import torch
import torch.nn as nn
import math
import cv2
import numpy as np
import mediapipe as mp
import time
import os
import argparse
from src.inference.emitter import InferenceEmitter

# Configuration
MODEL_PATH = "models/transformer_sliding_window.pth"
DATA_DIR = "data"
WINDOW_SIZE = 30
STRIDE = 1
FEATURES_PER_FRAME = 126
PORT_MAIN = 8765  # Your existing port for video client
PORT_FLUTTER = 8000  # New port for Flutter landmark broadcast

# Model Hyperparameters
D_MODEL = 128
NHEAD = 4
NUM_ENCODER_LAYERS = 2
DIM_FEEDFORWARD = 256
DROPOUT = 0.5

# Device configuration
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# --- Mediapipe Setup ---
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

# --- Model Definition ---
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super(PositionalEncoding, self).__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0).transpose(0, 1)
        self.register_buffer('pe', pe)

    def forward(self, x):
        return x + self.pe[:x.size(0), :]

class SignLanguageTransformer(nn.Module):
    def __init__(self, num_classes, input_dim=126, d_model=128, nhead=4, num_layers=2, dim_feedforward=256, dropout=0.5):
        super(SignLanguageTransformer, self).__init__()
        self.d_model = d_model
        self.embedding = nn.Linear(input_dim, d_model)
        self.pos_encoder = PositionalEncoding(d_model, max_len=WINDOW_SIZE)
        encoder_layer = nn.TransformerEncoderLayer(d_model=d_model, nhead=nhead, dim_feedforward=dim_feedforward, dropout=dropout, batch_first=True)
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        self.dropout = nn.Dropout(dropout)
        self.fc_out = nn.Linear(d_model, num_classes)

    def forward(self, src):
        src = self.embedding(src) * math.sqrt(self.d_model)
        src = src.permute(1, 0, 2)
        src = self.pos_encoder(src)
        src = src.permute(1, 0, 2)
        output = self.transformer_encoder(src)
        output = output.mean(dim=1)
        output = self.dropout(output)
        output = self.fc_out(output)
        return output

# Global State
model = None
classes = []
latest_landmarks = None  # Shared state for Flutter clients
flutter_clients = set()  # Connected Flutter clients

def get_classes():
    if os.path.exists(DATA_DIR):
        return sorted([d for d in os.listdir(DATA_DIR) if os.path.isdir(os.path.join(DATA_DIR, d))])
    return []

def extract_keypoints(results):
    frame_keypoints = []
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            for lm in hand_landmarks.landmark:
                frame_keypoints.extend([lm.x, lm.y, lm.z])
       
        detected_hands = len(results.multi_hand_landmarks)
        if detected_hands < 2:
            padding_needed = (2 - detected_hands) * 21 * 3
            frame_keypoints.extend([0.0] * padding_needed)
    else:
        frame_keypoints.extend([0.0] * FEATURES_PER_FRAME)
    return frame_keypoints[:FEATURES_PER_FRAME]

def convert_landmarks_for_flutter(results):
    """Convert MediaPipe results to Flutter format"""
    global latest_landmarks
    
    hands_list = []
    if results.multi_hand_landmarks and results.multi_handedness:
        for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
            # Get hand label and confidence
            label = results.multi_handedness[idx].classification[0].label
            confidence = results.multi_handedness[idx].classification[0].score
            
            # Extract 21 landmarks
            landmarks = []
            for lm in hand_landmarks.landmark:
                landmarks.append({
                    'x': float(lm.x),
                    'y': float(lm.y),
                    'z': float(lm.z)
                })
            
            hands_list.append({
                'hand_index': idx,
                'label': label,
                'confidence': float(confidence),
                'landmarks': landmarks
            })
    
    latest_landmarks = {
        'timestamp': time.time(),
        'hands_count': len(hands_list),
        'hands': hands_list
    }
    return latest_landmarks

async def flutter_handler(websocket):
    """Handle Flutter client connections on port 8000"""
    print(f"Flutter client connected: {websocket.remote_address}")
    flutter_clients.add(websocket)
    
    try:
        # Send welcome message
        await websocket.send(json.dumps({
            'type': 'WELCOME',
            'payload': {'message': 'Connected to RPi Landmark Server'}
        }))
        
        # Listen for commands from Flutter
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type')
                payload = data.get('payload')
                
                if msg_type == 'PING':
                    await websocket.send(json.dumps({'type': 'PONG', 'payload': None}))
                elif msg_type == 'COMMAND':
                    print(f"Flutter command: {payload}")
                    # Handle commands if needed
                    
            except Exception as e:
                print(f"Flutter message parse error: {e}")
                
    except websockets.exceptions.ConnectionClosed:
        print(f"Flutter client disconnected: {websocket.remote_address}")
    finally:
        flutter_clients.discard(websocket)

async def flutter_broadcaster():
    """Broadcast landmarks to all connected Flutter clients"""
    while True:
        if flutter_clients and latest_landmarks:
            # Send landmarks to all Flutter clients
            message = json.dumps({
                'type': 'LANDMARKS',
                'payload': latest_landmarks
            })
            
            disconnected = set()
            for client in flutter_clients:
                try:
                    await client.send(message)
                except Exception as e:
                    print(f"Error sending to Flutter client: {e}")
                    disconnected.add(client)
            
            # Remove disconnected clients
            flutter_clients.difference_update(disconnected)
        
        await asyncio.sleep(0.05)  # ~20 FPS

async def handler(websocket):
    """Handle video client connections on port 8765"""
    print(f"Video client connected: {websocket.remote_address}")
   
    # Initialize MediaPipe for this client
    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )

    # Initialize Emitter
    emitter = InferenceEmitter(
        model=model,
        label_map=classes,
        fps=30,
        window_size=WINDOW_SIZE,
        stride=STRIDE,
        device=device,
        debounce_k=3,
        conf_min=0.6
    )
   
    start_time_server = time.time()

    try:
        async for message in websocket:
            if isinstance(message, bytes):
                # Decode Frame
                nparr = np.frombuffer(message, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
               
                if frame is None:
                    continue
               
                # --- ROTATION STEP ---
                frame = cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)
               
                # MediaPipe Processing
                image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = hands.process(image_rgb)
               
                # Convert landmarks for Flutter (updates global state)
                convert_landmarks_for_flutter(results)
               
                # Draw Landmarks Overlay
                if results.multi_hand_landmarks:
                    for hand_landmarks in results.multi_hand_landmarks:
                        mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

                # Extract Keypoints for prediction
                kps = extract_keypoints(results)
                timestamp = time.time() - start_time_server
               
                # Update Emitter
                finalized_event = emitter.process_frame(kps, timestamp)
               
                state_code = 0 # 0=Wait, 2=Active, 3=Result
               
                if finalized_event:
                    token = finalized_event['token']
                    conf = finalized_event['avg_conf']
                    print(f"Detected: {token} ({conf:.2f})")
                   
                    state_code = 3
                   
                    # Send RESULT back to video client
                    response = {
                        "status": f"DETECTED: {token}",
                        "prediction": token,
                        "confidence": conf,
                        "state": 3
                    }
                    await websocket.send(json.dumps(response))

                elif emitter.current_token:
                    state_code = 2
                else:
                    state_code = 0

                # Server UI Overlay
                current_active = emitter.current_token if emitter.current_token else "..."
                cv2.putText(frame, f"Live: {current_active}", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
                
                # Show Flutter client count
                cv2.putText(frame, f"Flutter: {len(flutter_clients)} connected", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
               
                # Local Server Preview
                cv2.imshow("Server Preview (Rotated)", frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
                   
    except websockets.exceptions.ConnectionClosed:
        print(f"Video client disconnected: {websocket.remote_address}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        hands.close()
        cv2.destroyAllWindows()

async def main():
    global model, classes
   
    classes = get_classes()
    if not classes:
        print("Error: No classes found.")
        return
    print(f"Classes: {classes}")

    print(f"Loading model from {MODEL_PATH}...")
    model = SignLanguageTransformer(
        num_classes=len(classes),
        input_dim=FEATURES_PER_FRAME,
        d_model=D_MODEL,
        nhead=NHEAD,
        num_layers=NUM_ENCODER_LAYERS,
        dim_feedforward=DIM_FEEDFORWARD,
        dropout=DROPOUT
    ).to(device)
   
    try:
        model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
        print("Model loaded successfully.")
    except FileNotFoundError:
        print(f"Error: Model not found at {MODEL_PATH}")
        return
       
    model.eval()
   
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=PORT_MAIN, help="Video Client Port")
    parser.add_argument("--flutter-port", type=int, default=PORT_FLUTTER, help="Flutter Port")
    args = parser.parse_args()
   
    print(f"Starting video client server on port {args.port}...")
    print(f"Starting Flutter landmark server on port {args.flutter_port}...")
    print(f"Flutter should connect to: ws://10.100.169.47:{args.flutter_port}")
    
    # Start both servers concurrently
    async with websockets.serve(handler, "0.0.0.0", args.port), \
               websockets.serve(flutter_handler, "0.0.0.0", args.flutter_port):
        # Start Flutter broadcaster in background
        asyncio.create_task(flutter_broadcaster())
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Server stopped.")

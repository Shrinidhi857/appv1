# websocket_server.py
import asyncio
import json
import time
import random
from websockets import serve

import cv2
import mediapipe as mp
from picamera2 import Picamera2

# TODO: Replace this with your actual MediaPipe landmark extraction code
# Example structure for MediaPipe integration:
#
# import cv2
# import mediapipe as mp
# from picamera2 import Picamera2
# 
# mp_hands = mp.solutions.hands
# hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.5)
# picam2 = Picamera2()
# picam2.start()

def get_latest_landmarks():
    """
    Replace this entire function with your MediaPipe code that:
    1. Captures frame from camera
    2. Processes with MediaPipe
    3. Extracts hand landmarks
    4. Returns in this exact format
    """
    # TEMPORARY: Random data for testing
    # DELETE THIS and replace with your MediaPipe code
    hands = []
    landmarks = [[random.random(), random.random(), random.random()] for _ in range(21)]
    hands.append({'hand_index': 0, 'label': 'Left', 'confidence': 0.95, 'landmarks': landmarks})
    
    payload = {
        'timestamp': time.time(),
        'hands_count': len(hands),
        'hands': hands
    }
    return payload
    
    # EXAMPLE of what your MediaPipe code should return:
    # frame = picam2.capture_array()
    # results = hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    # 
    # hands_list = []
    # if results.multi_hand_landmarks:
    #     for idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
    #         label = results.multi_handedness[idx].classification[0].label
    #         confidence = results.multi_handedness[idx].classification[0].score
    #         landmarks = [{'x': lm.x, 'y': lm.y, 'z': lm.z} for lm in hand_landmarks.landmark]
    #         hands_list.append({'hand_index': idx, 'label': label, 'confidence': confidence, 'landmarks': landmarks})
    # 
    # return {
    #     'timestamp': time.time(),
    #     'hands_count': len(hands_list),
    #     'hands': hands_list
    # }

connected = set()

async def handler(ws):
    print("Client connected")
    connected.add(ws)
    try:
        # Send welcome
        await ws.send(json.dumps({'type': 'WELCOME', 'payload': {'message': 'Hello from RPi'}}))
        # optionally listen for commands from client
        async for msg in ws:
            try:
                data = json.loads(msg)
                t = data.get('type')
                p = data.get('payload')
                print("Received:", t, p)
                if t == 'COMMAND':
                    if p == 'start':
                        # client asked to start streaming - optionally set a flag
                        pass
                    elif p == 'stop':
                        pass
                    # respond with status
                    await ws.send(json.dumps({'type': 'STATUS', 'payload': {'streaming': True, 'message': 'Command received'}}))
                elif t == 'PING':
                    await ws.send(json.dumps({'type': 'PONG', 'payload': None}))
            except Exception as e:
                print("client msg parse error:", e)

    except Exception as e:
        print("Client handler error:", e)
    finally:
        connected.remove(ws)
        print("Client disconnected")

async def broadcaster():
    while True:
        if connected:
            payload = get_latest_landmarks()
            msg = json.dumps({'type': 'LANDMARKS', 'payload': payload})
            # broadcast
            webs = list(connected)
            for ws in webs:
                try:
                    await ws.send(msg)
                except Exception as e:
                    print("send error:", e)
        await asyncio.sleep(0.05)  # ~20 FPS

async def main():
    async with serve(handler, "0.0.0.0", 8000):
        print("WebSocket server listening on ws://0.0.0.0:8000")
        print("Flutter should connect to: ws://10.100.169.47:8000")
        await broadcaster()  # runs until cancelled

if __name__ == "__main__":
    asyncio.run(main())

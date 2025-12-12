# websocket_server.py
import asyncio
import json
import time
import random
from websockets import serve

# Replace this with your actual MediaPipe retrieval
def get_latest_landmarks():
    # Return example: a dict with timestamp, hands_count, hands list
    # Each hand: {'hand_index':0, 'label':'Left', 'confidence':0.98, 'landmarks': [[x,y,z], ...]}
    hands = []
    # create 1 random hand with 21 landmarks
    landmarks = [[random.random(), random.random(), random.random()] for _ in range(21)]
    hands.append({'hand_index': 0, 'label': 'Left', 'confidence': 0.95, 'landmarks': landmarks})
    payload = {
        'timestamp': time.time(),
        'hands_count': len(hands),
        'hands': hands
    }
    return payload

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
    async with serve(handler, "0.0.0.0", 8765):
        print("WebSocket server listening on ws://0.0.0.0:8765")
        await broadcaster()  # runs until cancelled

if __name__ == "__main__":
    asyncio.run(main())

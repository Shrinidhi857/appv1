# http_api.py
from flask import Flask, jsonify, request
import time
import random

app = Flask(__name__)

# store latest payload in memory
latest_payload = {
    'timestamp': time.time(),
    'hands_count': 0,
    'hands': []
}

def update_payload():
    # replace with your actual mediapipe retrieval
    landmarks = [[random.random(), random.random(), random.random()] for _ in range(21)]
    latest_payload['timestamp'] = time.time()
    latest_payload['hands_count'] = 1
    latest_payload['hands'] = [{'hand_index': 0, 'label': 'Left', 'confidence': 0.95, 'landmarks': landmarks}]

@app.route('/landmarks', methods=['GET'])
def get_landmarks():
    update_payload()
    return jsonify(latest_payload)

@app.route('/command', methods=['POST'])
def command():
    data = request.get_json() or {}
    cmd = data.get('command')
    print("Command received:", cmd)
    # perform command handling: start/stop camera, toggles etc.
    return jsonify({'status': 'ok', 'command': cmd})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

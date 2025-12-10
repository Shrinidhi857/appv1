# Quick Start Guide - MediaPipe to Flutter via Bluetooth

## 🚀 Quick Setup (5 Minutes)

### Step 1: Raspberry Pi Setup (2 minutes)

```bash
# 1. Copy the script to your Raspberry Pi
scp mp_bluetooth_simple.py pi@<your_pi_ip>:~/

# 2. SSH into your Pi
ssh pi@<your_pi_ip>

# 3. Install dependencies (if not already installed)
pip3 install picamera2 mediapipe pybluez opencv-python

# 4. Run the script
python3 mp_bluetooth_simple.py
```

**Expected Output:**
```
============================================================
MediaPipe Hand Landmark Bluetooth Sender
============================================================

[1/4] Initializing MediaPipe...
✓ MediaPipe initialized

[2/4] Initializing Camera...
✓ Camera initialized (640x480)

[3/4] Setting up Bluetooth server...
✓ Bluetooth server ready on channel 22
✓ Device name: 'Handspeaks'

[4/4] Waiting for Flutter app to connect...
→ Open the Flutter app and scan for devices
```

Leave this terminal running and proceed to Step 2.

---

### Step 2: Flutter App Setup (3 minutes)

**On your Windows PC:**

```powershell
# 1. Navigate to project
cd C:\Users\HP\Downloads\sih\ISL_App\appv1

# 2. Install dependencies
flutter pub get

# 3. Connect your Android phone via USB (with USB debugging enabled)

# 4. Run the app
flutter run
```

**On your Android phone:**
1. The app will launch automatically
2. Grant Bluetooth permissions when prompted
3. Wait for "Handspeaks" device to appear
4. App will auto-connect when found
5. You'll see real-time hand landmark data!

---

## 📱 What You'll See

### Raspberry Pi Terminal:
```
============================================================
STREAMING HAND LANDMARKS
============================================================
Press Ctrl+C to stop

[Frame 00000] Hands: 1 | Sent: 1 hand(s)
[Frame 00060] Hands: 2 | Sent: 2 hand(s)
[Frame 00120] Hands: 1 | Sent: 1 hand(s)
```

### Flutter App Screen:
```
┌─────────────────────────────────────┐
│ Connected ✓         Packets: 142   │
├─────────────────────────────────────┤
│                                     │
│  Hands Detected: 2                  │
│  Timestamp: 1702345678.12           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Right Hand     Conf: 98.7%  │   │
│  │                             │   │
│  │ Features:                   │   │
│  │  Thumb: 0.234               │   │
│  │  Index: 0.345               │   │
│  │  Size: 0.456                │   │
│  │                             │   │
│  │ Landmarks: 21 points        │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Hand Visualization]               │
│         ●                           │
│        ╱│╲                          │
│       ● ● ●                         │
│      ╱  │  ╲                        │
│     ●   ●   ●                       │
│                                     │
└─────────────────────────────────────┘
```

---

## ❓ Quick Troubleshooting

### "Camera not detected"
```bash
sudo raspi-config
# Interface Options > Camera > Enable
sudo reboot
```

### "Bluetooth permission denied" (Flutter)
- Go to Android Settings
- Apps > Handspeaks > Permissions
- Enable all permissions

### "Connection timeout"
1. Make sure Pi script is running FIRST
2. Restart Bluetooth on both devices
3. Try manual connection from device list

### "No hands detected"
- Ensure good lighting
- Keep hand within camera frame
- Try different hand positions
- Check camera preview window (if enabled)

---

## 📊 Testing the Connection

### Test 1: Basic Connection
1. Run Pi script
2. Launch Flutter app
3. Wait for auto-connect
4. ✅ Success: "Connected ✓" shown

### Test 2: Single Hand Detection
1. Show ONE hand to camera
2. Check Flutter app
3. ✅ Success: "Hands Detected: 1" shown
4. ✅ Success: See "Right Hand" or "Left Hand" card

### Test 3: Two Hand Detection
1. Show BOTH hands to camera
2. Check Flutter app
3. ✅ Success: "Hands Detected: 2" shown
4. ✅ Success: See two hand cards

### Test 4: Hand Visualization
1. Move hand slowly
2. Watch visualization on Flutter app
3. ✅ Success: Dots move with your hand
4. ✅ Success: Lines connect finger joints

---

## 🎯 Next Steps

Once basic connection works:

1. **Test different gestures** - Try thumbs up, peace sign, fist
2. **Check landmark accuracy** - Compare visualization to actual hand
3. **Monitor performance** - Watch packet count increase
4. **Test range** - See how far from camera works
5. **Add gesture recognition** - Use landmark data for custom gestures

---

## 📝 Files You Need

**Raspberry Pi:**
- `mp_bluetooth_simple.py` (recommended for testing)
- `mp_bluetooth_sender.py` (full version with GPIO)

**Flutter App:**
- Already integrated in your project
- No additional files needed

---

## 💡 Pro Tips

1. **Better Detection**: Ensure good lighting and contrasting background
2. **Lower Latency**: Reduce `send_interval` in Python script (higher CPU usage)
3. **Smoother Tracking**: Lower `min_tracking_confidence` value
4. **More Hands**: Change `max_num_hands` parameter (up to 2)
5. **Save Data**: Add JSON logging to Python script for training data

---

## 📞 Need Help?

Check the full README.md for:
- Detailed architecture
- Complete API reference
- Advanced configuration
- Performance tuning
- Future enhancements

---

**Ready?** Start with Step 1 above! 🚀

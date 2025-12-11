# 3D Hand Model - Quick Start

## Immediate Next Steps

### 1. Install Dependencies (REQUIRED)

```bash
cd c:\Users\HP\Downloads\sih\ISL_App\appv1
flutter pub get
```

**⚠️ Expected Issue:** The packages `flutter_gl` and `three_dart` may not be available in the specified versions.

**If `flutter pub get` fails:**

Check the error message and update `pubspec.yaml` with available versions:
- Look for error like: `three_dart ^0.0.17 doesn't exist`
- Remove or comment out problematic packages
- Consider WebView alternative (see main guide)

### 2. Inspect Your Model

```bash
# Install Python package
pip install pygltflib

# Run inspection
cd c:\Users\HP\Downloads\sih\ISL_App\appv1
python inspect_gltf.py assets/models/breen.glb
```

**What you'll get:**
- List of all node names (for hiding lower body)
- List of all bone names (for hand animation)
- Recommendations for Flutter code

### 3. Update Bone Names

Open `lib/components/glb_hand_mapping_widget.dart` and update these sections:

**Line ~221: Wrist bone names**
```dart
final wristBoneNames = [
  'YourActualWristBoneName',  // ← Add from inspect_gltf.py
  'RightWrist',
  'LeftWrist',
  // ... keep existing fallbacks
];
```

**Line ~315: Finger bone names**
```dart
final bonePatterns = {
  'thumb': ['YourThumbBoneName', 'Thumb1'],     // ← Add actual names
  'index': ['YourIndexBoneName', 'Index1'],     // ← Add actual names
  'middle': ['YourMiddleBoneName', 'Middle1'],  // ← Add actual names
  'ring': ['YourRingBoneName', 'Ring1'],        // ← Add actual names
  'pinky': ['YourPinkyBoneName', 'Pinky1'],     // ← Add actual names
};
```

**Line ~172: Lower body nodes to hide**
```dart
final lowerBodyNames = [
  'YourLowerBodyNodeName',  // ← Add from inspect_gltf.py
  'Hips',
  'Legs',
  // ... etc
];
```

### 4. Test in App

```bash
flutter run
```

1. Navigate to **Illustration tab** (third tab)
2. Toggle **3D Hand Model** switch to ON
3. Watch the status messages at bottom of screen
4. Check if model loads successfully

### 5. Where to Find the 3D Model in UI

**Location:** App → Home → Illustration Tab (3rd icon)

**UI Elements:**
- **Toggle Switch:** Top right - turns model on/off
- **3D Viewer:** 400px height container with black background
- **Status Overlay:** Bottom overlay shows loading status and node/bone count
- **Info Cards:** Below model with connection instructions

## Quick Troubleshooting

### Problem: `flutter pub get` fails

**Error:** `three_dart ^0.0.17 doesn't exist`

**Solution 1:** Update to available versions
```yaml
# pubspec.yaml
flutter_gl: ^0.0.6  # or whatever's latest
three_dart: ^0.0.16  # or whatever's latest
```

**Solution 2:** Remove and use WebView instead
```yaml
# Comment out or remove:
# flutter_gl: ^0.0.7
# three_dart: ^0.0.17

# Keep:
webview_flutter: ^4.4.2  # Already in your pubspec
```

Then follow WebView integration in main guide.

### Problem: Model loads but doesn't animate

**Cause:** Bone names don't match

**Solution:**
1. Run `python inspect_gltf.py assets/models/breen.glb`
2. Copy exact bone names from output
3. Update `glb_hand_mapping_widget.dart` with those names

### Problem: Lower body still visible

**Cause:** Node names don't match

**Solution:**
1. Check `inspect_gltf.py` output for lower body node names
2. Add them to `_hideLowerBody()` method

### Problem: Hand orientation wrong

**Cause:** Coordinate system mismatch

**Solution:** In `_applyWristRotation()` method, line ~245, try different flip combinations:

```dart
// Current:
final modelDir = vm.Vector3(
  direction.x,
  -direction.y,
  -direction.z,
);

// Try if hand is upside down:
final modelDir = vm.Vector3(
  direction.x,
  direction.y,    // No flip
  -direction.z,
);

// Try if hand is mirrored:
final modelDir = vm.Vector3(
  -direction.x,   // Flip X
  -direction.y,
  -direction.z,
);
```

## Files Reference

**Created/Modified:**
- ✅ `pubspec.yaml` - Added 3D dependencies
- ✅ `lib/components/glb_hand_mapping_widget.dart` - Main 3D widget (new file)
- ✅ `lib/tabs/illustration_tab.dart` - Updated with 3D viewer
- ✅ `inspect_gltf.py` - Model inspection tool (new file)
- ✅ `3D_MODEL_INTEGRATION_GUIDE.md` - Full documentation (new file)
- ✅ `3D_QUICKSTART.md` - This file (new file)

**Assets (already in place):**
- ✅ `assets/models/breen.glb`
- ✅ `assets/textures/*.png` (5 files)

## Alternative: WebView Approach

If native 3D rendering doesn't work, use the WebView method:

1. Create `assets/web/model_viewer.html` (template in main guide)
2. Use `webview_flutter` package (already in your dependencies)
3. Load HTML in WebView widget

**Pros:**
- No complex 3D dependencies
- Uses Google's `<model-viewer>` component
- Works on all platforms

**Cons:**
- Limited bone animation control
- Harder to connect MediaPipe landmarks
- Performance may be slower

See full WebView implementation in `3D_MODEL_INTEGRATION_GUIDE.md`.

## Summary Checklist

- [ ] Run `flutter pub get`
- [ ] Fix any dependency errors
- [ ] Run `python inspect_gltf.py assets/models/breen.glb`
- [ ] Update bone names in `glb_hand_mapping_widget.dart`
- [ ] Update lower body nodes to hide
- [ ] Run `flutter run`
- [ ] Navigate to Illustration tab
- [ ] Toggle 3D model ON
- [ ] Verify model loads
- [ ] Connect MediaPipe landmark stream
- [ ] Test hand animation
- [ ] Tune coordinate transforms

## Where to Get Help

1. **Full Guide:** `3D_MODEL_INTEGRATION_GUIDE.md`
2. **Console Logs:** `flutter logs` command
3. **Status Overlay:** Bottom of 3D viewer shows debug info
4. **Debug Prints:** Check console for node/bone names printed

## Next Action

**Run this now:**
```bash
cd c:\Users\HP\Downloads\sih\ISL_App\appv1
flutter pub get
```

Then check if it succeeds or shows package version errors!

# 3D Hand Model Integration Guide

## Overview
This document provides complete instructions for integrating the Breen GLB hand model with MediaPipe hand tracking in your Flutter HandSpeaks application.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Asset Setup](#asset-setup)
3. [Dependencies](#dependencies)
4. [Model Inspection](#model-inspection)
5. [Integration Steps](#integration-steps)
6. [Coordinate System Mapping](#coordinate-system-mapping)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Customization](#advanced-customization)

## Prerequisites

### Required Software
- Flutter SDK 3.9.2 or later
- Python 3.7+ (for model inspection)
- Android Studio / Xcode (for device testing)

### Required Files
All files should already be in place:
- `assets/models/breen.glb` - The 3D hand model
- `assets/textures/*.png` - 5 texture files for the model
- `lib/components/glb_hand_mapping_widget.dart` - Main 3D widget
- `lib/tabs/illustration_tab.dart` - UI integration
- `inspect_gltf.py` - Model inspection script

## Asset Setup

### ✅ Already Complete!
Your assets are already properly configured:

```
appv1/
  assets/
    models/
      breen.glb                 ✅ Ready
    textures/
      breen_face_2.png          ✅ Ready
      breen_sheet_4.png         ✅ Ready
      eyeball_l_3.png           ✅ Ready
      eyeball_r_0.png           ✅ Ready
      mouth_1.png               ✅ Ready
```

The `pubspec.yaml` is already configured with these assets.

## Dependencies

### ✅ Already Added!
The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_gl: ^0.0.7        # WebGL/OpenGL bridge
  three_dart: ^0.0.17       # three.js-like utilities and GLTFLoader
  vector_math: ^2.1.4       # Vector and quaternion math
```

### Next Step: Install Dependencies

**IMPORTANT:** Run this command to download the packages:

```bash
cd appv1
flutter pub get
```

**Note:** These package versions may not be available on pub.dev. If you encounter errors:

1. Check available versions:
   ```bash
   flutter pub outdated
   ```

2. Update to latest compatible versions in `pubspec.yaml`

3. Alternative approach: Use WebView with `<model-viewer>` component instead

## Model Inspection

### Inspect the Breen Model

Use the provided Python script to examine the model structure:

```bash
# Install required package
pip install pygltflib

# Run inspection
cd appv1
python inspect_gltf.py assets/models/breen.glb
```

This will output:
- All node names (for hiding lower body)
- Bone/joint names (for hand animation)
- Mesh and material information
- Recommendations for Flutter integration

### What to Look For

**Important bone names to find:**
- Wrist bones: Look for `Wrist`, `Hand`, `wrist_r`, `mixamorig:RightHand`, etc.
- Finger bones: Look for `Thumb1`, `Index1`, `Middle1`, `Ring1`, `Pinky1`, etc.
- Each finger typically has 3-4 bones (base, middle, distal, tip)

**Nodes to hide (lower body):**
- Hips, Pelvis, Spine, Legs, Feet nodes
- Any nodes below the torso

## Integration Steps

### Step 1: Verify Dependencies
```bash
cd appv1
flutter pub get
flutter doctor -v
```

### Step 2: Test the Model Loading
Navigate to the **Illustration tab** in your app:
1. Open the app
2. Go to the third tab (Illustration)
3. Toggle the **3D Hand Model** switch ON
4. You should see the model loading with status messages

### Step 3: Connect MediaPipe Data
The landmark stream is already set up in `illustration_tab.dart`:

```dart
StreamController<List<vm.Vector3>> _landmarksController
```

To feed real data from your Bluetooth/MediaPipe connection:

```dart
// In your Bluetooth handler or landmark receiver:
void onLandmarksReceived(List<Vector3> landmarks) {
  // Send to illustration tab
  _landmarksController.add(landmarks);
}
```

### Step 4: Customize Bone Mapping

**After running `inspect_gltf.py`, update bone names** in `glb_hand_mapping_widget.dart`:

```dart
// Example: Update these arrays based on your model's actual bone names
final wristBoneNames = [
  'RightWrist',      // Add your model's wrist bone name here
  'LeftWrist',
  // ... more variants
];

final bonePatterns = {
  'thumb': ['Thumb1', 'YourThumbBoneName'],    // Update with actual names
  'index': ['Index1', 'YourIndexBoneName'],    // Update with actual names
  // ... etc
};
```

### Step 5: Hide Lower Body

Update the `_hideLowerBody()` method based on inspection results:

```dart
void _hideLowerBody() {
  final lowerBodyNames = [
    // Add node names from inspect_gltf.py output
    'Hips',
    'YourLowerBodyNodeName',
    // ... more nodes
  ];
  
  for (final name in lowerBodyNames) {
    if (_nodesByName.containsKey(name)) {
      _nodesByName[name]!.visible = false;
    }
  }
}
```

## Coordinate System Mapping

### MediaPipe Coordinate System
- **X-axis**: Right (+) / Left (-)
- **Y-axis**: Down (+) / Up (-)  
- **Z-axis**: Forward toward camera (+) / Away (-)
- **Range**: Normalized 0.0 to 1.0 (relative to image frame)

### 3D Model Coordinate System (typically)
- **X-axis**: Right (+) / Left (-)
- **Y-axis**: Up (+) / Down (-)
- **Z-axis**: Forward (+) / Back (-)

### Conversion in Code

The widget already includes coordinate conversion:

```dart
final modelDir = vm.Vector3(
  direction.x,      // X stays same
  -direction.y,     // Flip Y (MediaPipe down → Model up)
  -direction.z,     // Flip Z (MediaPipe toward → Model forward)
);
```

**You may need to adjust these** based on your model's orientation!

### Testing Coordinate Mapping

1. **Show hand with palm facing camera**
2. **Check if model hand matches orientation**
3. **If inverted/rotated, adjust the flip signs**

Common adjustments:
- Model upside down? Change `-direction.y` to `direction.y`
- Model backward? Change `-direction.z` to `direction.z`
- Model mirrored? Change `direction.x` to `-direction.x`

## Troubleshooting

### Issue: Packages Not Found

**Error:** `flutter_gl` or `three_dart` not found

**Solution:**
```bash
# Check available versions
flutter pub outdated

# Try different versions in pubspec.yaml
flutter_gl: ^0.0.6  # or latest available
three_dart: ^0.0.16  # or latest available
```

**Alternative:** Use WebView approach (see below)

### Issue: Model Doesn't Load

**Symptoms:** Black screen or loading forever

**Debug steps:**
1. Check console output: `flutter logs`
2. Look for error messages in status overlay
3. Verify GLB file is valid: Open in Blender or online viewer
4. Check file size: Very large models may timeout

```dart
// Add more debug logging in _loadModel():
debugPrint('Loading model from: ${widget.modelAssetPath}');
debugPrint('Bytes loaded: ${bytes.length}');
```

### Issue: Model Visible But Not Animating

**Possible causes:**
1. Bone names don't match → Run `inspect_gltf.py`
2. No landmarks being received → Check Bluetooth connection
3. Coordinate system mismatch → Adjust flip signs

**Debug:**
```dart
// Add to _applyLandmarksToModel():
debugPrint('Received ${landmarks.length} landmarks');
debugPrint('Wrist bone found: ${wristBone != null}');
```

### Issue: Lower Body Still Visible

**Solution:** Run `inspect_gltf.py` to find exact node names, then update `_hideLowerBody()` with those names.

### Issue: Hand Movements Jittery

**Solution:** Adjust smoothing factor:
```dart
static const double _smoothingFactor = 0.2; // Lower = smoother but slower
```

### Issue: App Crashes on Model Load

**Possible causes:**
1. Out of memory (model too complex)
2. Texture loading failure
3. Incompatible GLB version

**Solutions:**
- Simplify model in Blender (reduce poly count)
- Ensure textures are in assets folder
- Re-export GLB as GLTF 2.0 format

## Advanced Customization

### Full Finger Bone Mapping

For precise finger control, map all finger segments:

```dart
void _applyFingerBones(List<vm.Vector3> landmarks) {
  // Thumb: landmarks 1-4 → bones Thumb1, Thumb2, Thumb3
  _mapFingerSegment(landmarks[1], landmarks[2], 'Thumb1');
  _mapFingerSegment(landmarks[2], landmarks[3], 'Thumb2');
  _mapFingerSegment(landmarks[3], landmarks[4], 'Thumb3');
  
  // Index: landmarks 5-8 → bones Index1, Index2, Index3
  _mapFingerSegment(landmarks[5], landmarks[6], 'Index1');
  // ... repeat for each finger
}

void _mapFingerSegment(vm.Vector3 base, vm.Vector3 tip, String boneName) {
  if (!_bonesByName.containsKey(boneName)) return;
  
  final direction = vm.Vector3.copy(tip)..sub(base)..normalize();
  final quat = _quaternionFromVectors(vm.Vector3(0, 1, 0), direction);
  final smoothed = _smoothQuaternion(boneName, quat);
  
  _bonesByName[boneName]!.quaternion.copy(
    three.Quaternion(smoothed.x, smoothed.y, smoothed.z, smoothed.w)
  );
}
```

### Camera Controls

Add orbit controls for better viewing:

```dart
// Add to _initGL():
final controls = three.OrbitControls(_camera!, _glPlugin.element);
controls.enableDamping = true;
controls.dampingFactor = 0.05;

// Update in _animate():
controls.update();
```

### Multiple Hand Support

Track both hands:

```dart
final Stream<List<vm.Vector3>> leftHandStream;
final Stream<List<vm.Vector3>> rightHandStream;

// In _applyLandmarksToModel:
if (isLeftHand) {
  // Use left hand bones
} else {
  // Use right hand bones
}
```

### Export Custom Animations

Record hand movements and export as animation clips:

```dart
final animationClips = <three.AnimationClip>[];

void recordFrame(List<vm.Vector3> landmarks) {
  // Store bone rotations
  final frame = _captureCurrentPose();
  animationClips.add(frame);
}
```

## Alternative: WebView Approach

If `flutter_gl` / `three_dart` don't work, use WebView with `<model-viewer>`:

### 1. Create HTML file

**File:** `assets/web/model_viewer.html`

```html
<!DOCTYPE html>
<html>
<head>
  <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
</head>
<body style="margin:0; background:#1a1a1a;">
  <model-viewer 
    id="model"
    src="/assets/models/breen.glb" 
    auto-rotate 
    camera-controls
    style="width:100%; height:100%;">
  </model-viewer>
  
  <script>
    const modelViewer = document.querySelector('#model');
    
    // Listen for landmark data from Flutter
    window.addEventListener('message', (event) => {
      const landmarks = JSON.parse(event.data);
      updateModelPose(landmarks);
    });
    
    function updateModelPose(landmarks) {
      // Apply landmark data to model
      // This requires custom animation logic
    }
  </script>
</body>
</html>
```

### 2. Use WebView in Flutter

```dart
import 'package:webview_flutter/webview_flutter.dart';

class GlbHandMappingWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'assets/web/model_viewer.html',
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}
```

## Next Steps

1. ✅ Run `flutter pub get` to install dependencies
2. ✅ Run `python inspect_gltf.py assets/models/breen.glb`
3. ✅ Update bone names in `glb_hand_mapping_widget.dart`
4. ✅ Test model loading in Illustration tab
5. ✅ Connect MediaPipe landmark stream
6. ✅ Fine-tune coordinate mapping
7. ✅ Test with real hand tracking

## Resources

- **Flutter GL Package**: https://pub.dev/packages/flutter_gl
- **Three Dart Package**: https://pub.dev/packages/three_dart
- **MediaPipe Hands**: https://google.github.io/mediapipe/solutions/hands
- **GLTF Specification**: https://github.com/KhronosGroup/glTF
- **Blender GLB Export**: https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html

## Support

If you encounter issues:
1. Check console logs: `flutter logs`
2. Run model inspection: `python inspect_gltf.py`
3. Verify assets are loaded: Check status overlay in app
4. Review coordinate transforms: Add debug print statements

## Summary

**What's Ready:**
- ✅ Assets (model + textures) in place
- ✅ Dependencies added to pubspec.yaml
- ✅ Widget implementation complete
- ✅ UI integration in illustration tab
- ✅ Inspection script provided

**What You Need to Do:**
- ⚠️ Run `flutter pub get` (may need version adjustments)
- ⚠️ Run `inspect_gltf.py` to get exact bone names
- ⚠️ Update bone name mappings in widget
- ⚠️ Test and tune coordinate transforms
- ⚠️ Connect to MediaPipe landmark stream

Good luck with your 3D hand visualization! 🚀👋

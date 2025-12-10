# 🎯 Quick Start - Speech-to-Text Integration

## ✅ What's Already Done

Your React speech-to-text app is **fully styled** and **ready to use**! Here's what was updated:

### 🎨 Styling Updates
- ✅ Colors match your Flutter app exactly (`#F5EAFF` background)
- ✅ Urbanist font throughout
- ✅ HandSpeaks**PRO** logo with black badge
- ✅ Green gradient microphone button (140px)
- ✅ Pink gradient when recording
- ✅ Glass morphism transcription cards
- ✅ Smooth animations and transitions

### 📦 Files Updated
- ✅ `src/index.css` - Global styles & color palette
- ✅ `src/App.css` - Main layout & status indicators
- ✅ `src/components/MicrophoneButton.css` - Button styling
- ✅ `src/components/TranscriptionDisplay.css` - Card styling

## 🚀 How to Run

### Step 1: Build the React App
```powershell
cd C:\Users\HP\Downloads\sih\ISL_App\appv1\speech-to-text
npm run build
```

### Step 2: Copy to Flutter Assets
```powershell
# Copy build output to Flutter assets
Copy-Item -Path "dist\*" -Destination "..\assets\web\" -Recurse -Force
```

### Step 3: Run Flutter App
```powershell
cd ..
flutter run
```

### Step 4: Navigate to Speech-to-Text
In your Flutter app:
1. Select "Abled → Sign" mode
2. Tap "Translate" tab
3. The React page loads automatically!

## 🔑 Setting Your Deepgram API Key

### In Flutter Code
Edit `lib/pages/Abled_to_Sign/SpeechToTextPage.dart`:

```dart
Future<void> _sendApiKeyToWebView() async {
  // Replace with your actual API key
  const String apiKey = 'YOUR_DEEPGRAM_API_KEY_HERE';
  
  final message = jsonEncode({
    'type': 'DEEPGRAM_API_KEY',
    'apiKey': apiKey,
  });
  
  await _controller?.runJavaScript('''
    window.postMessage($message, '*');
  ''');
}
```

### Get Your API Key
1. Go to https://deepgram.com
2. Sign up / Log in
3. Navigate to Dashboard → API Keys
4. Create new key or copy existing one
5. Paste into Flutter code above

## 🎨 Color Reference

Your app now uses these exact colors:

| Element | Color | Hex Code |
|---------|-------|----------|
| Background | Lavender Grey | `#F5EAFF` |
| Primary Text | Pure Black | `#000000` |
| Secondary Text | Grey Black | `#6A6F7D` |
| Ready Button | Teal Green | `#6FB5A8` |
| Recording Button | Soft Pink | `#FF9B9B` |
| Error Background | Light Red | `#FFE3E3` |
| Card Background | White (80%) | `rgba(255,255,255,0.8)` |

## 📱 What You'll See

### Initial State
```
┌─────────────────────────────────┐
│      HandSpeaks PRO             │
│                                 │
│    Speech to Text               │
│    Speak clearly into mic       │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Transcription          │   │
│  │  ┌──────────────────┐   │   │
│  │  │  🎤              │   │   │
│  │  │  Your transcript │   │   │
│  │  │  will appear here│   │   │
│  │  └──────────────────┘   │   │
│  └─────────────────────────┘   │
│                                 │
│         ( GREEN CIRCLE )        │
│       🎤 Microphone 140px       │
│                                 │
│    Tap to start recording       │
│                                 │
│    Powered by Deepgram          │
└─────────────────────────────────┘
```

### Recording State
```
┌─────────────────────────────────┐
│      HandSpeaks PRO             │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Transcription    Clear │   │
│  │  ┌──────────────────┐   │   │
│  │  │ Hello world      │   │   │
│  │  │ How are you      │   │   │
│  │  │ doing today...   │   │   │
│  │  └──────────────────┘   │   │
│  │  9 words                │   │
│  └─────────────────────────┘   │
│                                 │
│    ( PINK CIRCLE + RIPPLES )    │
│       ⏹️ Stop Button             │
│                                 │
│    ● Recording                  │
│    (with animated green dot)    │
└─────────────────────────────────┘
```

## 🧪 Testing Checklist

- [ ] Build completes without errors
- [ ] Assets copied to Flutter project
- [ ] Flutter app launches
- [ ] React page loads in WebView
- [ ] API key is sent from Flutter
- [ ] Microphone button appears (green)
- [ ] Tap button → Changes to pink
- [ ] Speak → Text appears in card
- [ ] Text updates in real-time
- [ ] Stop button works
- [ ] Clear button works
- [ ] Styling matches screenshots

## 🐛 Quick Fixes

### "npm: command not found"
**Install Node.js**: https://nodejs.org/

### "Build failed"
```powershell
# Clean and rebuild
Remove-Item -Path "node_modules" -Recurse -Force
npm install
npm run build
```

### "Styling looks wrong"
- Check Urbanist font is loaded in `public/index.html`
- Clear browser cache
- Rebuild the app

### "No API key received"
- Check Flutter is sending postMessage
- Verify WebView JavaScript is enabled
- Check browser console for errors

## 📂 File Structure After Build

```
appv1/
├── assets/
│   └── web/                    ← React build output goes here
│       ├── index.html
│       ├── assets/
│       │   ├── index-[hash].js
│       │   └── index-[hash].css
│       └── ...
├── speech-to-text/
│   ├── src/                   ← Your React source code
│   ├── dist/                  ← Build output (copy to assets/web/)
│   └── package.json
└── lib/
    └── pages/
        └── Abled_to_Sign/
            └── SpeechToTextPage.dart  ← Loads the React app
```

## 🎯 Next Steps

1. **Get Deepgram API Key** (if you don't have one)
2. **Add it to Flutter code** (SpeechToTextPage.dart)
3. **Build React app** (`npm run build`)
4. **Copy to assets** (see Step 2 above)
5. **Run Flutter app** (`flutter run`)
6. **Test on device** (grant mic permissions)

## 💡 Pro Tips

### Faster Development
```powershell
# Watch mode - auto-rebuild on changes
npm run dev
# Then copy dist/ to assets/web/ after each change
```

### Multiple Languages
Edit `App.jsx`:
```javascript
// Change language parameter
'wss://api.deepgram.com/v1/listen?language=hi'  // Hindi
'wss://api.deepgram.com/v1/listen?language=es'  // Spanish
```

### Custom Styling
All colors are in `src/index.css` under `:root` variables.
Change them to customize the look!

## 📞 Need Help?

- **React issues**: Check `speech-to-text/README.md`
- **Flutter issues**: Check Flutter console logs
- **API issues**: Check Deepgram dashboard for usage

---

**Your speech-to-text is ready! 🎉**

Just add your Deepgram API key and build the app!

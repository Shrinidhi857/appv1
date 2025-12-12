import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:glass/glass.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({Key? key}) : super(key: key);

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  // Vosk implementation coming next
  bool _isListening = false;
  String _text = "Tap the microphone to start speaking...";
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HandSpeaks',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.pureBlack,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 2),
                color: AppColors.pureBlack,
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Speech to Text',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offline & Native',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transcription Display
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transcription',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF666666),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFF666666)),
                          onPressed: () {
                            setState(() {
                              _text = "Tap the microphone to start speaking...";
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _text,
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 24,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: _text.startsWith("Tap") ? Colors.grey : AppColors.pureBlack,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).asGlass(
                tintColor: Colors.transparent,
                clipBorderRadius: BorderRadius.circular(30),
                blurX: 10,
                blurY: 10,
              ),
            ),

            // Microphone Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isListening = !_isListening;
                    if (_isListening) {
                      _text = "Listening... (Model downloading...)";
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening ? const Color(0xFFFF9B9B) : const Color(0xFF00C853),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? const Color(0xFFFF9B9B) : const Color(0xFF00C853)).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

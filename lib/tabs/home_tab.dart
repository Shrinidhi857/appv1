import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/frostedglass.dart';
import '../theme/app_colors.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<String> _randomWords = [];
  String _generatedSentence = '';
  bool _isSpeakerEnabled = false;
  Timer? _wordTimer;
  Timer? _sentenceTimer;

  final List<String> _sampleWords = [
    'hello', 'world', 'I', 'happy', 'come', 'Look', 'Eat',
    'with', 'now', 'your', 'food', 'We',
  ];

  final List<String> _sampleSentences = [
    'I am happy',
    'We go now',
    'Come with me',
    'Eat your food',
    'Look at me',
  ];

  @override
  void initState() {
    super.initState();
    _startWordGeneration();
    _startSentenceGeneration();
  }

  void _startWordGeneration() {
    _wordTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          if (_randomWords.length >= 8) {
            _randomWords.removeAt(0);
          }
          _randomWords.add(_sampleWords[Random().nextInt(_sampleWords.length)]);
        });
      }
    });
  }

  void _startSentenceGeneration() {
    _sentenceTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _generatedSentence = _sampleSentences[Random().nextInt(_sampleSentences.length)];
        });
      }
    });
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _sentenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ---- Raw Output Field ----
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.15),
                              Colors.red.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.sensors,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Raw Output',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x75F436FF),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _randomWords.map((word) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        word,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Sentence Generation Field ----
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FrostedCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Generated Output',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green,
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
                                color: _isSpeakerEnabled ? Colors.blue : AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSpeakerEnabled = !_isSpeakerEnabled;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            key: ValueKey(_generatedSentence),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _generatedSentence.isEmpty
                                        ? 'Waiting for input...'
                                        : _generatedSentence,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: _generatedSentence.isEmpty
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      fontStyle: _generatedSentence.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ),
                                if (_generatedSentence.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(left: 10),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Note: You need to add this import at the top of the file:
// import 'dart:ui';
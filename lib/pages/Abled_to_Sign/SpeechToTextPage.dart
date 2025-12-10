import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../../theme/app_colors.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({Key? key}) : super(key: key);

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  WebViewController? _controller;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize WebView controller
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF0EBF4))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) async {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              // Send API key to React app after page loads
              await _sendApiKeyToWebView();
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _error = 'Failed to load page: ${error.description}';
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'ReactNativeWebView',
          onMessageReceived: (JavaScriptMessage message) {
            // Handle messages from React app
            _handleMessageFromWebView(message.message);
          },
        );

      // Load HTML content with proper base URL for Android
      final String htmlContent = await rootBundle.loadString('assets/web/index.html');
      final String baseUrl = 'file:///android_asset/flutter_assets/assets/web/';
      
      await controller.loadHtmlString(
        htmlContent,
        baseUrl: baseUrl,
      );
      
      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error initializing WebView: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendApiKeyToWebView() async {
    if (_controller == null) return;
    
    try {
      // Retrieve API key from secure storage
      String? apiKey = await _secureStorage.read(key: 'deepgram_api_key');
      
      if (apiKey != null && apiKey.isNotEmpty) {
        // Send API key to React app via postMessage
        final message = jsonEncode({
          'type': 'DEEPGRAM_API_KEY',
          'apiKey': apiKey,
        });
        
        await _controller!.runJavaScript('''
          window.postMessage($message, '*');
        ''');
      } else {
        // No API key found - show dialog to enter it
        if (mounted) {
          _showApiKeyDialog();
        }
      }
    } catch (e) {
      print('Error sending API key: $e');
    }
  }

  void _handleMessageFromWebView(String message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'REQUEST_API_KEY') {
        // React app is requesting the API key
        _sendApiKeyToWebView();
      }
    } catch (e) {
      print('Error handling message from WebView: $e');
    }
  }

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Enter Deepgram API Key',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: apiKeyController,
            decoration: InputDecoration(
              hintText: 'Your Deepgram API key',
              hintStyle: TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF00C853),
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiKey = apiKeyController.text.trim();
                if (apiKey.isNotEmpty) {
                  // Save API key to secure storage
                  await _secureStorage.write(
                    key: 'deepgram_api_key',
                    value: apiKey,
                  );
                  Navigator.of(context).pop();
                  // Send API key to WebView
                  await _sendApiKeyToWebView();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EBF4),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.pureBlack),
            onPressed: _showApiKeyDialog,
            tooltip: 'Update API Key',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                        _initializeWebView();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: AppColors.pureWhite,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: const Color(0xFFF0EBF4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

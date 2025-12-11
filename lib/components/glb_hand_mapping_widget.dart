import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// WebView-based 3D GLB hand model viewer using Google Model Viewer
class GlbHandMappingWidget extends StatefulWidget {
  final String modelAssetPath;
  final Stream<List<vm.Vector3>> handLandmarksStream;

  const GlbHandMappingWidget({
    required this.modelAssetPath,
    required this.handLandmarksStream,
    Key? key,
  }) : super(key: key);

  @override
  State<GlbHandMappingWidget> createState() => _GlbHandMappingWidgetState();
}

class _GlbHandMappingWidgetState extends State<GlbHandMappingWidget> {
  late final WebViewController _controller;
  StreamSubscription<List<vm.Vector3>>? _landmarksSub;
  bool _isReady = false;
  int _landmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _subscribeLandmarks();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a1a))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('Received from WebView: ${message.message}');
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'ready') {
              setState(() => _isReady = true);
              debugPrint('WebView is ready for landmark data');
            }
          } catch (e) {
            debugPrint('Error parsing WebView message: $e');
          }
        },
      )
      ..loadFlutterAsset('assets/web/model_viewer.html');
  }

  void _subscribeLandmarks() {
    _landmarksSub = widget.handLandmarksStream.listen(
      (landmarks) {
        if (_isReady && landmarks.length >= 21) {
          _sendLandmarksToWebView(landmarks);
        }
      },
      onError: (error) {
        debugPrint('Landmark stream error: $error');
      },
    );
  }

  void _sendLandmarksToWebView(List<vm.Vector3> landmarks) {
    final landmarksList = landmarks
        .map((v) => {'x': v.x, 'y': v.y, 'z': v.z})
        .toList();

    final message = jsonEncode({
      'type': 'landmarks',
      'landmarks': landmarksList,
    });

    _controller.runJavaScript('''
      window.postMessage($message, '*');
    ''');

    setState(() => _landmarkCount++);
  }

  @override
  void dispose() {
    _landmarksSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1a1a1a),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_landmarkCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB5A8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_landmarkCount frames',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

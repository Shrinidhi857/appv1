import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Model for Hand Landmark Data
class HandLandmark {
  final double x, y, z;
  HandLandmark({required this.x, required this.y, required this.z});

  factory HandLandmark.fromJson(Map<String, dynamic> json) {
    return HandLandmark(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      z: json['z'].toDouble(),
    );
  }
}

class HandFeatures {
  final double thumbDistance;
  final double indexDistance;
  final double handSize;

  HandFeatures({
    required this.thumbDistance,
    required this.indexDistance,
    required this.handSize,
  });

  factory HandFeatures.fromJson(Map<String, dynamic> json) {
    return HandFeatures(
      thumbDistance: json['thumb_distance'].toDouble(),
      indexDistance: json['index_distance'].toDouble(),
      handSize: json['hand_size'].toDouble(),
    );
  }
}

class HandData {
  final int handIndex;
  final String label;
  final double confidence;
  final List<HandLandmark> landmarks;
  final HandFeatures features;

  HandData({
    required this.handIndex,
    required this.label,
    required this.confidence,
    required this.landmarks,
    required this.features,
  });

  factory HandData.fromJson(Map<String, dynamic> json) {
    var landmarksList = json['landmarks'] as List;
    List<HandLandmark> landmarksData = landmarksList
        .map((landmark) => HandLandmark.fromJson(landmark))
        .toList();

    return HandData(
      handIndex: json['hand_index'],
      label: json['label'],
      confidence: json['confidence'].toDouble(),
      landmarks: landmarksData,
      features: HandFeatures.fromJson(json['features']),
    );
  }
}

class LandmarkDataPacket {
  final double timestamp;
  final int handsCount;
  final List<HandData> hands;

  LandmarkDataPacket({
    required this.timestamp,
    required this.handsCount,
    required this.hands,
  });

  factory LandmarkDataPacket.fromJson(Map<String, dynamic> json) {
    var handsList = json['hands'] as List;
    List<HandData> hands = handsList
        .map((hand) => HandData.fromJson(hand))
        .toList();

    return LandmarkDataPacket(
      timestamp: json['timestamp'].toDouble(),
      handsCount: json['hands_count'],
      hands: hands,
    );
  }
}

/// Landmark Data Screen - Visualizes received hand landmarks
class LandmarkDataScreen extends StatefulWidget {
  final BluetoothDevice device;
  const LandmarkDataScreen({super.key, required this.device});

  @override
  State<LandmarkDataScreen> createState() => _LandmarkDataScreenState();
}

class _LandmarkDataScreenState extends State<LandmarkDataScreen> {
  BluetoothConnection? connection;
  bool connected = false;
  String connectionStatus = "Connecting...";

  LandmarkDataPacket? latestData;
  int packetsReceived = 0;
  String buffer = "";

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() async {
    setState(() => connectionStatus = "Connecting to ${widget.device.name}...");

    try {
      BluetoothConnection conn = await BluetoothConnection.toAddress(
        widget.device.address,
      );

      setState(() {
        connection = conn;
        connected = true;
        connectionStatus = "Connected ✓";
      });

      // Listen to incoming data stream
      conn.input!.listen(
        _onDataReceived,
        onDone: () {
          setState(() {
            connected = false;
            connectionStatus = "Disconnected";
          });
        },
      );
    } catch (e) {
      setState(() {
        connectionStatus = "Connection failed: $e";
      });
    }
  }

  void _onDataReceived(Uint8List data) {
    // Convert bytes to string and add to buffer
    String chunk = utf8.decode(data);
    buffer += chunk;

    // Process complete JSON messages (delimited by newline)
    List<String> lines = buffer.split('\n');

    // Keep incomplete line in buffer
    buffer = lines.removeLast();

    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        Map<String, dynamic> json = jsonDecode(line);
        LandmarkDataPacket packet = LandmarkDataPacket.fromJson(json);

        setState(() {
          latestData = packet;
          packetsReceived++;
        });
      } catch (e) {
        print("Error parsing JSON: $e");
      }
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? "Handspeaks"),
        backgroundColor: connected ? Colors.green : Colors.grey,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                connectionStatus,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: connected ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  connected ? "🟢 Receiving landmarks..." : "🔴 Not connected",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Packets: $packetsReceived",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // Data visualization
          Expanded(
            child: latestData == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Waiting for hand landmark data..."),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header info
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hands Detected: ${latestData!.handsCount}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Timestamp: ${latestData!.timestamp.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hand data
                        ...latestData!.hands.map(
                          (hand) => _buildHandCard(hand),
                        ),

                        // Visual representation
                        if (latestData!.hands.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Hand Visualization",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 300,
                                    child: CustomPaint(
                                      painter: HandLandmarkPainter(
                                        latestData!.hands[0],
                                      ),
                                      size: const Size(double.infinity, 300),
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
        ],
      ),
    );
  }

  Widget _buildHandCard(HandData hand) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${hand.label} Hand",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    "Confidence: ${(hand.confidence * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Features:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureChip("Thumb", hand.features.thumbDistance),
                _buildFeatureChip("Index", hand.features.indexDistance),
                _buildFeatureChip("Size", hand.features.handSize),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Landmarks: ${hand.landmarks.length} points",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to visualize hand landmarks
class HandLandmarkPainter extends CustomPainter {
  final HandData handData;

  HandLandmarkPainter(this.handData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw landmarks
    for (var landmark in handData.landmarks) {
      final x = landmark.x * size.width;
      final y = landmark.y * size.height;
      canvas.drawCircle(Offset(x, y), 5, paint);
    }

    // Draw connections (simplified - thumb, index, middle, ring, pinky)
    final connections = [
      [0, 1, 2, 3, 4], // Thumb
      [0, 5, 6, 7, 8], // Index
      [0, 9, 10, 11, 12], // Middle
      [0, 13, 14, 15, 16], // Ring
      [0, 17, 18, 19, 20], // Pinky
    ];

    for (var connection in connections) {
      for (int i = 0; i < connection.length - 1; i++) {
        final start = handData.landmarks[connection[i]];
        final end = handData.landmarks[connection[i + 1]];
        canvas.drawLine(
          Offset(start.x * size.width, start.y * size.height),
          Offset(end.x * size.width, end.y * size.height),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

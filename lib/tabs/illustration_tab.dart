// File: illustration_tab.dart
import 'package:flutter/material.dart';
import '../bluetooth/landmark_receiver.dart';
import '../landmark_bus.dart'; // Use shared singleton
import '../components/glb_hand_mapping_widget.dart'; // 3D model viewer

class IllustrationTab extends StatefulWidget {
  const IllustrationTab({super.key});
  @override
  State<IllustrationTab> createState() => _IllustrationTabState();
}

class _IllustrationTabState extends State<IllustrationTab> {
  // Use shared landmarkBus instead of local receiver
  // landmarkBus is fed by device_tab.dart polling from RPi

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LandmarkDataPacket>(
      stream: landmarkBus.stream, // Shared stream from device_tab
      builder: (context, snap) {
        final hasData = snap.hasData && snap.data!.hands.isNotEmpty;
        final state = snap.data;

        return Column(
          children: [
            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: hasData
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              child: Text(
                hasData
                    ? '🟢 LIVE - ${state!.handsCount} hand(s) detected'
                    : '⚪ Waiting for RPi data...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasData ? Colors.green : Colors.grey,
                ),
              ),
            ),

            // 3D Model Viewer (takes most space)
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF1a1a1a),
                child: hasData
                    ? const GlbHandMappingWidget(
                        modelAssetPath: 'assets/models/breen.glb',
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.threed_rotation,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '3D Hand Model',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect to RPi to see live hand tracking',
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Landmark data list (bottom section)
            if (hasData)
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: state!.hands.length,
                    itemBuilder: (ctx, i) {
                      final hand = state.hands[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.pan_tool,
                          color: hand.label == 'Left'
                              ? Colors.blue
                              : Colors.orange,
                          size: 20,
                        ),
                        title: Text(
                          '${hand.label} Hand',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${hand.landmarks.length} points • ${(hand.confidence * 100).toStringAsFixed(0)}% confidence',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Text(
                          '${state.timestamp.toStringAsFixed(1)}s',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          _showLandmarkDetails(context, hand, i + 1);
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showLandmarkDetails(
    BuildContext context,
    HandData hand,
    int handNumber,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Landmarks - Hand $handNumber (${hand.label})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: hand.landmarks.length,
            itemBuilder: (_, idx) {
              final lm = hand.landmarks[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '[$idx] x:${lm.x.toStringAsFixed(3)} y:${lm.y.toStringAsFixed(3)} z:${lm.z.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

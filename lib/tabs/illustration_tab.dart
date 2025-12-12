// File: illustration_tab.dart
import 'package:flutter/material.dart';
import '../bluetooth/landmark_receiver.dart';

class IllustrationTab extends StatefulWidget {
  const IllustrationTab({super.key});
  @override
  State<IllustrationTab> createState() => _IllustrationTabState();
}

class _IllustrationTabState extends State<IllustrationTab> {
  // If you keep a single instance of LandmarkReceiver elsewhere, you should pass it down.
  // For the demo, we'll create a local receiver and expect to be fed by the connection page.
  // In your app you should share the same LandmarkReceiver instance.
  final LandmarkReceiver _receiver = LandmarkReceiver();

  @override
  void dispose() {
    _receiver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LandmarkDataPacket>(
      stream: _receiver.stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.hands.isEmpty) {
          return const Center(child: Text('No landmarks yet'));
        }
        final state = snap.data!;
        return Column(
          children: [
            Text('Timestamp: ${state.timestamp.toStringAsFixed(2)}'),
            Text('Hands: ${state.handsCount}'),
            Expanded(
              child: ListView.builder(
                itemCount: state.hands.length,
                itemBuilder: (ctx, i) {
                  final hand = state.hands[i];
                  return ListTile(
                    leading: const Icon(Icons.pan_tool),
                    title: Text('Hand ${i + 1}: ${hand.label}'),
                    subtitle: Text(
                      '${hand.landmarks.length} landmarks | Confidence: ${hand.confidence.toStringAsFixed(2)}',
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Landmarks Hand ${i + 1}'),
                          content: SingleChildScrollView(
                            child: Text(
                              hand.landmarks
                                  .take(20)
                                  .map(
                                    (e) =>
                                        'x:${e.x.toStringAsFixed(3)}, y:${e.y.toStringAsFixed(3)}, z:${e.z.toStringAsFixed(3)}',
                                  )
                                  .join('\n'),
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
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// File: bluetooth_handler.dart
// NOTE: This used to be Bluetooth. It now connects over WebSocket (Wi-Fi).
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../landmark_bus.dart';
import 'landmark_receiver.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  // Keep name for compatibility, but replace IP below in device_tab instead if you prefer
  static const String defaultRPI_IP =
      "192.168.1.100"; // you can change here (or use device_tab)
  static const int RPI_PORT = 8765;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;

  bool _isConnected = false;
  bool _isStreaming = false;
  String _status = "Disconnected";
  final TextEditingController _ipController = TextEditingController(
    text: defaultRPI_IP,
  );

  // Local receiver for this widget's UI
  final LandmarkReceiver _receiver = LandmarkReceiver();

  @override
  void dispose() {
    _stopPing();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _ipController.dispose();
    _receiver.dispose();
    super.dispose();
  }

  void _connect() {
    final ip = _ipController.text.trim();
    final uri = Uri.parse("ws://$ip:$RPI_PORT");

    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      setState(() {
        _isConnected = true;
        _status = "Connected to $ip";
      });

      _startPing();
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = "Connect failed: $e";
      });
      try {
        _channel?.sink.close();
      } catch (_) {}
      _channel = null;
    }
  }

  void _disconnect() {
    _stopPing();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    setState(() {
      _isConnected = false;
      _isStreaming = false;
      _status = "Disconnected";
    });
    _receiver.clear();
    landmarkBus.clear();
  }

  void _sendCommand(String cmd) {
    if (_channel == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not connected")));
      return;
    }
    try {
      _channel!.sink.add(json.encode({"type": "COMMAND", "payload": cmd}));
    } catch (e) {
      debugPrint("SendCommand error: $e");
    }
  }

  void _onMessage(dynamic raw) {
    try {
      if (raw == null) return;
      final String text = raw is String ? raw : utf8.decode(raw as List<int>);
      final Map<String, dynamic> msg = json.decode(text);
      final String? type = msg['type']?.toString();
      final dynamic payload = msg['payload'];

      switch (type) {
        case 'WELCOME':
          setState(() {
            _status = payload?['message']?.toString() ?? "Welcome";
          });
          break;
        case 'STATUS':
          setState(() {
            _isStreaming = payload is Map && payload['streaming'] == true;
            _status = payload?['message']?.toString() ?? _status;
          });
          break;
        case 'LANDMARKS':
          if (payload is Map<String, dynamic>) {
            // Process locally for this widget's UI
            _receiver.processPayload(Map<String, dynamic>.from(payload));
            // Also publish to the shared bus for other tabs
            landmarkBus.processPayload(Map<String, dynamic>.from(payload));
            setState(() {
              _isStreaming = true;
              _status = "Receiving landmarks";
            });
          }
          break;
        case 'PONG':
          // ignore / keepalive ack
          break;
        default:
          // optional telemetry or messages
          debugPrint("Unknown message type: $type");
      }
    } catch (e) {
      debugPrint('onMessage parse error: $e');
    }
  }

  void _onError(Object err) {
    debugPrint('WebSocket error: $err');
    _stopPing();
    setState(() {
      _isConnected = false;
      _isStreaming = false;
      _status = 'Connection error';
    });
  }

  void _onDone() {
    debugPrint('WebSocket done');
    _stopPing();
    setState(() {
      _isConnected = false;
      _isStreaming = false;
      _status = 'Connection closed';
    });
  }

  void _startPing({Duration interval = const Duration(seconds: 10)}) {
    _stopPing();
    _pingTimer = Timer.periodic(interval, (_) {
      if (_channel != null) {
        try {
          _channel!.sink.add(
            json.encode({
              "type": "PING",
              "payload": DateTime.now().toIso8601String(),
            }),
          );
        } catch (e) {
          debugPrint("Ping error: $e");
        }
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // UI - minimal; reuse your app's styling where needed
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HandSpeaks Wi-Fi Control'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'RPi5 Connection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'RPi5 IP Address',
                        hintText: '192.168.1.100',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isConnected ? null : _connect,
                            icon: const Icon(Icons.link),
                            label: const Text('Connect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isConnected ? _disconnect : null,
                            icon: const Icon(Icons.link_off),
                            label: const Text('Disconnect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: _isConnected ? Colors.green[900] : Colors.red[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_isConnected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _sendCommand('start'),
                          child: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    if (_isConnected) const SizedBox(width: 8),
                    if (_isConnected)
                      ElevatedButton(
                        onPressed: () => _sendCommand('stop'),
                        child: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<LandmarkDataPacket>(
                stream: landmarkBus.stream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Center(
                      child: Text(
                        _isConnected
                            ? 'Press START to stream'
                            : 'Connect to RPi5',
                      ),
                    );
                  }
                  final packet = snap.data!;
                  return ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      Text('Timestamp: ${packet.timestamp}'),
                      Text('Hands detected: ${packet.handsCount}'),
                      const SizedBox(height: 8),
                      ...packet.hands.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final hand = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.back_hand),
                          title: Text('Hand ${idx + 1}: ${hand.label}'),
                          subtitle: Text(
                            '${hand.landmarks.length} landmarks • conf ${hand.confidence.toStringAsFixed(2)}',
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

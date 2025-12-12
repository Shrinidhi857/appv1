// lib/device_tab.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:http/http.dart' as http;
import '../components/frostedglass.dart';
import '../theme/app_colors.dart';
import '../landmark_bus.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key});

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> {
  // <-- Change this to your RPi IP (single place)
  static const String defaultRPI_IP =
      "192.168.1.100"; // <-- CHANGE THIS TO YOUR RPI IP
  static const int API_PORT = 8000; // Your RPi landmark stream API port

  Timer? _pollTimer;

  // UI / status
  bool _isConnected = false; // HTTP polling running flag
  bool _isReceiving = false;
  String _connectionStatus = "Not connected";
  String _connectedName = "RPi5";

  // Device controls
  bool _cameraEnabled = true;
  bool _speakerEnabled = true;
  bool _tofSensorEnabled = false;
  bool _microphoneEnabled = true;
  bool _ledEnabled = false;
  final List<String> _receivedMessages = [];

  final TextEditingController _ipController = TextEditingController(
    text: defaultRPI_IP,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopPolling();
    _ipController.dispose();
    super.dispose();
  }

  // -----------------------
  // Connect / Disconnect (HTTP only)
  // -----------------------
  void _connect() {
    _startPolling();
  }

  void _disconnect() {
    _stopPolling();
  }

  // -----------------------
  // HTTP Polling implementation (RPi API on port 5555)
  // -----------------------
  void _startPolling({Duration interval = const Duration(milliseconds: 250)}) {
    final ip = _ipController.text.trim();
    setState(() {
      _connectionStatus = "Starting HTTP polling to $ip:$API_PORT";
      _isConnected = true;
    });

    _pollTimer = Timer.periodic(interval, (_) async {
      try {
        final url = Uri.parse('http://$ip:$API_PORT/landmarks');
        final resp = await http.get(url).timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) {
          final Map<String, dynamic> payload = json.decode(resp.body);
          // Publish landmarks to shared bus for 3D visualization
          landmarkBus.processPayload(payload);
          setState(() {
            _isReceiving = true;
            _connectionStatus = "✓ Receiving landmarks from RPi";
          });
        } else {
          debugPrint("HTTP status: ${resp.statusCode}");
        }
      } catch (e) {
        debugPrint("Polling error: $e");
        setState(() {
          _connectionStatus = "Retrying connection...";
        });
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    setState(() {
      _isConnected = false;
      _isReceiving = false;
      _connectionStatus = "HTTP polling stopped";
    });
  }

  // -----------------------
  // Send command to RPi via HTTP POST
  // -----------------------
  void _sendCommand(String command) {
    final ip = _ipController.text.trim();
    final url = Uri.parse('http://$ip:$API_PORT/command');
    http
        .post(
          url,
          body: json.encode({'command': command}),
          headers: {'Content-Type': 'application/json'},
        )
        .then((resp) {
          if (resp.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✓ Command sent to RPi")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Command error: ${resp.statusCode}")),
            );
          }
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Command send failed: $e")));
        });
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _isConnected ? _buildConnectedView() : _buildConnectionView(),
        ),
      ],
    );
  }

  Widget _buildConnectionView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6BAB90).withOpacity(0.3),
                    const Color(0xFF7BA3BC).withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.wifi, size: 60, color: AppColors.textPrimary),
            ).asGlass(
              enabled: true,
              tintColor: Colors.transparent,
              clipBorderRadius: BorderRadius.circular(60),
              frosted: true,
              blurX: 500,
              blurY: 500,
            ),

            const SizedBox(height: 24),

            FrostedCard(
              child: Column(
                children: [
                  Text(
                    'Connect Your Device (Wi-Fi)',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _connectionStatus,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'RPi5 IP Address',
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.router),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionItem(
                    icon: Icons.power_settings_new,
                    text: "Power on your Handspeaks device (RPi5)",
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    icon: Icons.wifi,
                    text: "Ensure both phone and RPi are on same Wi-Fi network",
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    icon: Icons.settings,
                    text: "Enter RPi IP & tap Connect",
                  ),
                ],
              ),
            ).asGlass(
              enabled: true,
              tintColor: Colors.transparent,
              clipBorderRadius: BorderRadius.circular(20),
              frosted: true,
              blurX: 500,
              blurY: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 180),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF34C759),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34C759).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _connectedName,
                          style: TextStyle(
                            fontFamily: "Urbanist",
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendCommand('start'),
                        child: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _sendCommand('stop'),
                        child: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _disconnect,
                        child: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ).asGlass(
                  enabled: true,
                  tintColor: Colors.transparent,
                  clipBorderRadius: BorderRadius.circular(16),
                  frosted: true,
                  blurX: 500,
                  blurY: 500,
                ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FrostedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Controls',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildControlItem(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    value: _cameraEnabled,
                    onChanged: (val) {
                      setState(() => _cameraEnabled = val);
                      _sendCommand("CAMERA:${val ? 'ON' : 'OFF'}");
                    },
                  ),
                  _buildControlItem(
                    icon: Icons.volume_up,
                    label: "Speaker",
                    value: _speakerEnabled,
                    onChanged: (val) {
                      setState(() => _speakerEnabled = val);
                      _sendCommand("SPEAKER:${val ? 'ON' : 'OFF'}");
                    },
                  ),
                  _buildControlItem(
                    icon: Icons.sensors,
                    label: "ToF Sensor",
                    value: _tofSensorEnabled,
                    onChanged: (val) {
                      setState(() => _tofSensorEnabled = val);
                      _sendCommand("TOF:${val ? 'ON' : 'OFF'}");
                    },
                  ),
                  _buildControlItem(
                    icon: Icons.mic,
                    label: "Microphone",
                    value: _microphoneEnabled,
                    onChanged: (val) {
                      setState(() => _microphoneEnabled = val);
                      _sendCommand("MIC:${val ? 'ON' : 'OFF'}");
                    },
                  ),
                  _buildControlItem(
                    icon: Icons.lightbulb_outline,
                    label: "LED Indicator",
                    value: _ledEnabled,
                    onChanged: (val) {
                      setState(() => _ledEnabled = val);
                      _sendCommand("LED:${val ? 'ON' : 'OFF'}");
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_receivedMessages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FrostedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Messages',
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.pureBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: (_receivedMessages.length > 5
                            ? 5
                            : _receivedMessages.length),
                        itemBuilder: (context, index) {
                          final msg =
                              _receivedMessages[_receivedMessages.length -
                                  1 -
                                  index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              msg,
                              style: TextStyle(
                                fontFamily: "Urbanist",
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6BAB90).withOpacity(0.2),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6BAB90)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: "Urbanist",
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppColors.textPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildIOSStyleSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }

  Widget _buildIOSStyleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? const Color(0xFF34C759) : Colors.grey.withOpacity(0.3),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

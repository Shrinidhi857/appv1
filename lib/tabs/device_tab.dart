import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../components/frostedglass.dart';
import '../theme/app_colors.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key});

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> {
  // Bluetooth instances
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;

  // Connection states
  bool _isConnected = false;
  bool _isSearching = false;
  bool _autoConnecting = false;
  String _connectionStatus = "Not connected";

  // Device controls
  bool _cameraEnabled = true;
  bool _speakerEnabled = true;
  bool _tofSensorEnabled = false;
  bool _microphoneEnabled = true;
  bool _ledEnabled = false;

  // Data from device
  String _batteryLevel = "87%";
  String _latency = "42 ms";
  final List<String> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // BLUETOOTH INITIALIZATION & CONNECTION
  // -----------------------------------------------------------

  void _initializeBluetooth() async {
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == null || !isEnabled) {
      setState(() => _connectionStatus = "Bluetooth is OFF");
      await _bluetooth.requestEnable();
    }
  }

  void _startSearching() async {
    setState(() {
      _isSearching = true;
      _connectionStatus = "Scanning for Handspeaks...";
      _devices.clear();
    });

    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      print("Cancel discovery error: $e");
    }

    var subscription = _bluetooth.startDiscovery();
    subscription.listen((result) {
      final device = result.device;

      // Add to list if not already present
      if (!_devices.any((d) => d.address == device.address)) {
        setState(() => _devices.add(device));
      }

      // Auto-connect to "Handspeaks" when found
      if (!_autoConnecting &&
          device.name != null &&
          device.name!.toLowerCase().contains('handspeaks')) {
        setState(() => _autoConnecting = true);
        _autoConnectToDevice(device);
      }
    }).onDone(() {
      setState(() {
        _isSearching = false;
        if (!_autoConnecting) {
          _connectionStatus = _devices.isEmpty
              ? "No devices found"
              : "Scan complete";
        }
      });
    });
  }

  void _autoConnectToDevice(BluetoothDevice device) async {
    try {
      await _bluetooth.cancelDiscovery();
      setState(() {
        _isSearching = false;
        _connectionStatus = "Connecting to ${device.name}...";
      });
    } catch (e) {
      print("Cancel discovery error: $e");
    }

    await _connectToDevice(device);
  }

  void _manualConnectToDevice(BluetoothDevice device) async {
    try {
      await _bluetooth.cancelDiscovery();
      setState(() => _isSearching = false);
    } catch (e) {
      print("Cancel discovery error: $e");
    }

    await _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _connectionStatus = "Connecting...");

    try {
      // Bond device if not already bonded
      if (!device.isBonded) {
        await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
      }

      // Establish connection
      BluetoothConnection conn = await BluetoothConnection.toAddress(device.address);

      setState(() {
        _connection = conn;
        _connectedDevice = device;
        _isConnected = true;
        _connectionStatus = "Connected";
        _autoConnecting = false;
      });

      // Listen for incoming data
      _connection!.input!.listen((Uint8List data) {
        String received = utf8.decode(data).trim();
        setState(() {
          _receivedMessages.add(received);
          // Parse data if it's JSON or specific format
          _parseReceivedData(received);
        });
      }).onDone(() {
        _disconnectDevice();
      });

    } catch (e) {
      setState(() {
        _connectionStatus = "Connection failed: $e";
        _isConnected = false;
        _autoConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnectDevice() {
    _connection?.dispose();
    setState(() {
      _isConnected = false;
      _isSearching = false;
      _autoConnecting = false;
      _connection = null;
      _connectedDevice = null;
      _connectionStatus = "Disconnected";
    });
  }

  void _parseReceivedData(String data) {
    // Example: Parse JSON data from device
    // {"battery": "85%", "latency": "38ms"}
    try {
      final Map<String, dynamic> json = jsonDecode(data);
      setState(() {
        if (json.containsKey('battery')) _batteryLevel = json['battery'];
        if (json.containsKey('latency')) _latency = json['latency'];
      });
    } catch (e) {
      // If not JSON, just store as message
      print("Received non-JSON data: $data");
    }
  }

  void _sendCommand(String command) {
    if (_connection == null || !_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device not connected!")),
      );
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode("$command\n")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Send error: $e")),
      );
    }
  }

  // -----------------------------------------------------------
  // UI BUILD
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _isConnected ? _buildConnectedView() : _buildConnectionView(),
        )
      ],
    );
  }

  // -----------------------------------------------------------
  // Connection View (When Not Connected)
  // -----------------------------------------------------------
  Widget _buildConnectionView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Device Icon
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
              child: Icon(
                Icons.bluetooth,
                size: 60,
                color: AppColors.textPrimary,
              ),
            ).asGlass(
              enabled: true,
              tintColor: Colors.transparent,
              clipBorderRadius: BorderRadius.circular(60),
              frosted: true,
              blurX: 500,
              blurY: 500,
            ),

            const SizedBox(height: 32),

            // Connection Card
            FrostedCard(
              child: Column(
                children: [
                  Text(
                    _isSearching ? 'Searching for Handspeaks...' : 'Connect Your Device',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Searching Animation or Search Button
                  if (_isSearching)
                    Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF6BAB90),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Available Devices Found
                        ..._devices.map((device) => _buildAvailableDevice(device)).toList(),
                      ],
                    )
                  else
                    _buildSearchButton(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionItem(
                    icon: Icons.power_settings_new,
                    text: "Turn on your Handspeaks device",
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    icon: Icons.bluetooth,
                    text: "Enable Bluetooth on your phone",
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    icon: Icons.search,
                    text: "Tap search to find device",
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

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _startSearching,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6BAB90),
              const Color(0xFF7BA3BC),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Search for Device',
              style: TextStyle(
                fontFamily: "Urbanist",
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDevice(BluetoothDevice device) {
    final isHandspeaks = device.name != null &&
        device.name!.toLowerCase().contains('handspeaks');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _manualConnectToDevice(device),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHandspeaks
                  ? const Color(0xFF6BAB90)
                  : const Color(0xFF6BAB90).withOpacity(0.3),
              width: isHandspeaks ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6BAB90).withOpacity(0.2),
                ),
                child: Icon(
                  Icons.bluetooth,
                  color: const Color(0xFF6BAB90),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name ?? 'Unknown Device',
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontWeight: isHandspeaks ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.isBonded ? 'Paired • ${device.address}' : 'Ready to pair',
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ).asGlass(
          enabled: true,
          tintColor: Colors.transparent,
          clipBorderRadius: BorderRadius.circular(16),
          frosted: true,
          blurX: 300,
          blurY: 300,
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6BAB90).withOpacity(0.2),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF6BAB90),
          ),
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

  // -----------------------------------------------------------
  // Connected View (Device Controls with Real Bluetooth)
  // -----------------------------------------------------------
  Widget _buildConnectedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 180),
      child: Container(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Connection Status Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                        '${_connectedDevice?.name ?? "Device"} Connected',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _disconnectDevice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: Text(
                          'Connected',
                          style: TextStyle(
                            fontFamily: "Urbanist",
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
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

            const SizedBox(height: 20),

            // Device Health Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FrostedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Health',
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        _buildHealthMetric(
                          icon: Icons.battery_charging_full,
                          label: "Battery",
                          value: _batteryLevel,
                          color: const Color(0xFF6BAB90),
                        ),
                        const SizedBox(width: 14),
                        _buildHealthMetric(
                          icon: Icons.speed,
                          label: "Latency",
                          value: _latency,
                          color: const Color(0xFF7BA3BC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Device Controls Section
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
                          color: AppColors.pureBlack
                      ),
                    ),

                    const SizedBox(height: 16),

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

            const SizedBox(height: 20),

            // Data Log Section (Optional)
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
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _receivedMessages.length > 5
                              ? 5
                              : _receivedMessages.length,
                          itemBuilder: (context, index) {
                            final msg = _receivedMessages[
                            _receivedMessages.length - 1 - index];
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
          ],
        ),
      ).asGlass(
          enabled: true,
          tintColor: Colors.transparent,
          clipBorderRadius: BorderRadius.circular(25.0),
          frosted: true,
          blurX: 500,
          blurY: 500
      ),
    );
  }

  // -----------------------------------------------------------
  // Mini Frosted Health Metric Card
  // -----------------------------------------------------------
  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 14),

            Text(
              value,
              style: TextStyle(
                  fontFamily: "Urbanist",
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary
              ),
            ),

            Text(
              label,
              style: TextStyle(
                fontFamily: "Urbanist",
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).asGlass(
          enabled: true,
          tintColor: Colors.transparent,
          clipBorderRadius: BorderRadius.circular(25.0),
          frosted: true,
          blurX: 500,
          blurY: 50
      ),
    );
  }

  // -----------------------------------------------------------
  // iPhone-style Control Item
  // -----------------------------------------------------------
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
              Icon(
                icon,
                size: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontFamily: "Urbanist",
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary
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

  // -----------------------------------------------------------
  // iOS-style Toggle Switch
  // -----------------------------------------------------------
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
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'landmark_receiver.dart';

/// Enhanced Bluetooth Page with auto-connect to "Handspeaks"
class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devices = [];
  bool scanning = false;
  bool autoConnecting = false;
  String status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  /* ---------------------------------------------------------- */
  /* INITIALIZATION & AUTO-CONNECT                              */
  /* ---------------------------------------------------------- */
  void _initializeBluetooth() async {
    // Check if Bluetooth is enabled
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == null || !isEnabled) {
      setState(() => status = "Bluetooth is OFF. Please enable it.");
      // Request to enable Bluetooth
      await _bluetooth.requestEnable();
    }

    // Start discovery and look for "Handspeaks"
    _startDiscoveryAndAutoConnect();
  }

  void _startDiscoveryAndAutoConnect() async {
    setState(() {
      scanning = true;
      status = "Scanning for Handspeaks...";
      devices.clear();
    });

    var subscription = _bluetooth.startDiscovery();

    subscription
        .listen((result) {
          final device = result.device;

          // Add to list if not already present
          if (!devices.any((d) => d.address == device.address)) {
            setState(() => devices.add(device));
          }

          // Auto-connect to "Handspeaks" when found
          if (!autoConnecting &&
              device.name != null &&
              device.name!.toLowerCase().contains('handspeaks')) {
            setState(() => autoConnecting = true);
            _autoConnectToDevice(device);
          }
        })
        .onDone(() {
          setState(() {
            scanning = false;
            if (!autoConnecting) {
              status = devices.isEmpty
                  ? "No devices found. Pull to refresh."
                  : "Scan complete. Tap device to connect.";
            }
          });
        });
  }

  // File: bluetooth_page.dart (Inside _BluetoothPageState)

  // File: bluetooth_page.dart (Inside _BluetoothPageState)

  void _autoConnectToDevice(BluetoothDevice device) async {
    // 🛑 FIX A: Stop scanning before attempting to connect
    try {
      await _bluetooth.cancelDiscovery();
      setState(() => scanning = false);
    } catch (e) {
      print("Warning: Failed to cancel discovery: $e");
    }

    setState(() => status = "Found Handspeaks! Connecting...");

    if (!device.isBonded) {
      await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
    }

    // Navigate to Landmark Receiver Screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LandmarkDataScreen(device: device)),
    );
  }

  void _manualConnect(BluetoothDevice device) async {
    // 🛑 FIX B: Stop scanning for manual connect too
    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      print("Warning: Failed to cancel discovery for manual connect: $e");
    }

    if (!device.isBonded) {
      await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
    }

    // Navigate to Landmark Receiver Screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LandmarkDataScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handspeaks Connector'),
        actions: [
          if (scanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanning ? null : _startDiscoveryAndAutoConnect,
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: autoConnecting ? Colors.green.shade100 : Colors.blue.shade50,
            child: Row(
              children: [
                if (autoConnecting || scanning)
                  const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(status, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          status,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final isHandspeaks =
                          device.name != null &&
                          device.name!.toLowerCase().contains('handspeaks');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: isHandspeaks ? Colors.green.shade50 : null,
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: isHandspeaks ? Colors.green : Colors.blue,
                          ),
                          title: Text(
                            device.name ?? "Unknown Device",
                            style: TextStyle(
                              fontWeight: isHandspeaks
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(device.address),
                          trailing: device.isBonded
                              ? const Chip(
                                  label: Text(
                                    "Paired",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                )
                              : null,
                          onTap: () => _manualConnect(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================ */
/* CHAT SCREEN – Receives data from Pi continuously            */
/* ============================================================ */
class _ChatScreen extends StatefulWidget {
  final BluetoothDevice device;
  const _ChatScreen({required this.device});
  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  BluetoothConnection? connection;
  final List<String> messages = [];
  final TextEditingController _tec = TextEditingController();
  bool connected = false;
  String connectionStatus = "Connecting...";

  @override
  void initState() {
    super.initState();
    _connect();
  }

  // File: bluetooth_page.dart (Inside _ChatScreenState)

  void _connect() async {
    setState(() => connectionStatus = "Connecting to ${widget.device.name}...");

    try {
      // 💡 Try 1: Standard Connection (Keep this as primary attempt)
      BluetoothConnection conn = await BluetoothConnection.toAddress(
        widget.device.address,
      );
      // OR: 💡 Try 2: Insecure Connection on Specific Channel (If Try 1 fails)
      // BluetoothConnection conn = await BluetoothConnection.toAddress(
      //     widget.device.address,
      //     secure: false, // Forcing insecure connection
      //     channel: 22    // Match the channel used by the Pi script
      // );

      // ... rest of success logic ...

      setState(() {
        connection = conn;
        connected = true;
        connectionStatus = "Connected ✓";
        messages.add("*** Connected to ${widget.device.name} ***");
      });

      // ... rest of input stream listener ...
    } catch (e) {
      setState(() {
        messages.add("*** Connection failed: $e ***");
        connectionStatus = "Failed to connect";
        // This is the error point from your screenshot!
      });
    }
  }

  void _send() {
    if (connection == null || !connected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not connected!")));
      return;
    }

    final txt = _tec.text.trim();
    if (txt.isEmpty) return;

    _tec.clear();

    try {
      connection!.output.add(Uint8List.fromList(utf8.encode("$txt\n")));
      setState(() => messages.add("📤 Me: $txt"));
      _scrollToBottom();
    } catch (e) {
      setState(() => messages.add("*** Send error: $e ***"));
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    _scrollController.dispose();
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name ?? "Raspberry Pi"),
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
          // Connection indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: connected ? Colors.green.shade100 : Colors.red.shade100,
            child: Text(
              connected ? "🟢 Receiving data from Pi..." : "🔴 Not connected",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("Waiting for data..."))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isFromPi = msg.startsWith("📥");
                      final isSystem = msg.startsWith("***");

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? Colors.grey.shade200
                              : isFromPi
                              ? Colors.blue.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontStyle: isSystem
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tec,
                    decoration: InputDecoration(
                      hintText: "Send message to Pi",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: connected ? _send : null,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

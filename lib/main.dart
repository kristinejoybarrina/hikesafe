import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoRa BLE Input Sender',
      theme: ThemeData.dark(),
      home: const LoRaInputScreen(),
    );
  }
}

class LoRaInputScreen extends StatefulWidget {
  const LoRaInputScreen({super.key});
  @override
  State<LoRaInputScreen> createState() => _LoRaInputScreenState();
}

class _LoRaInputScreenState extends State<LoRaInputScreen> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  final TextEditingController inputController = TextEditingController();
  String status = 'Waiting...';

  final String targetName = 'LoRaBLE';
  final Guid serviceUuid = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  final Guid charUuid = Guid('0000ffe1-0000-1000-8000-00805f9b34fb');

  @override
  void initState() {
    super.initState();
    _startScanAndConnect();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _startScanAndConnect() async {
    await _requestPermissions();

    setState(() => status = 'Scanning for LoRa device...');
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == targetName) {
          setState(() => status = 'Found $targetName. Connecting...');
          await FlutterBluePlus.stopScan();
          try {
            await r.device.connect();
          } catch (_) {}
          connectedDevice = r.device;
          await _discoverServices();
          break;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (var s in services) {
      if (s.uuid == serviceUuid) {
        for (var c in s.characteristics) {
          if (c.uuid == charUuid && c.properties.write) {
            writeCharacteristic = c;
            setState(() => status = 'Connected. Ready to send.');
            return;
          }
        }
      }
    }

    setState(() => status = 'Write characteristic not found.');
  }

  Future<void> _sendMessage() async {
    if (writeCharacteristic == null || inputController.text.isEmpty) return;

    String message = inputController.text;
    try {
      await writeCharacteristic!.write(message.codeUnits);
      setState(() => status = 'Sent: "$message"');
      inputController.clear();
    } catch (e) {
      setState(() => status = 'Send failed: $e');
    }
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoRa BLE Sender')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: 'Enter message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send to LoRa'),
            ),
          ],
        ),
      ),
    );
  }
}

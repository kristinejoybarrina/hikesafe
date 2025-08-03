// FLUTTER CODE (for both Phone A and Phone B, same code)
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoRa BLE Chat',
      theme: ThemeData.dark(),
      home: const LoRaChatScreen(),
    );
  }
}

class LoRaChatScreen extends StatefulWidget {
  const LoRaChatScreen({super.key});

  @override
  State<LoRaChatScreen> createState() => _LoRaChatScreenState();
}

class _LoRaChatScreenState extends State<LoRaChatScreen> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeChar;
  BluetoothCharacteristic? notifyChar;
  final TextEditingController inputController = TextEditingController();
  final List<String> messages = [];

  final String deviceName = 'LoRaAudio';
  final Guid serviceUuid = Guid('12345678-1234-1234-1234-1234567890ab');
  final Guid charUuid = Guid('87654321-4321-4321-4321-ba0987654321');

  @override
  void initState() {
    super.initState();
    _connectToLoRa();
  }

  Future<void> _connectToLoRa() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == deviceName) {
          await FlutterBluePlus.stopScan();
          await r.device.connect();
          connectedDevice = r.device;

          var services = await r.device.discoverServices();
          for (var service in services) {
            if (service.uuid == serviceUuid) {
              for (var char in service.characteristics) {
                if (char.uuid == charUuid) {
                  if (char.properties.write) writeChar = char;
                  if (char.properties.notify) {
                    notifyChar = char;
                    await char.setNotifyValue(true);
                    char.value.listen((value) {
                      String msg = String.fromCharCodes(value);
                      setState(() => messages.add('📩 $msg'));
                    });
                  }
                }
              }
            }
          }
          break;
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    String msg = inputController.text.trim();
    if (msg.isNotEmpty && writeChar != null) {
      await writeChar!.write(msg.codeUnits);
      setState(() => messages.add('📤 $msg'));
      inputController.clear();
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
      appBar: AppBar(title: const Text('LoRa Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => Text(messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: const InputDecoration(
                      labelText: 'Enter message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

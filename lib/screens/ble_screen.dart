import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEScreen extends StatefulWidget {
  const BLEScreen({super.key});

  @override
  State<BLEScreen> createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen> {
  List<BluetoothDevice> connectedDevices = [];

  @override
  void initState() {
    super.initState();
    _scanForDevices();
  }

  void _scanForDevices() async {
    try {
      // Check if Bluetooth is on
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint("Bluetooth not supported by this device");
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!connectedDevices.contains(r.device)) {
            setState(() {
              connectedDevices.add(r.device);
            });
          }
        }
      });

      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Error scanning: $e");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.platformName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Devices')),
      body: ListView.builder(
        itemCount: connectedDevices.length,
        itemBuilder: (context, index) {
          final device = connectedDevices[index];
          return ListTile(
            title: Text(
              device.platformName.isNotEmpty
                  ? device.platformName
                  : device.remoteId.toString(),
            ),
            trailing: ElevatedButton(
              child: const Text("Connect"),
              onPressed: () => _connectToDevice(device),
            ),
          );
        },
      ),
    );
  }
}

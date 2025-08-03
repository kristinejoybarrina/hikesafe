import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HikesafeBluetoothService {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify) {
          notifyCharacteristic = characteristic;
          await notifyCharacteristic!.setNotifyValue(true);
        }
      }
    }
  }

  Future<void> sendMessage(String message) async {
    if (writeCharacteristic == null) return;

    List<int> bytes = utf8.encode(message);
    int mtu = 20; // BLE default packet size

    for (int i = 0; i < bytes.length; i += mtu) {
      int end = (i + mtu < bytes.length) ? i + mtu : bytes.length;
      await writeCharacteristic!.write(
        bytes.sublist(i, end),
        withoutResponse: true,
      );
      await Future.delayed(const Duration(milliseconds: 20)); // prevent overrun
    }
  }

  Stream<List<int>>? receiveMessages() {
    if (notifyCharacteristic == null) return null;
    return notifyCharacteristic!.lastValueStream;
  }

  void disconnect() {
    connectedDevice?.disconnect();
    connectedDevice = null;
    writeCharacteristic = null;
    notifyCharacteristic = null;
  }
}

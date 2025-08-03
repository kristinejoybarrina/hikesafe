import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/bluetooth_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final HikesafeBluetoothService _bluetoothService = HikesafeBluetoothService();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/voice_note.aac';

    await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);

    setState(() {
      _isRecording = true;
      _audioPath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    if (_audioPath != null) {
      final file = File(_audioPath!);
      final bytes = await file.readAsBytes();
      debugPrint("Recording size: ${bytes.length} bytes");

      try {
        // Split audio into chunks and send over LoRa via BLE
        await _sendAudioChunks(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice message sent via LoRa!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send voice message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendAudioChunks(List<int> audioBytes) async {
    const int chunkSize = 16; // BLE packet size minus header
    const String chunkPrefix = 'AUDIO:'; // Prefix to identify audio chunks

    for (int i = 0; i < audioBytes.length; i += chunkSize) {
      int end = (i + chunkSize < audioBytes.length)
          ? i + chunkSize
          : audioBytes.length;
      List<int> chunk = audioBytes.sublist(i, end);

      // Create chunk message with index and data
      String chunkMessage =
          '$chunkPrefix${i ~/ chunkSize}:${base64Encode(chunk)}';
      await _bluetoothService.sendMessage(chunkMessage);

      // Small delay to prevent overwhelming the BLE connection
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Send end marker
    await _bluetoothService.sendMessage('${chunkPrefix}END');
  }

  Widget _buildRecorderUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isRecording ? 'Recording...' : 'Tap to record a message'),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          onPressed: _isRecording ? _stopRecording : _startRecording,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Walkie-Talkie')),
      body: Center(child: _buildRecorderUI()),
    );
  }
}

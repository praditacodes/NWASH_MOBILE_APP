import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioRecordWidget extends StatefulWidget {
  final List<String> audios;
  final ValueChanged<List<String>> onAudiosChanged;

  const AudioRecordWidget({required this.audios, required this.onAudiosChanged});

  @override
  State<AudioRecordWidget> createState() => _AudioRecordWidgetState();
}

class _AudioRecordWidgetState extends State<AudioRecordWidget> {
  bool _isRecording = false;
  final _audioRecorder = AudioRecorder();

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.m4a';
      final filePath = '${appDir.path}/$fileName';
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      final newAudios = List<String>.from(widget.audios)..add(path);
      widget.onAudiosChanged(newAudios);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audio Recorder', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (i) {
            return Container(
              margin: EdgeInsets.all(4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: i < widget.audios.length ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: i < widget.audios.length
                  ? Icon(Icons.mic, color: Colors.white, size: 20)
                  : Center(child: Text('${i + 1}')),
            );
          }),
        ),
        ElevatedButton.icon(
          onPressed: widget.audios.length < 5
              ? () async {
                  if (_isRecording) {
                    await _stopRecording();
                  } else {
                    await _startRecording();
                  }
                }
              : null,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
        ),
        if (widget.audios.isNotEmpty)
          Wrap(
            children: widget.audios.map((path) {
              return IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () async {
                  // You can use an audio player package to play the file
                  // For example: just_audio or audioplayers
                  // This is a placeholder for playback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playback not implemented in this demo')),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
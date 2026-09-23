import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

/// Voice recorder button. Hold to record, release to send/playback.
/// Uses the `audio_record` package which exposes a concrete `AudioRecord` class.
class VoiceMessageButton extends StatefulWidget {
  const VoiceMessageButton({this.onSend, super.key});
  final void Function(String filePath)? onSend;

  @override
  State<VoiceMessageButton> createState() => _VoiceMessageButtonState();
}

class _VoiceMessageButtonState extends State<VoiceMessageButton> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _recording = false;
  String? _filePath;
  bool _playerReady = false;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required.')),
      );
      return;
    }
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _filePath = path;
      });
    } else {
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      await _recorder.start(config, path: '/tmp/note_${DateTime.now().millisecondsSinceEpoch}.m4a');
      setState(() => _recording = true);
    }
  }

  Future<void> _play() async {
    final file = _filePath;
    if (file == null) return;
    await _player.setFilePath(file);
    setState(() => _playerReady = true);
    await _player.play();
  }

  Future<void> _send() async {
    final file = _filePath;
    if (file == null || widget.onSend == null) return;
    widget.onSend!(file);
    setState(() => _filePath = null);
  }

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        if (_filePath != null) ...[
          IconButton(icon: const Icon(Icons.play_arrow), onPressed: _playerReady ? null : _play),
          Text('${_player.duration?.inSeconds ?? 0}s'),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ] else
          GestureDetector(
            onLongPressStart: (_) => _toggleRecord(),
            onLongPressEnd: (_) {
              if (_recording) _toggleRecord();
            },
            child: Icon(
              _recording ? Icons.mic : Icons.mic_none,
              color: _recording ? Colors.red : Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
      ]);
}

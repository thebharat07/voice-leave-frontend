import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class MicRecorderCard extends StatefulWidget {
  final Function(String path, String leaveType) onSubmit;
  final bool isUploading;

  const MicRecorderCard({
    super.key,
    required this.onSubmit,
    this.isUploading = false,
  });

  @override
  State<MicRecorderCard> createState() => _MicRecorderCardState();
}

class _MicRecorderCardState extends State<MicRecorderCard> with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? _lastRecordedPath;
  late AnimationController _animationController;

  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 1.0,
      upperBound: 1.05,
    );

    _audioPlayer.onDurationChanged.listen((d) => setState(() => _audioDuration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _audioPosition = p));
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;

    if (_isRecording) {
      final path = await _recorder.stop();
      _animationController.stop();
      _animationController.reset();
      setState(() {
        _isRecording = false;
        _lastRecordedPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      setState(() {
        _isRecording = true;
        _lastRecordedPath = null;
      });
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _playRecording() async {
    if (_lastRecordedPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_lastRecordedPath!));
      setState(() => _isPlaying = true);
    }
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Future<void> _showLeaveTypePicker() async {
    final String? selectedType = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Leave Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.beach_access, color: Colors.orange),
              title: const Text('Casual Leave'),
              onTap: () => Navigator.pop(context, 'Casual'),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.red),
              title: const Text('Medical Leave'),
              onTap: () => Navigator.pop(context, 'Medical'),
            ),
            ListTile(
              leading: const Icon(Icons.flight_takeoff, color: Colors.blue),
              title: const Text('Vacation Leave'),
              onTap: () => Navigator.pop(context, 'Vacation'),
            ),
          ],
        ),
      ),
    );

    if (selectedType != null && _lastRecordedPath != null) {
      widget.onSubmit(_lastRecordedPath!, selectedType);
      setState(() {
        _lastRecordedPath = null; // Clear after submitting
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _animationController.value : 1.0,
            child: Container(
              height: 380,
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording ? Colors.indigoAccent.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                    blurRadius: _isRecording ? 30 : 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Request Leave', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.indigo),
                    child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(_isRecording ? 'Recording...' : 'Tap to Record', style: const TextStyle(fontSize: 16)),

                  if (!_isRecording && _lastRecordedPath != null) ...[
                    Slider(
                      min: 0,
                      max: _audioDuration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      value: _audioPosition.inMilliseconds.toDouble().clamp(0, _audioDuration.inMilliseconds.toDouble()),
                      onChanged: (v) => _audioPlayer.seek(Duration(milliseconds: v.toInt())),
                      activeColor: Colors.indigo,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(_formatTime(_audioPosition)), Text(_formatTime(_audioDuration))],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: _playRecording,
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        const SizedBox(width: 20),
                        widget.isUploading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          onPressed: _showLeaveTypePicker,
                          label: const Text("Submit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.shade100,
                            foregroundColor: Colors.green.shade900,
                          ),
                        ),
                      ],
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
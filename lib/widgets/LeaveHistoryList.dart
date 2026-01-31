import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/leave_application.dart';
import '../services/audio_service.dart';
import '../services/leave_service.dart';

class LeaveHistoryList extends StatefulWidget {
  const LeaveHistoryList({super.key});

  @override
  State<LeaveHistoryList> createState() => LeaveHistoryListState();
}

// Renamed to public (removed underscore) so FacultyHome can use it with GlobalKey
class LeaveHistoryListState extends State<LeaveHistoryList> {
  final AudioPlayer _listAudioPlayer = AudioPlayer();
  final AudioService _audioService = AudioService();
  final LeaveService _leaveService = LeaveService();

  String? _currentlyPlayingId;
  bool _isLoadingAudio = false;

  // Store the future in a variable to allow refreshing
  late Future<List<LeaveApplication>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _leaveService.fetchMyApplications();
  }

  /// Public method to refresh the list from outside (e.g., from FacultyHome)
  void refresh() {
    setState(() {
      _applicationsFuture = _leaveService.fetchMyApplications();
    });
  }

  Future<void> _playApplicationAudio(LeaveApplication app) async {
    try {
      if (_currentlyPlayingId == app.id) {
        await _listAudioPlayer.stop();
        setState(() => _currentlyPlayingId = null);
        return;
      }

      setState(() {
        _isLoadingAudio = true;
        _currentlyPlayingId = app.id;
      });

      // Use new AudioService to get SAS URL
      final url = await _audioService.getFreshSasUrl(app.blobName);

      await _listAudioPlayer.play(UrlSource(url));

      _listAudioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _currentlyPlayingId = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error playing audio")),
        );
      }
      setState(() => _currentlyPlayingId = null);
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  @override
  void dispose() {
    _listAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaveApplication>>(
      future: _applicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: Text("No leave applications found")),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final app = snapshot.data![index];
            final isPlaying = _currentlyPlayingId == app.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(app.status).withOpacity(0.1),
                  child: Icon(Icons.record_voice_over, color: _getStatusColor(app.status)),
                ),
                title: Text("${app.type} Leave", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Level: ${app.levelTitle}"),
                    Text(
                      "${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year} • ${app.status.toUpperCase()}",
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(app.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: _isLoadingAudio && isPlaying
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                    size: 36,
                    color: Colors.indigo,
                  ),
                  onPressed: () => _playApplicationAudio(app),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
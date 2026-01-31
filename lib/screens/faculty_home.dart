import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screen Imports
import 'package:voiceleave/screens/login_screen.dart';

// Service Imports (Updated to new services)
import '../services/audio_service.dart';
import '../services/leave_service.dart';

// Widget Imports
import '../widgets/mic_recorder_card.dart';
import '../widgets/header_card.dart';
import '../widgets/LeaveHistoryList.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  // Initialize new services
  final AudioService _audioService = AudioService();
  final LeaveService _leaveService = LeaveService();

  // Used to trigger a refresh in the History List after an upload
  final GlobalKey<LeaveHistoryListState> _historyKey = GlobalKey();

  // Supabase User Data
  final user = Supabase.instance.client.auth.currentUser;
  late final metadata = user?.userMetadata ?? {};
  late final name = metadata['name'] ?? 'Faculty';
  late final title = metadata['title'] ?? '';
  late final dept = metadata['dept'] ?? '';

  bool _uploading = false;

  // Business Logic: Handle Voice Submission
  Future<void> _handleVoiceSubmit(String path, String leaveType) async {
    setState(() => _uploading = true);
    try {
      // Use the new AudioService
      await _audioService.uploadAudio(path, leaveType: leaveType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$leaveType Leave Request Sent!')),
        );

        // Refresh the history list so the new application appears
        _historyKey.currentState?.refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // Business Logic: Handle Logout
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: RefreshIndicator(
        // Pull to refresh the whole page
        onRefresh: () async => _historyKey.currentState?.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // REUSABLE HEADER
              HeaderCard(
                name: name,
                title: title,
                department: dept,
                onLogout: () => _handleLogout(context),
              ),

              const SizedBox(height: 30),

              // REUSABLE RECORDER
              Center(
                child: MicRecorderCard(
                  isUploading: _uploading,
                  onSubmit: (path, type) => _handleVoiceSubmit(path, type),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 10),
                child: Text(
                  "Recent Applications",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // REUSABLE HISTORY LIST (With Key for refreshing)
              LeaveHistoryList(key: _historyKey),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
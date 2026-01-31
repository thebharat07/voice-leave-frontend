import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voiceleave/screens/login_screen.dart';

// Import the new services
import '../services/audio_service.dart';
import '../services/leave_service.dart';

import '../models/leave_application.dart';
import '../widgets/header_card.dart';
import '../widgets/mic_recorder_card.dart';

class AuthorityHome extends StatefulWidget {
  const AuthorityHome({super.key});

  @override
  State<AuthorityHome> createState() => _AuthorityHomeState();
}

class _AuthorityHomeState extends State<AuthorityHome> {
  // Initialize new services
  final AudioService _audioService = AudioService();
  final LeaveService _leaveService = LeaveService();

  final user = Supabase.instance.client.auth.currentUser;
  late final metadata = user?.userMetadata ?? {};
  late final name = metadata['name'] ?? 'Faculty';
  late final title = metadata['title'] ?? '';
  late final dept = metadata['dept'] ?? '';

  bool _uploading = false;
  final Set<String> _processedIds = {};

  late final authLevel = {
    'Associate Prof': 1,
    'Assistant Prof': 1,
    'Dean': 3,
    'HOD': 2,
    'Principal': 4,
    'Vice Chancellor': 5,
    'Registrar': 6
  }[metadata['title']] ?? 1;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  late Future<List<LeaveApplication>> _pendingFuture;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _pendingFuture = _leaveService.fetchApplicationsForAuthority(authLevel);
      _historyFuture = _leaveService.fetchAuthorityHistory();
    });
  }

  Future<void> _handleVoiceSubmit(String path, String leaveType) async {
    setState(() => _uploading = true);
    try {
      await _audioService.uploadAudio(path, leaveType: leaveType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$leaveType Leave Request Sent!')),
        );
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

  Future<void> _handleDecision(LeaveApplication app, bool isGranted) async {
    setState(() => _processedIds.add(app.id));

    try {
      await _leaveService.updateApplicationStatus(
          applicationId: app.id,
          status: isGranted ? 'approved' : 'rejected',
          level: app.level,
          leaveType: app.type,
          decision: isGranted ? 'granted' : 'rejected'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isGranted ? "Application Granted" : "Application Rejected")),
        );
      }
      _refreshData();
    } catch (e) {
      setState(() => _processedIds.remove(app.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed")));
      }
    }
  }

  Future<void> _playVoice(LeaveApplication app) async {
    if (_playingId == app.id) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
      return;
    }

    setState(() => _playingId = app.id);
    try {
      final url = await _audioService.getFreshSasUrl(app.blobName);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (e) {
      setState(() => _playingId = null);
    }
  }

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

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    HeaderCard(
                      name: name,
                      title: title,
                      department: dept,
                      onLogout: () => _handleLogout(context),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: MicRecorderCard(
                        isUploading: _uploading,
                        onSubmit: (path, type) => _handleVoiceSubmit(path, type),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: const Color(0xFFF6F7FB),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [Icon(Icons.pending_actions_rounded), SizedBox(width: 8), Text("Pending")],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [Icon(Icons.history_rounded), SizedBox(width: 8), Text("History")],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              RefreshIndicator(onRefresh: () async => _refreshData(), child: _buildPendingList()),
              RefreshIndicator(onRefresh: () async => _refreshData(), child: _buildHistoryList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return FutureBuilder<List<LeaveApplication>>(
      future: _pendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No pending applications"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final app = snapshot.data![index];
            return _ApprovalCard(
              app: app,
              isProcessed: _processedIds.contains(app.id),
              isPlaying: _playingId == app.id,
              onPlay: () => _playVoice(app),
              onGrant: () => _handleDecision(app, true),
              onReject: () => _handleDecision(app, false),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No decision history found"));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _HistoryCard(data: snapshot.data![index]),
        );
      },
    );
  }
}

// --- SUB-WIDGETS (Unchanged structure, updated logic) ---

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFFF6F7FB), child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _ApprovalCard extends StatelessWidget {
  final LeaveApplication app;
  final bool isPlaying;
  final bool isProcessed;
  final VoidCallback onPlay;
  final VoidCallback onGrant;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.app,
    required this.isPlaying,
    required this.isProcessed,
    required this.onPlay,
    required this.onGrant,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(app.name ?? "Unknown Applicant", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${app.title ?? ''} • ${app.dept ?? ''}"),
              trailing: IconButton(
                icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_fill, size: 44, color: Colors.indigo),
                onPressed: onPlay,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("Type: ${app.type}", style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            isProcessed
                ? const Text("Processed", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onGrant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Grant"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final application = data['leave_applications'];
    final faculty = application?['faculty'];
    final String decision = data['decision'] ?? 'processed';
    final DateTime date = DateTime.parse(data['decision_at']).toLocal();

    bool isGranted = decision.toLowerCase() == 'granted';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? Colors.green : Colors.red,
          size: 30,
        ),
        title: Text('${faculty?['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${application?['type'] ?? 'Leave'} • ${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"),
        trailing: Text(
          decision.toUpperCase(),
          style: TextStyle(
            color: isGranted ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
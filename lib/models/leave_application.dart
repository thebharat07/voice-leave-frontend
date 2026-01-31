class LeaveApplication {
  final String id;
  final String type;
  final String status;
  final int level;
  final String blobName;
  final DateTime createdAt;
  final String? name;
  final String? dept;
  final String? title;

  LeaveApplication({
    required this.id,
    required this.type,
    required this.status,
    required this.level,
    required this.blobName,
    required this.createdAt,
    this.name,
    this.dept,
    this.title,

  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    // Check if faculty_id is a Map (from a join) or just a String (regular select)
    final facultyData = json['faculty'];
    Map<String, dynamic>? userData;

    if (facultyData is Map<String, dynamic>) {
      userData = facultyData;
    }

    return LeaveApplication(
      id: json['id'].toString(),
      type: json['leave_type'] ?? 'General',
      status: json['status'] ?? 'Pending',
      level: json['current_level'] ?? 1,
      blobName: json['voice_blob_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      // If userData is null (because faculty_id was just a string), these become null
      name: userData?['name'],
      dept: userData?['dept'],
      title: userData?['title'],
    );
  }

  String get levelTitle {
    switch (level) {
      case 2: return 'HOD';
      case 3: return 'Dean';
      case 4: return 'Principal';
      default: return 'Management';
    }
  }
}
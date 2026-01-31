import '../models/leave_application.dart';
import 'base_service.dart';

class LeaveService extends BaseService {

  // Faculty: Fetch my own applications
  Future<List<LeaveApplication>> fetchMyApplications() async {
    try {
      final List<dynamic> response = await supabase
          .from('leave_applications')
          .select()
          .eq('faculty_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => LeaveApplication.fromJson(json)).toList();
    } catch (e) {
      return []; // Or rethrow based on UI needs
    }
  }

  // Authority: Fetch applications to review
  Future<List<LeaveApplication>> fetchApplicationsForAuthority(int authLevel) async {
    final metadata = supabase.auth.currentUser?.userMetadata ?? {};
    final String authDept = metadata['dept'] ?? '';

    var query = supabase.from('leave_applications').select('''
        *,
        faculty:users!inner (name, dept, title)
      ''').eq('current_level', authLevel).eq('status', 'pending');

    if (authLevel == 2) {
      query = query.eq('faculty.dept', authDept);
    }

    final List<dynamic> response = await query.order('created_at', ascending: true);
    return response.map((json) => LeaveApplication.fromJson(json)).toList();
  }

  // Authority: Update status and log approval
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    required int level,
    required String leaveType,
    required String decision,
  }) async {
    // Note: Use a transaction if your backend/RPC supports it
    await supabase
        .from('leave_applications')
        .update({'status': status})
        .eq('id', applicationId);

    await supabase.from('leave_approvals').insert({
      'id': applicationId, // Changed 'id' to 'application_id' (usually better DB practice)
      'decision_by': userId,
      'decision': decision,
      'leave_type': leaveType,
      'role': level
    });
  }

  // Authority: Fetch history
  Future<List<Map<String, dynamic>>> fetchAuthorityHistory() async {
    final response = await supabase
        .from('leave_approvals')
        .select('''
          id, decision, decision_at,
          leave_applications (
            type:leave_type,
            faculty:users (name, title)
          )
        ''')
        .eq('decision_by', userId)
        .order('decision_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
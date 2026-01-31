import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'base_service.dart';

class AudioService extends BaseService {
  static const String _baseUrl = 'https://voice-leave-jntugv.onrender.com';

  Future<String> uploadAudio(String audioPath, {required String leaveType}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/user/upload-audio'));

    request.fields['leave_type'] = leaveType;
    request.headers.addAll({'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}'});

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        contentType: MediaType('audio', 'm4a'),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) throw Exception('Upload failed: $responseBody');

    return jsonDecode(responseBody)['sasUrl'];
  }

  Future<String> getFreshSasUrl(String blobName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/get-sas-url'),
      headers: authHeaders,
      body: jsonEncode({'blobName': blobName}),
    );

    if (response.statusCode == 200) return jsonDecode(response.body)['sasUrl'];
    throw Exception('Failed to get audio URL');
  }
}
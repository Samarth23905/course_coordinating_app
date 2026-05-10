import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> registerUser(
    String name,
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
      }),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> addCourse(
    String programCode,
    int semester,
    Map<String, dynamic> courseData, {
    Map<String, dynamic>? semesterDuration,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_course'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'program_code': programCode,
        'semester': semester,
        'course_data': courseData,
        if (semesterDuration != null) 'semester_duration': semesterDuration,
      }),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> getCourses(String programCode, int semester) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_courses/$programCode/$semester'),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> updateCourse(
    String programCode,
    int semester,
    Map<String, dynamic> courseData, {
    Map<String, dynamic>? semesterDuration,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update_course'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'program_code': programCode,
        'semester': semester,
        'course_data': courseData,
        if (semesterDuration != null) 'semester_duration': semesterDuration,
      }),
    );

    return _processResponse(response);
  }

  Future<Map<String, dynamic>> deleteCourse(String programCode, int semester, String courseCode) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_course'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'program_code': programCode,
        'semester': semester,
        'course_code': courseCode,
      }),
    );

    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body);
    } else {
      Map<String, dynamic> errorData = {};
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {
        errorData = {'error': 'Unknown error occurred (${response.statusCode})'};
      }
      throw Exception(errorData['error'] ?? 'Request failed');
    }
  }
}

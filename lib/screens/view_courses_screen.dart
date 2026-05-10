import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import 'assign_course_screen.dart';

class ViewCoursesScreen extends StatefulWidget {
  const ViewCoursesScreen({super.key});

  @override
  State<ViewCoursesScreen> createState() => _ViewCoursesScreenState();
}

class _ViewCoursesScreenState extends State<ViewCoursesScreen> {
  String _programCode = 'CS';
  int _semester = 1;
  List<dynamic> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _courses = [];
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getCourses(_programCode, _semester);
      if (!mounted) return;
      setState(() {
        _courses = response['courses'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCourse(String courseCode) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $courseCode?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (!mounted) return;
    if (!confirm) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteCourse(_programCode, _semester, courseCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted successfully')));
        await _fetchCourses(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _updateCourse(Map<String, dynamic> course) async {
    // Navigate to a new route that shows the AssignCourseScreen in Edit mode
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Course')),
          body: AssignCourseScreen(
            initialCourse: course,
            initialProgramCode: _programCode,
            initialSemester: _semester,
            onSaveSuccess: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
    // Refresh the list after returning
    if (!mounted) return;
    await _fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('View Assigned Courses', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Program Code', border: OutlineInputBorder()),
                  initialValue: _programCode,
                  items: ['CS', 'IS', 'ECE'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setState(() => _programCode = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                  initialValue: _semester,
                  items: List.generate(8, (index) => index + 1).map((int value) {
                    return DropdownMenuItem<int>(value: value, child: Text('Semester $value'));
                  }).toList(),
                  onChanged: (val) => setState(() => _semester = val!),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _fetchCourses,
                icon: const Icon(Icons.search),
                label: const Text('Fetch Data'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null) Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
          if (!_isLoading && _errorMessage == null && _courses.isEmpty)
            const Text('No courses found for the selected program and semester.'),
          if (!_isLoading && _courses.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ExpansionTile(
                      title: Text("${course['course_code']} - ${course['course_title']}"),
                      subtitle: Text("Credits: ${course['credits']?['total'] ?? 0} | ${course['hours_per_week'] ?? 0} Hrs/Week"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Aim: ${course['course_aim'] ?? ''}"),
                              const SizedBox(height: 16),
                              const Text('Course Outcomes:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...(course['course_outcomes'] as List? ?? []).map((co) {
                                return Text("${co['co']}: ${co['description']} [${co['bloom']}]");
                              }),
                              const SizedBox(height: 16),
                              const Text('Units:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...(course['course_content'] as List? ?? []).map((unit) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("- ${unit['unit']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ...(unit['topics'] as List? ?? []).map((t) => Text('  * $t')),
                                  ],
                                );
                              }),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    TextButton.icon(
                                      onPressed: () => _updateCourse(course),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Course'),
                                    ),
                                  TextButton.icon(
                                    onPressed: () => _deleteCourse(course['course_code']),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

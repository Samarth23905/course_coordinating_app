import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
    );
  }

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
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete $courseCode?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !confirm) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteCourse(_programCode, _semester, courseCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted successfully')),
        );
        await _fetchCourses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _updateCourse(Map<String, dynamic> course) async {
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

    if (!mounted) return;
    await _fetchCourses();
  }

  Future<Uint8List> _buildCoursesPdf(List<Map<String, dynamic>> courses) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final tableHeaders = [
            'Course Code',
            'Title',
            'Credits',
            'Hrs/Week',
            'Total Hrs',
            'Faculty',
            'Section',
            'Year',
          ];

          final tableData = courses.map((course) {
            return [
              course['course_code'] ?? '',
              course['course_title'] ?? '',
              (course['credits']?['total'] ?? 0).toString(),
              (course['hours_per_week'] ?? 0).toString(),
              (course['total_hours'] ?? 0).toString(),
              course['faculty_assignment']?['faculty_name'] ?? '',
              course['faculty_assignment']?['section'] ?? '',
              course['faculty_assignment']?['academic_year'] ?? '',
            ];
          }).toList();

          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Assigned Courses Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Program: $_programCode   Semester: $_semester',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: pdf.PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
              ],
            ),
            pw.Table.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: pdf.PdfColors.grey300,
              ),
              border: pw.TableBorder.all(
                color: pdf.PdfColors.grey400,
                width: 0.5,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(0.8),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(0.9),
                7: const pw.FlexColumnWidth(0.9),
              },
            ),
            pw.SizedBox(height: 20),
            ...courses.expand((course) {
              final outcomes =
                  (course['course_outcomes'] as List<dynamic>?)
                      ?.map(
                        (co) =>
                            '- ${co['co']}: ${co['description']} [${co['bloom']}]',
                      )
                      .toList() ??
                  <String>[];

              return [
                pw.Text(
                  '${course['course_code']} — ${course['course_title']}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Aim: ${course['course_aim'] ?? ''}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Objectives: ${(course['course_objectives'] as List<dynamic>?)?.join(', ') ?? ''}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 6),
                if (outcomes.isNotEmpty)
                  pw.Text(
                    'Course Outcomes:',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (outcomes.isNotEmpty)
                  pw.Column(
                    children: outcomes
                        .map(
                          (item) =>
                              pw.Text(item, style: pw.TextStyle(fontSize: 10)),
                        )
                        .toList(),
                  ),
                pw.SizedBox(height: 16),
              ];
            }),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<void> _downloadPdf() async {
    if (_courses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fetch course data first before downloading PDF.',
          ),
        ),
      );
      return;
    }

    try {
      await Printing.layoutPdf(
        onLayout: (format) =>
            _buildCoursesPdf(_courses.cast<Map<String, dynamic>>()),
        name: 'assigned_courses_${_programCode}_sem$_semester.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to create PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View Assigned Courses',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetch course details, review credits, and export a teacher-ready PDF report.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: theme.colorScheme.surface,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Search filters',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select the semester and generate your teaching report.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Program Code'),
                          value: _programCode,
                          items: ['CS', 'IS', 'ECE']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _programCode = val);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<int>(
                          decoration: _inputDecoration('Semester'),
                          value: _semester,
                          items: List.generate(8, (index) => index + 1)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('Semester $value'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _semester = val);
                          },
                        ),
                      ),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _fetchCourses,
                          icon: const Icon(Icons.search),
                          label: const Text('Fetch Data'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      if (_courses.isNotEmpty)
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _downloadPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Download PDF'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _courses.isEmpty
                ? Center(
                    child: Text(
                      'No courses found for the selected program and semester.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _courses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final course = _courses[index] as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            20,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(
                            '${course['course_code']} - ${course['course_title']}',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    'Credits: ${course['credits']?['total'] ?? 0}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${course['hours_per_week'] ?? 0} hrs/week',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            const SizedBox(height: 8),
                            if ((course['course_aim'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              Text('Aim', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Text(
                                course['course_aim'] ?? '',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if ((course['course_outcomes'] as List?)
                                    ?.isNotEmpty ??
                                false) ...[
                              Text(
                                'Course Outcomes',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              ...((course['course_outcomes'] as List<dynamic>)
                                  .map(
                                    (co) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '• ',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${co['co']}: ${co['description']} [${co['bloom']}]',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList()),
                              const SizedBox(height: 16),
                            ],
                            if ((course['course_content'] as List?)
                                    ?.isNotEmpty ??
                                false) ...[
                              Text('Units', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              ...((course['course_content'] as List<dynamic>)
                                  .map(
                                    (unit) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            unit['unit'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...((unit['topics'] as List?) ?? [])
                                              .map(
                                                (topic) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 12.0,
                                                        bottom: 4.0,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text('• '),
                                                      Expanded(
                                                        child: Text(
                                                          topic.toString(),
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList()),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => _updateCourse(course),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () => _deleteCourse(
                                    course['course_code'] ?? '',
                                  ),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.errorContainer,
                                    foregroundColor:
                                        theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
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

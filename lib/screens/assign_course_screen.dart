import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';

class AssignCourseScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCourse;
  final String? initialProgramCode;
  final int? initialSemester;
  final VoidCallback? onSaveSuccess;

  const AssignCourseScreen({
    super.key,
    this.initialCourse,
    this.initialProgramCode,
    this.initialSemester,
    this.onSaveSuccess,
  });

  @override
  State<AssignCourseScreen> createState() => _AssignCourseScreenState();
}

class _AssignCourseScreenState extends State<AssignCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  String _programCode = 'CS';
  int _semester = 1;

  final TextEditingController _courseCodeCtrl = TextEditingController();
  final TextEditingController _courseTitleCtrl = TextEditingController();
  final TextEditingController _teachingWeeksCtrl = TextEditingController(text: '1-16');
  final TextEditingController _examWeeksCtrl = TextEditingController(text: '17-18');
  final TextEditingController _resultWeeksCtrl = TextEditingController(text: '19-20');
  final TextEditingController _lCtrl = TextEditingController();
  final TextEditingController _tCtrl = TextEditingController();
  final TextEditingController _pCtrl = TextEditingController();
  final TextEditingController _hoursPerWeekCtrl = TextEditingController();
  final TextEditingController _totalHoursCtrl = TextEditingController();
  final TextEditingController _facultyNameCtrl = TextEditingController();
  final TextEditingController _sectionCtrl = TextEditingController();
  final TextEditingController _academicYearCtrl = TextEditingController();
  final TextEditingController _courseAimCtrl = TextEditingController();

  final TextEditingController _quizTotalCtrl = TextEditingController();
  final TextEditingController _quizQ1Ctrl = TextEditingController();
  final TextEditingController _quizQ2Ctrl = TextEditingController();
  final TextEditingController _quizQ3Ctrl = TextEditingController();
  final TextEditingController _testTotalCtrl = TextEditingController();
  final TextEditingController _testT1Ctrl = TextEditingController();
  final TextEditingController _testT2Ctrl = TextEditingController();
  final TextEditingController _assignmentTotalCtrl = TextEditingController();
  final TextEditingController _assignmentA1Ctrl = TextEditingController();
  final TextEditingController _assignmentA2Ctrl = TextEditingController();
  final TextEditingController _cieCtrl = TextEditingController();
  final TextEditingController _seeCtrl = TextEditingController();

  final TextEditingController _level1Ctrl = TextEditingController();
  final TextEditingController _level2Ctrl = TextEditingController();
  final TextEditingController _level3Ctrl = TextEditingController();

  final Map<String, TextEditingController> _gradingCtrls = {
    'O': TextEditingController(),
    'A+': TextEditingController(),
    'A': TextEditingController(),
    'B+': TextEditingController(),
    'B': TextEditingController(),
    'C': TextEditingController(),
    'D': TextEditingController(),
  };

  final List<TextEditingController> _courseObjectives = [];
  final List<Map<String, TextEditingController>> _courseOutcomes = [];
  final List<Map<String, TextEditingController>> _coPoPsoMappings = [];
  final List<Map<String, dynamic>> _courseUnits = [];
  final List<TextEditingController> _textbooks = [];
  final List<TextEditingController> _references = [];
  final List<Map<String, TextEditingController>> _teachingPlan = [];
  final List<Map<String, TextEditingController>> _assessmentCoDistribution = [];
  final List<Map<String, TextEditingController>> _coTargets = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourse != null) {
      _programCode = widget.initialProgramCode ?? 'CS';
      _semester = widget.initialSemester ?? 1;
      _populateFields(widget.initialCourse!);
    } else {
      _setDefaultRows();
    }
  }

  void _setDefaultRows() {
    _addCourseObjective();
    _addCourseOutcome();
    _addCoPoPsoMapping();
    _addCourseUnit();
    _addTextbook();
    _addReference();
    _addTeachingPlanItem();
    _addAssessmentCoDistribution();
    _addCoTarget();
  }

  void _populateFields(Map<String, dynamic> course) {
    _courseCodeCtrl.text = course['course_code'] ?? '';
    _courseTitleCtrl.text = course['course_title'] ?? '';
    _lCtrl.text = (course['credits']?['L'] ?? '').toString();
    _tCtrl.text = (course['credits']?['T'] ?? '').toString();
    _pCtrl.text = (course['credits']?['P'] ?? '').toString();
    _hoursPerWeekCtrl.text = (course['hours_per_week'] ?? '').toString();
    _totalHoursCtrl.text = (course['total_hours'] ?? '').toString();
    _facultyNameCtrl.text = course['faculty_assignment']?['faculty_name'] ?? '';
    _sectionCtrl.text = course['faculty_assignment']?['section'] ?? '';
    _academicYearCtrl.text = course['faculty_assignment']?['academic_year'] ?? '';
    _courseAimCtrl.text = course['course_aim'] ?? '';

    _populateTextList(_courseObjectives, course['course_objectives'] as List?);
    _populateOutcomes(course['course_outcomes'] as List?);
    _populateMappings(course['co_po_pso_mapping'] as List?);
    _populateUnits(course['course_content'] as List?);
    _populateTextList(_textbooks, course['books']?['textbooks'] as List?);
    _populateTextList(_references, course['books']?['references'] as List?);
    _populateTeachingPlan(course['teaching_plan'] as List?);
    _populateAssessment(course['assessment'] as Map<String, dynamic>?);
    _populateAttainment(course['attainment_targets'] as Map<String, dynamic>?);
    _populateGrading(course['grading'] as Map<String, dynamic>?);
  }

  void _populateTextList(List<TextEditingController> target, List? values) {
    target.clear();
    if (values == null || values.isEmpty) {
      target.add(TextEditingController());
      return;
    }
    for (final value in values) {
      target.add(TextEditingController(text: value.toString()));
    }
  }

  void _populateOutcomes(List? outcomes) {
    _courseOutcomes.clear();
    if (outcomes == null || outcomes.isEmpty) {
      _addCourseOutcome();
      return;
    }
    for (final co in outcomes) {
      _courseOutcomes.add({
        'co': TextEditingController(text: co['co'] ?? ''),
        'description': TextEditingController(text: co['description'] ?? ''),
        'bloom': TextEditingController(text: co['bloom'] ?? ''),
      });
    }
  }

  void _populateMappings(List? mappings) {
    _coPoPsoMappings.clear();
    if (mappings == null || mappings.isEmpty) {
      _addCoPoPsoMapping();
      return;
    }
    for (final item in mappings) {
      final mapping = item['mapping'] ?? {};
      _coPoPsoMappings.add({
        'co': TextEditingController(text: item['co'] ?? ''),
        'po1': TextEditingController(text: (mapping['PO1'] ?? '').toString()),
        'po2': TextEditingController(text: (mapping['PO2'] ?? '').toString()),
        'pso1': TextEditingController(text: (mapping['PSO1'] ?? '').toString()),
      });
    }
  }

  void _populateUnits(List? content) {
    _courseUnits.clear();
    if (content == null || content.isEmpty) {
      _addCourseUnit();
      return;
    }
    for (final unit in content) {
      final topics = (unit['topics'] as List? ?? [])
          .map((topic) => TextEditingController(text: topic.toString()))
          .toList();
      _courseUnits.add({
        'unit': TextEditingController(text: unit['unit'] ?? ''),
        'topics': topics.isEmpty ? <TextEditingController>[TextEditingController()] : topics,
      });
    }
  }

  void _populateTeachingPlan(List? plan) {
    _teachingPlan.clear();
    if (plan == null || plan.isEmpty) {
      _addTeachingPlanItem();
      return;
    }
    for (final item in plan) {
      _teachingPlan.add({
        'lecture': TextEditingController(text: (item['lecture'] ?? '').toString()),
        'topic': TextEditingController(text: item['topic'] ?? ''),
      });
    }
  }

  void _populateAssessment(Map<String, dynamic>? assessment) {
    final structure = assessment?['structure'] ?? {};
    final quiz = structure['quiz'] ?? {};
    final test = structure['test'] ?? {};
    final assignment = structure['assignment'] ?? {};

    _quizTotalCtrl.text = (quiz['total'] ?? '').toString();
    _quizQ1Ctrl.text = (quiz['Q1'] ?? '').toString();
    _quizQ2Ctrl.text = (quiz['Q2'] ?? '').toString();
    _quizQ3Ctrl.text = (quiz['Q3'] ?? '').toString();
    _testTotalCtrl.text = (test['total'] ?? '').toString();
    _testT1Ctrl.text = (test['T1'] ?? '').toString();
    _testT2Ctrl.text = (test['T2'] ?? '').toString();
    _assignmentTotalCtrl.text = (assignment['total'] ?? '').toString();
    _assignmentA1Ctrl.text = (assignment['A1'] ?? '').toString();
    _assignmentA2Ctrl.text = (assignment['A2'] ?? '').toString();
    _cieCtrl.text = (structure['cie'] ?? '').toString();
    _seeCtrl.text = (structure['see'] ?? '').toString();

    _assessmentCoDistribution.clear();
    final distribution = assessment?['co_distribution'] as List? ?? [];
    if (distribution.isEmpty) {
      _addAssessmentCoDistribution();
      return;
    }
    for (final item in distribution) {
      _assessmentCoDistribution.add({
        'co': TextEditingController(text: item['co'] ?? ''),
        'cie': TextEditingController(text: (item['cie'] ?? '').toString()),
        'see': TextEditingController(text: (item['see'] ?? '').toString()),
      });
    }
  }

  void _populateAttainment(Map<String, dynamic>? attainment) {
    final criteria = attainment?['criteria'] ?? {};
    _level1Ctrl.text = criteria['level_1'] ?? '';
    _level2Ctrl.text = criteria['level_2'] ?? '';
    _level3Ctrl.text = criteria['level_3'] ?? '';

    _coTargets.clear();
    final targets = attainment?['co_targets'] as List? ?? [];
    if (targets.isEmpty) {
      _addCoTarget();
      return;
    }
    for (final item in targets) {
      _coTargets.add({
        'co': TextEditingController(text: item['co'] ?? ''),
        'target_level': TextEditingController(text: (item['target_level'] ?? '').toString()),
      });
    }
  }

  void _populateGrading(Map<String, dynamic>? grading) {
    for (final entry in _gradingCtrls.entries) {
      entry.value.text = (grading?[entry.key] ?? '').toString();
    }
  }

  int get _totalCredits {
    final l = int.tryParse(_lCtrl.text) ?? 0;
    final t = int.tryParse(_tCtrl.text) ?? 0;
    final p = int.tryParse(_pCtrl.text) ?? 0;
    return l + t + p;
  }

  List<String> _stringsFrom(List<TextEditingController> controllers) {
    return controllers.map((controller) => controller.text.trim()).where((text) => text.isNotEmpty).toList();
  }

  int _intFrom(TextEditingController controller) => int.tryParse(controller.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final courseData = {
      "course_code": _courseCodeCtrl.text.trim(),
      "course_title": _courseTitleCtrl.text.trim(),
      "credits": {
        "L": _intFrom(_lCtrl),
        "T": _intFrom(_tCtrl),
        "P": _intFrom(_pCtrl),
        "total": _totalCredits,
      },
      "hours_per_week": _intFrom(_hoursPerWeekCtrl),
      "total_hours": _intFrom(_totalHoursCtrl),
      "faculty_assignment": {
        "faculty_name": _facultyNameCtrl.text.trim(),
        "section": _sectionCtrl.text.trim(),
        "academic_year": _academicYearCtrl.text.trim(),
      },
      "course_aim": _courseAimCtrl.text.trim(),
      "course_objectives": _stringsFrom(_courseObjectives),
      "course_outcomes": _courseOutcomes.map((co) => {
        "co": co['co']!.text.trim(),
        "description": co['description']!.text.trim(),
        "bloom": co['bloom']!.text.trim(),
      }).toList(),
      "co_po_pso_mapping": _coPoPsoMappings.map((item) => {
        "co": item['co']!.text.trim(),
        "mapping": {
          "PO1": _intFrom(item['po1']!),
          "PO2": _intFrom(item['po2']!),
          "PSO1": _intFrom(item['pso1']!),
        },
      }).toList(),
      "course_content": _courseUnits.map((unit) => {
        "unit": (unit['unit'] as TextEditingController).text.trim(),
        "topics": _stringsFrom(unit['topics'] as List<TextEditingController>),
      }).toList(),
      "books": {
        "textbooks": _stringsFrom(_textbooks),
        "references": _stringsFrom(_references),
      },
      "teaching_plan": _teachingPlan.map((item) => {
        "lecture": _intFrom(item['lecture']!),
        "topic": item['topic']!.text.trim(),
      }).toList(),
      "assessment": {
        "structure": {
          "quiz": {
            "total": _intFrom(_quizTotalCtrl),
            "Q1": _intFrom(_quizQ1Ctrl),
            "Q2": _intFrom(_quizQ2Ctrl),
            "Q3": _intFrom(_quizQ3Ctrl),
          },
          "test": {
            "total": _intFrom(_testTotalCtrl),
            "T1": _intFrom(_testT1Ctrl),
            "T2": _intFrom(_testT2Ctrl),
          },
          "assignment": {
            "total": _intFrom(_assignmentTotalCtrl),
            "A1": _intFrom(_assignmentA1Ctrl),
            "A2": _intFrom(_assignmentA2Ctrl),
          },
          "cie": _intFrom(_cieCtrl),
          "see": _intFrom(_seeCtrl),
        },
        "co_distribution": _assessmentCoDistribution.map((item) => {
          "co": item['co']!.text.trim(),
          "cie": _intFrom(item['cie']!),
          "see": _intFrom(item['see']!),
        }).toList(),
      },
      "attainment_targets": {
        "criteria": {
          "level_1": _level1Ctrl.text.trim(),
          "level_2": _level2Ctrl.text.trim(),
          "level_3": _level3Ctrl.text.trim(),
        },
        "co_targets": _coTargets.map((item) => {
          "co": item['co']!.text.trim(),
          "target_level": _intFrom(item['target_level']!),
        }).toList(),
      },
      "grading": {
        for (final entry in _gradingCtrls.entries) entry.key: entry.value.text.trim(),
      },
    };

    try {
      if (widget.initialCourse != null) {
        await apiService.updateCourse(
          _programCode,
          _semester,
          courseData,
          semesterDuration: {
            "teaching_weeks": _teachingWeeksCtrl.text.trim(),
            "exam_weeks": _examWeeksCtrl.text.trim(),
            "result_weeks": _resultWeeksCtrl.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course Updated Successfully!')),
          );
          widget.onSaveSuccess?.call();
        }
      } else {
        await apiService.addCourse(
          _programCode,
          _semester,
          courseData,
          semesterDuration: {
            "teaching_weeks": _teachingWeeksCtrl.text.trim(),
            "exam_weeks": _examWeeksCtrl.text.trim(),
            "result_weeks": _resultWeeksCtrl.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course Assigned Successfully!')),
          );
          _formKey.currentState?.reset();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _addCourseObjective() => setState(() => _courseObjectives.add(TextEditingController()));
  void _addTextbook() => setState(() => _textbooks.add(TextEditingController()));
  void _addReference() => setState(() => _references.add(TextEditingController()));

  void _removeTextController(List<TextEditingController> list, int index) {
    setState(() {
      list.removeAt(index).dispose();
      if (list.isEmpty) list.add(TextEditingController());
    });
  }

  void _addCourseOutcome() {
    setState(() {
      _courseOutcomes.add({
        'co': TextEditingController(),
        'description': TextEditingController(),
        'bloom': TextEditingController(),
      });
    });
  }

  void _addCoPoPsoMapping() {
    setState(() {
      _coPoPsoMappings.add({
        'co': TextEditingController(),
        'po1': TextEditingController(),
        'po2': TextEditingController(),
        'pso1': TextEditingController(),
      });
    });
  }

  void _addCourseUnit() {
    setState(() {
      _courseUnits.add({
        'unit': TextEditingController(),
        'topics': <TextEditingController>[TextEditingController()],
      });
    });
  }

  void _addTopicToUnit(int unitIndex) {
    setState(() {
      (_courseUnits[unitIndex]['topics'] as List<TextEditingController>).add(TextEditingController());
    });
  }

  void _addTeachingPlanItem() {
    setState(() {
      _teachingPlan.add({
        'lecture': TextEditingController(),
        'topic': TextEditingController(),
      });
    });
  }

  void _addAssessmentCoDistribution() {
    setState(() {
      _assessmentCoDistribution.add({
        'co': TextEditingController(),
        'cie': TextEditingController(),
        'see': TextEditingController(),
      });
    });
  }

  void _addCoTarget() {
    setState(() {
      _coTargets.add({
        'co': TextEditingController(),
        'target_level': TextEditingController(),
      });
    });
  }

  void _removeMapRow(List<Map<String, TextEditingController>> list, int index, VoidCallback addFallback) {
    var needsFallback = false;
    setState(() {
      for (final controller in list.removeAt(index).values) {
        controller.dispose();
      }
      needsFallback = list.isEmpty;
    });
    if (needsFallback) addFallback();
  }

  void _removeCourseUnit(int index) {
    var needsFallback = false;
    setState(() {
      final unit = _courseUnits.removeAt(index);
      (unit['unit'] as TextEditingController).dispose();
      for (final topic in unit['topics'] as List<TextEditingController>) {
        topic.dispose();
      }
      needsFallback = _courseUnits.isEmpty;
    });
    if (needsFallback) _addCourseUnit();
  }

  void _removeTopicFromUnit(int unitIndex, int topicIndex) {
    setState(() {
      final topics = _courseUnits[unitIndex]['topics'] as List<TextEditingController>;
      topics.removeAt(topicIndex).dispose();
      if (topics.isEmpty) topics.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    final controllers = [
      _courseCodeCtrl,
      _courseTitleCtrl,
      _teachingWeeksCtrl,
      _examWeeksCtrl,
      _resultWeeksCtrl,
      _lCtrl,
      _tCtrl,
      _pCtrl,
      _hoursPerWeekCtrl,
      _totalHoursCtrl,
      _facultyNameCtrl,
      _sectionCtrl,
      _academicYearCtrl,
      _courseAimCtrl,
      _quizTotalCtrl,
      _quizQ1Ctrl,
      _quizQ2Ctrl,
      _quizQ3Ctrl,
      _testTotalCtrl,
      _testT1Ctrl,
      _testT2Ctrl,
      _assignmentTotalCtrl,
      _assignmentA1Ctrl,
      _assignmentA2Ctrl,
      _cieCtrl,
      _seeCtrl,
      _level1Ctrl,
      _level2Ctrl,
      _level3Ctrl,
      ..._gradingCtrls.values,
      ..._courseObjectives,
      ..._textbooks,
      ..._references,
    ];
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final row in [..._courseOutcomes, ..._coPoPsoMappings, ..._teachingPlan, ..._assessmentCoDistribution, ..._coTargets]) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    for (final unit in _courseUnits) {
      (unit['unit'] as TextEditingController).dispose();
      for (final topic in unit['topics'] as List<TextEditingController>) {
        topic.dispose();
      }
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int flex = 1,
    bool required = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Expanded(
      flex: flex,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onChanged: onChanged,
        validator: required ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _textListSection(String title, List<TextEditingController> controllers, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        ...controllers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _field(entry.value, title),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTextController(controllers, entry.key),
                ),
              ],
            ),
          );
        }),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text('Add $title')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
              ),
            Text(widget.initialCourse != null ? 'Edit Course' : 'Assign Course', style: Theme.of(context).textTheme.headlineMedium),
            _sectionTitle('Program and Semester'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Program Code', border: OutlineInputBorder()),
                    value: _programCode,
                    items: ['CS', 'IS', 'ECE', 'DS'].map((value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: widget.initialCourse != null ? null : (val) => setState(() => _programCode = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                    value: _semester,
                    items: List.generate(8, (index) => index + 1).map((value) {
                      return DropdownMenuItem<int>(value: value, child: Text('Semester $value'));
                    }).toList(),
                    onChanged: widget.initialCourse != null ? null : (val) => setState(() => _semester = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_teachingWeeksCtrl, 'Teaching Weeks'),
                const SizedBox(width: 16),
                _field(_examWeeksCtrl, 'Exam Weeks'),
                const SizedBox(width: 16),
                _field(_resultWeeksCtrl, 'Result Weeks'),
              ],
            ),
            _sectionTitle('Course Details'),
            Row(
              children: [
                _field(_courseCodeCtrl, 'Course Code', required: true, readOnly: widget.initialCourse != null),
                const SizedBox(width: 16),
                _field(_courseTitleCtrl, 'Course Title', flex: 2, required: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_lCtrl, 'L', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                const SizedBox(width: 8),
                _field(_tCtrl, 'T', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                const SizedBox(width: 8),
                _field(_pCtrl, 'P', keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                const SizedBox(width: 16),
                Text('Total Credits: $_totalCredits', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_hoursPerWeekCtrl, 'Hours/Week', keyboardType: TextInputType.number),
                const SizedBox(width: 16),
                _field(_totalHoursCtrl, 'Total Hours', keyboardType: TextInputType.number),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_facultyNameCtrl, 'Faculty Name'),
                const SizedBox(width: 16),
                _field(_sectionCtrl, 'Section'),
                const SizedBox(width: 16),
                _field(_academicYearCtrl, 'Academic Year'),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [_field(_courseAimCtrl, 'Course Aim', maxLines: 3)]),
            _textListSection('Course Objective', _courseObjectives, _addCourseObjective),
            _sectionTitle('Course Outcomes'),
            ..._courseOutcomes.asMap().entries.map((entry) {
              final co = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _field(co['co']!, 'CO'),
                    const SizedBox(width: 8),
                    _field(co['description']!, 'Description', flex: 3),
                    const SizedBox(width: 8),
                    _field(co['bloom']!, 'Bloom Level', flex: 2),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMapRow(_courseOutcomes, entry.key, _addCourseOutcome),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addCourseOutcome, icon: const Icon(Icons.add), label: const Text('Add Outcome')),
            _sectionTitle('CO-PO/PSO Mapping'),
            ..._coPoPsoMappings.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _field(item['co']!, 'CO'),
                    const SizedBox(width: 8),
                    _field(item['po1']!, 'PO1', keyboardType: TextInputType.number),
                    const SizedBox(width: 8),
                    _field(item['po2']!, 'PO2', keyboardType: TextInputType.number),
                    const SizedBox(width: 8),
                    _field(item['pso1']!, 'PSO1', keyboardType: TextInputType.number),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMapRow(_coPoPsoMappings, entry.key, _addCoPoPsoMapping),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addCoPoPsoMapping, icon: const Icon(Icons.add), label: const Text('Add Mapping')),
            _sectionTitle('Units and Topics'),
            ..._courseUnits.asMap().entries.map((unitEntry) {
              final unitIdx = unitEntry.key;
              final unitData = unitEntry.value;
              final unitCtrl = unitData['unit'] as TextEditingController;
              final topics = unitData['topics'] as List<TextEditingController>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _field(unitCtrl, 'Unit Name'),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeCourseUnit(unitIdx)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...topics.asMap().entries.map((topicEntry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              _field(topicEntry.value, 'Topic'),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeTopicFromUnit(unitIdx, topicEntry.key),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(onPressed: () => _addTopicToUnit(unitIdx), icon: const Icon(Icons.add), label: const Text('Add Topic')),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addCourseUnit, icon: const Icon(Icons.add), label: const Text('Add Unit')),
            _textListSection('Textbook', _textbooks, _addTextbook),
            _textListSection('Reference', _references, _addReference),
            _sectionTitle('Teaching Plan'),
            ..._teachingPlan.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _field(item['lecture']!, 'Lecture', keyboardType: TextInputType.number),
                    const SizedBox(width: 8),
                    _field(item['topic']!, 'Topic', flex: 4),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMapRow(_teachingPlan, entry.key, _addTeachingPlanItem),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addTeachingPlanItem, icon: const Icon(Icons.add), label: const Text('Add Lecture')),
            _sectionTitle('Assessment Structure'),
            Row(
              children: [
                _field(_quizTotalCtrl, 'Quiz Total', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_quizQ1Ctrl, 'Q1', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_quizQ2Ctrl, 'Q2', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_quizQ3Ctrl, 'Q3', keyboardType: TextInputType.number),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field(_testTotalCtrl, 'Test Total', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_testT1Ctrl, 'T1', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_testT2Ctrl, 'T2', keyboardType: TextInputType.number),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _field(_assignmentTotalCtrl, 'Assignment Total', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_assignmentA1Ctrl, 'A1', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_assignmentA2Ctrl, 'A2', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_cieCtrl, 'CIE', keyboardType: TextInputType.number),
                const SizedBox(width: 8),
                _field(_seeCtrl, 'SEE', keyboardType: TextInputType.number),
              ],
            ),
            _sectionTitle('Assessment CO Distribution'),
            ..._assessmentCoDistribution.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _field(item['co']!, 'CO'),
                    const SizedBox(width: 8),
                    _field(item['cie']!, 'CIE', keyboardType: TextInputType.number),
                    const SizedBox(width: 8),
                    _field(item['see']!, 'SEE', keyboardType: TextInputType.number),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMapRow(_assessmentCoDistribution, entry.key, _addAssessmentCoDistribution),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addAssessmentCoDistribution, icon: const Icon(Icons.add), label: const Text('Add CO Distribution')),
            _sectionTitle('Attainment Targets'),
            Row(children: [_field(_level1Ctrl, 'Level 1 Criteria')]),
            const SizedBox(height: 8),
            Row(children: [_field(_level2Ctrl, 'Level 2 Criteria')]),
            const SizedBox(height: 8),
            Row(children: [_field(_level3Ctrl, 'Level 3 Criteria')]),
            const SizedBox(height: 12),
            ..._coTargets.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _field(item['co']!, 'CO'),
                    const SizedBox(width: 8),
                    _field(item['target_level']!, 'Target Level', keyboardType: TextInputType.number),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMapRow(_coTargets, entry.key, _addCoTarget),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton.icon(onPressed: _addCoTarget, icon: const Icon(Icons.add), label: const Text('Add CO Target')),
            _sectionTitle('Grading'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _gradingCtrls.entries.map((entry) {
                return SizedBox(
                  width: 150,
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key, border: const OutlineInputBorder()),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _submit,
                      child: Text(widget.initialCourse != null ? 'Update Course' : 'Submit Course'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

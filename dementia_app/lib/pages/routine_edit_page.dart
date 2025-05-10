import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:dementia_app/pages/routine_list_page.dart';

class GuardianEditRoutinePage extends StatefulWidget {
  final String patientUid;
  final Routine routine;
  const GuardianEditRoutinePage({
    super.key,
    required this.patientUid,
    required this.routine,
  });

  @override
  State<GuardianEditRoutinePage> createState() =>
      _GuardianEditRoutinePageState();
}

class _GuardianEditRoutinePageState extends State<GuardianEditRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine.title);
    _selectedDateTime = widget.routine.dateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('routines')
          .doc(widget.routine.id)
          .update({
            'title': _titleController.text,
            'dateTime': _selectedDateTime,
          });
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update routine.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text('Edit Routine'),
        backgroundColor: const Color(0xFF80C4E9),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Routine Title',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDateTime == null
                                  ? 'No date/time chosen'
                                  : DateFormat(
                                    'yyyy-MM-dd hh:mm a',
                                  ).format(_selectedDateTime!),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickDateTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF80C4E9),
                            ),
                            child: const Text('Pick Date & Time'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            backgroundColor: const Color(0xFFFDDDE6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Update Routine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dementia_app/pages/routine_edit_page.dart';

class Routine {
  final String id;
  final String title;
  final DateTime dateTime;

  Routine({required this.id, required this.title, required this.dateTime});

  factory Routine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Routine(
      id: doc.id,
      title: data['title'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
    );
  }

  String get formattedDateTime =>
      DateFormat('EEE, MMM d • hh:mm a').format(dateTime);
}

Future<List<Routine>> getRoutinesForPatient(String patientUid) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientUid)
          .collection('routines')
          .orderBy('dateTime')
          .get();

  return snapshot.docs.map((doc) => Routine.fromFirestore(doc)).toList();
}

class GuardianRoutineListPage extends StatefulWidget {
  final String patientUid;
  const GuardianRoutineListPage({super.key, required this.patientUid});

  @override
  State<GuardianRoutineListPage> createState() =>
      _GuardianRoutineListPageState();
}

class _GuardianRoutineListPageState extends State<GuardianRoutineListPage> {
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _routines = await getRoutinesForPatient(widget.patientUid);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load routines.';
      });
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientUid)
          .collection('routines')
          .doc(routine.id)
          .delete();
      _loadRoutines();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete routine.';
      });
    }
  }

  void _editRoutine(Routine routine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => GuardianEditRoutinePage(
              patientUid: widget.patientUid,
              routine: routine,
            ),
      ),
    );
    if (result == true) _loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text('Manage Routines'),
        backgroundColor: const Color(0xFF80C4E9),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _routines.isEmpty
              ? const Center(child: Text('No routines found.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _routines.length,
                itemBuilder: (context, index) {
                  final routine = _routines[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      title: Text(
                        routine.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        routine.formattedDateTime,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.indigo),
                            onPressed: () => _editRoutine(routine),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteRoutine(routine),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

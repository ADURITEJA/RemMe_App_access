import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianRoutineListPage extends StatefulWidget {
  final String patientUid;

  const GuardianRoutineListPage({super.key, required this.patientUid});

  @override
  State<GuardianRoutineListPage> createState() =>
      _GuardianRoutineListPageState();
}

class _GuardianRoutineListPageState extends State<GuardianRoutineListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent.shade100.withOpacity(0.85),
        title: const Text("🌈 Patient Routines"),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDCBDA), Color(0xFFB4E4FF), Color(0xFFC1FFD7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('patients')
                  .doc(widget.patientUid)
                  .collection('routines')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading routines.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final routines = snapshot.data!.docs;

            if (routines.isEmpty) {
              return const Center(child: Text("✨ No routines yet."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index].data() as Map<String, dynamic>;
                final docId = routines[index].id;

                return Card(
                  color: Colors.purple.shade100.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(
                      routine['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (routine['time'] != null)
                          Text('🕒 Time: ${routine['time']}'),
                        if (routine['days'] != null)
                          Text('📅 Days: ${routine['days'].join(', ')}'),
                        if (routine['repeat'] != null)
                          Text('🔁 Repeat: ${routine['repeat']}'),
                        if (routine['notes'] != null)
                          Text('📝 Notes: ${routine['notes']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.deepPurple),
                      onPressed: () => _showEditRoutineDialog(docId, routine),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditRoutineDialog(null, {}),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditRoutineDialog(String? docId, Map<String, dynamic> routine) {
    final titleController = TextEditingController(text: routine['title'] ?? '');
    final timeController = TextEditingController(text: routine['time'] ?? '');
    final notesController = TextEditingController(text: routine['notes'] ?? '');
    final repeatController = TextEditingController(
      text: routine['repeat'] ?? '',
    );
    final daysController = TextEditingController(
      text: (routine['days'] as List?)?.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.pink.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              docId == null ? '🆕 Add Routine' : '✏️ Edit Routine',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _customField('Title', titleController),
                  _customField('Time', timeController),
                  _customField('Days (Mon, Tue...)', daysController),
                  _customField('Repeat', repeatController),
                  _customField('Notes', notesController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'title': titleController.text.trim(),
                    'time': timeController.text.trim(),
                    'days':
                        daysController.text
                            .split(',')
                            .map((d) => d.trim())
                            .toList(),
                    'repeat': repeatController.text.trim(),
                    'notes': notesController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  final collection = FirebaseFirestore.instance
                      .collection('patients')
                      .doc(widget.patientUid)
                      .collection('routines');

                  if (docId == null) {
                    await collection.add(data);
                  } else {
                    await collection.doc(docId).update(data);
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget _customField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.purple.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

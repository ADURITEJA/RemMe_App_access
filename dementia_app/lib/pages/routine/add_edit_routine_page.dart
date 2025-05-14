import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/routine_model.dart';
import '../../services/routine_service.dart';

// Custom colors
const Color royalBlue = Color(0xFF3D56B2);
const Color quickSand = Color(0xFFF5E6CA);
const Color swanWing = Color(0xFFF7F7F7);
const Color darkBlue = Color(0xFF2C3E50);
const Color successGreen = Color(0xFF2ECC71);

class AddEditRoutinePage extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final Routine? routineToEdit;

  const AddEditRoutinePage({
    Key? key,
    required this.patientUid,
    required this.patientName,
    this.routineToEdit,
  }) : super(key: key);

  @override
  _AddEditRoutinePageState createState() => _AddEditRoutinePageState();
}

class _AddEditRoutinePageState extends State<AddEditRoutinePage> {
  final _formKey = GlobalKey<FormState>();
  late final RoutineService _routineService;
  
  // Form fields
  late String _title;
  late String _description;
  late TimeOfDay _time;
  final List<String> _selectedDays = [];
  bool _isActive = true;
  String? _category;
  final Map<String, dynamic> _additionalData = {};

  // Available options
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _categories = [
    'Medication',
    'Meal',
    'Exercise',
    'Appointment',
    'Personal Care',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _routineService = RoutineService();
    
    // Initialize with existing routine data if editing
    if (widget.routineToEdit != null) {
      final routine = widget.routineToEdit!;
      _title = routine.title;
      _description = routine.description;
      _time = TimeOfDay.fromDateTime(routine.time);
      _selectedDays.addAll(routine.days);
      _isActive = routine.isActive;
      _category = routine.category;
      if (routine.additionalData != null) {
        _additionalData.addAll(routine.additionalData!);
      }
    } else {
      _title = '';
      _description = '';
      _time = TimeOfDay.now();
      _isActive = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: royalBlue,
        title: Text(
          widget.routineToEdit == null ? 'New Reminder' : 'Edit Reminder',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.routineToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: _confirmDelete,
              tooltip: 'Delete Routine',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Reminder Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ),
            
            // Title
            _buildCard(
              child: TextFormField(
                style: const TextStyle(fontSize: 16),
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: darkBlue.withOpacity(0.7)),
                  hintText: 'e.g., Morning Medication',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _title = value!.trim(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            _buildCard(
              child: TextFormField(
                style: const TextStyle(fontSize: 16),
                initialValue: _description,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: darkBlue.withOpacity(0.7)),
                  hintText: 'Enter details about this reminder',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) => _description = value!.trim(),
              ),
            ),
            
            const SizedBox(height: 16),
            // Category
            _buildCard(
              child: DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: darkBlue.withOpacity(0.7)),
                  border: InputBorder.none,
                  hintText: 'Select a category',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                dropdownColor: Colors.white,
                items: _categories
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                icon: Icon(Icons.keyboard_arrow_down, color: darkBlue),
              ),
            ),
            
            const SizedBox(height: 16),
            // Time Picker
            _buildCard(
              child: InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: royalBlue, size: 24),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _time.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // Days of Week
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat on',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: FilterChip(
                          label: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                              color: isSelected ? Colors.white : darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: royalBlue,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? royalBlue : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            // Active Toggle
            _buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isActive ? 'This reminder is active' : 'This reminder is paused',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch.adaptive(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: royalBlue,
                      activeTrackColor: royalBlue.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [royalBlue, royalBlue.withBlue(180)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: royalBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _saveRoutine,
                  onHover: (hovered) {
                    // Hover effect
                  },
                  child: Center(
                    child: Text(
                      widget.routineToEdit == null ? 'SAVE REMINDER' : 'UPDATE REMINDER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create card with shadow
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: royalBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one day'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red[400],
          ),
        );
      }
      return;
    }

    _formKey.currentState!.save();

    try {
      final routineTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _time.hour,
        _time.minute,
      );

      final routine = Routine(
        id: widget.routineToEdit?.id ?? const Uuid().v4(),
        patientUid: widget.patientUid,
        title: _title,
        description: _description,
        time: routineTime,
        days: _selectedDays,
        isActive: _isActive,
        category: _category,
        additionalData: _additionalData.isNotEmpty ? _additionalData : null,
        notificationId: widget.routineToEdit?.notificationId,
      );

      if (widget.routineToEdit == null) {
        await _routineService.addRoutine(routine);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine added successfully')),
        );
      } else {
        await _routineService.updateRoutine(routine);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine updated successfully')),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save routine: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Reminder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this reminder? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRoutine();
    }
  }

  Future<void> _deleteRoutine() async {
    try {
      if (widget.routineToEdit != null) {
        await _routineService.deleteRoutine(
          widget.routineToEdit!.id,
          widget.routineToEdit!.notificationId,
        );
        if (!mounted) return;
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reminder deleted successfully'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: successGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete reminder: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }
}

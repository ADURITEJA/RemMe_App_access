import 'package:flutter/material.dart';
import '../../models/routine_model.dart';
import '../../services/routine_service.dart';
import 'add_edit_routine_page.dart';

// Custom colors
const Color royalBlue = Color(0xFF3D56B2);
const Color quickSand = Color(0xFFF5E6CA);
const Color swanWing = Color(0xFFF7F7F7);
const Color darkBlue = Color(0xFF2C3E50);
const Color successGreen = Color(0xFF2ECC71);

class RoutineListPage extends StatefulWidget {
  final String patientUid;
  final String patientName;

  const RoutineListPage({
    Key? key,
    required this.patientUid,
    required this.patientName,
  }) : super(key: key);

  @override
  _RoutineListPageState createState() => _RoutineListPageState();
}

class _RoutineListPageState extends State<RoutineListPage> {
  late final RoutineService _routineService;

  @override
  void initState() {
    super.initState();
    _routineService = RoutineService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: swanWing,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: royalBlue,
        title: Text(
          '${widget.patientName}\'s Reminders',
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
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            onPressed: () => _navigateToAddRoutine(),
            tooltip: 'Add New Reminder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Routine>>(
        stream: _routineService.getRoutinesForPatient(widget.patientUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(royalBlue),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading reminders: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final routines = snapshot.data ?? [];

          if (routines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'No Reminders Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create your first reminder to help manage daily activities',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 50,
                      width: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [royalBlue, royalBlue.withBlue(180)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: royalBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _navigateToAddRoutine,
                          onHover: (hovered) {},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'CREATE REMINDER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(seconds: 1));
            },
            color: royalBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRoutineCard(routine),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateToEditRoutine(routine),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time and Icon
                Container(
                  width: 70,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(routine.time).split(' ')[0],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: routine.isActive ? royalBlue : Colors.grey[400],
                        ),
                      ),
                      Text(
                        _formatTime(routine.time).split(' ')[1],
                        style: TextStyle(
                          fontSize: 12,
                          color: routine.isActive ? royalBlue.withOpacity(0.8) : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: routine.isActive 
                        ? royalBlue.withOpacity(0.1) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForCategory(routine.category),
                    color: routine.isActive ? royalBlue : Colors.grey[400],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: routine.isActive ? darkBlue : Colors.grey[500],
                          decoration: routine.isActive ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: routine.isActive ? Colors.grey[600] : Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: routine.days.map((day) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: routine.isActive 
                                  ? royalBlue.withOpacity(0.1) 
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: routine.isActive ? royalBlue : Colors.grey[500],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Toggle
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: routine.isActive,
                    onChanged: (_) => _toggleRoutineStatus(routine),
                    activeColor: royalBlue,
                    activeTrackColor: royalBlue.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final hourStr = hour == 0 ? '12' : hour.toString();
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'medication':
        return Icons.medication_outlined;
      case 'meal':
        return Icons.restaurant_outlined;
      case 'exercise':
        return Icons.directions_run;
      case 'appointment':
        return Icons.calendar_today_outlined;
      case 'personal care':
        return Icons.person_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Future<void> _toggleRoutineStatus(Routine routine) async {
    try {
      await _routineService.toggleRoutineStatus(routine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder ${routine.isActive ? 'activated' : 'paused'}' + 
              (routine.isActive ? ' \u{1F44D}' : ' \u{23F8}'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: routine.isActive ? successGreen : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reminder: $e'),
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

  void _navigateToAddRoutine() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEditRoutinePage(
          patientUid: widget.patientUid,
          patientName: widget.patientName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    
    // Refresh the list if a new routine was added
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _navigateToEditRoutine(Routine routine) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEditRoutinePage(
          patientUid: widget.patientUid,
          patientName: widget.patientName,
          routineToEdit: routine,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
    
    // Refresh the list if the routine was updated
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

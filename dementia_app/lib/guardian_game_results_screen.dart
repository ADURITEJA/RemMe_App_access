import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GuardianGameResultsScreen extends StatefulWidget {
  final String patientId; // ID of the patient whose results we're viewing

  const GuardianGameResultsScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  _GuardianGameResultsScreenState createState() =>
      _GuardianGameResultsScreenState();
}

class _GuardianGameResultsScreenState extends State<GuardianGameResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gameResults = [];
  Map<String, dynamic> _monthlyStats = {};

  @override
  void initState() {
    super.initState();
    _loadGameResults();
  }

  Future<void> _loadGameResults() async {
    try {
      // Get game results from Firestore
      final resultsSnapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(widget.patientId)
              .collection('game_results')
              .orderBy('timestamp', descending: true)
              .get();

      final results =
          resultsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'timestamp': data['timestamp'].toDate(),
              'correctAnswers': data['correctAnswers'],
              'totalQuestions': data['totalQuestions'],
              'memoryNames': List<String>.from(data['memoryNames'] ?? []),
            };
          }).toList();

      // Calculate monthly statistics
      final Map<String, dynamic> monthlyStats = {};
      for (var result in results) {
        final date = result['timestamp'] as DateTime;
        final monthKey = DateFormat('MMMM yyyy').format(date);

        if (!monthlyStats.containsKey(monthKey)) {
          monthlyStats[monthKey] = {
            'totalCorrect': 0,
            'totalQuestions': 0,
            'gamesPlayed': 0,
          };
        }

        monthlyStats[monthKey]['totalCorrect'] += result['correctAnswers'];
        monthlyStats[monthKey]['totalQuestions'] += result['totalQuestions'];
        monthlyStats[monthKey]['gamesPlayed']++;
      }

      setState(() {
        _gameResults = results;
        _monthlyStats = monthlyStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading game results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Progress Section
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Monthly Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._monthlyStats.entries.map((entry) {
                      final stats = entry.value;
                      final accuracy =
                          stats['totalQuestions'] > 0
                              ? (stats['totalCorrect'] /
                                      stats['totalQuestions'] *
                                      100)
                                  .toStringAsFixed(1)
                              : '0';

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'Accuracy',
                                  value: '$accuracy%',
                                ),
                                _StatItem(
                                  label: 'Games Played',
                                  value: '${stats['gamesPlayed']}',
                                ),
                                _StatItem(
                                  label: 'Correct Answers',
                                  value: '${stats['totalCorrect']}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Recent Games Section
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Recent Games',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._gameResults.map((result) {
                      final accuracy = (result['correctAnswers'] /
                              result['totalQuestions'] *
                              100)
                          .toStringAsFixed(1);
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy - h:mm a',
                                  ).format(result['timestamp']),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        double.parse(accuracy) >= 70
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$accuracy%',
                                    style: TextStyle(
                                      color:
                                          double.parse(accuracy) >= 70
                                              ? Colors.green[900]
                                              : Colors.orange[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Score: ${result['correctAnswers']}/${result['totalQuestions']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (result['memoryNames']?.isNotEmpty ?? false) ...[
                              SizedBox(height: 8),
                              Text(
                                'Memories: ${result['memoryNames'].join(", ")}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}

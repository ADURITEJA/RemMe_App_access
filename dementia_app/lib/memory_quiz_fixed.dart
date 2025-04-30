import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryQuizGame extends StatefulWidget {
  const MemoryQuizGame({Key? key}) : super(key: key);

  @override
  _MemoryQuizGameState createState() => _MemoryQuizGameState();
}

class _MemoryQuizGameState extends State<MemoryQuizGame> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _memories = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  String? _selectedAnswer;
  List<String> _options = [];
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadMemoriesAndScore();
  }

  Future<void> _loadMemoriesAndScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's memories
      final memoriesSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('memories')
              .get();

      setState(() {
        _memories =
            memoriesSnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
        _isLoading = false;
      });

      // Load score from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _score = prefs.getInt('memory_quiz_score') ?? 0;
      });

      if (_memories.isNotEmpty) {
        _generateOptions();
      }
    } catch (e) {
      print('Error loading memories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateOptions() {
    if (_memories.isEmpty) return;

    final currentMemory = _memories[_currentIndex];
    final correctAnswer = currentMemory['objectName'] as String;

    // Create a list of all possible answers
    List<String> allAnswers =
        _memories.map((memory) => memory['objectName'] as String).toList();

    // Remove the correct answer from the list
    allAnswers.remove(correctAnswer);

    // Shuffle the remaining answers
    allAnswers.shuffle();

    // Take 3 random wrong answers
    final wrongAnswers = allAnswers.take(3).toList();

    // Create the final options list with the correct answer and 3 wrong answers
    setState(() {
      _options = [correctAnswer, ...wrongAnswers];
      _options.shuffle(); // Shuffle the final options
    });
  }

  void _checkAnswer(String selectedAnswer) {
    if (_memories.isEmpty) return;

    final currentMemory = _memories[_currentIndex];
    final correctAnswer = currentMemory['objectName'] as String;

    setState(() {
      _selectedAnswer = selectedAnswer;
      _isCorrect = selectedAnswer == correctAnswer;
      _showResult = true;

      if (_isCorrect) {
        _score += 10;
      }
    });

    // Save score to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('memory_quiz_score', _score);
    });

    // Update score in Firestore
    _updateScoreInFirestore();
  }

  Future<void> _updateScoreInFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'memoryQuizScore': _score,
        'lastMemoryQuizPlayed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _memories.length;
      _selectedAnswer = null;
      _showResult = false;
      _generateOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memories.isEmpty) {
      return const Center(
        child: Text('No memories found. Add some memories first!'),
      );
    }

    final currentMemory = _memories[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Memory Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                currentMemory['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Question
            Text(
              'What is this object?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Options
            ..._options.map(
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _showResult ? null : () => _checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _getButtonColor(option),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Result and Next Button
            if (_showResult) ...[
              Text(
                _isCorrect ? 'Correct! +10 points' : 'Incorrect!',
                style: TextStyle(
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('Next Question'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _getButtonColor(String option) {
    if (!_showResult) return null;

    if (option == _selectedAnswer) {
      return _isCorrect ? Colors.green : Colors.red;
    }

    if (option == _memories[_currentIndex]['objectName']) {
      return Colors.green;
    }

    return null;
  }
}

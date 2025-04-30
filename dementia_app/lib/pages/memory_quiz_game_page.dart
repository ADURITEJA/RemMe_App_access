import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class MemoryQuizGamePage extends StatefulWidget {
  const MemoryQuizGamePage({super.key});

  @override
  State<MemoryQuizGamePage> createState() => _MemoryQuizGamePageState();
}

class _MemoryQuizGamePageState extends State<MemoryQuizGamePage>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _memories = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animController;
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadMemoriesAndScore();
  }

  @override
  void didUpdateWidget(covariant MemoryQuizGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generateOptions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoriesAndScore() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .collection('memories')
              .get();

      _memories =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'imageUrl': data['imageUrl'],
              'text': data['text'],
              'dateTime': data['dateTime'].toDate(),
            };
          }).toList();

      // Load score
      final scoreDoc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .get();
      _score = scoreDoc.data()?['cutePoints'] ?? 0;

      _memories.shuffle(Random());
      _generateOptions();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load memories/game.';
      });
    }
  }

  void _generateOptions() {
    if (_memories.isEmpty) return;

    if (_memories.length < 2) {
      _options = [_memories[_currentIndex]['text']];
      return;
    }

    final correct = _memories[_currentIndex]['text'];
    final otherMemories =
        _memories
            .map((m) => m['text'] as String)
            .where((t) => t != correct)
            .toList();

    otherMemories.shuffle(Random());
    _options = [correct, ...otherMemories.take(3)];
    _options.shuffle(Random());
  }

  void _checkAnswer(String selected) async {
    final correct =
        selected.trim().toLowerCase() ==
        _memories[_currentIndex]['text'].trim().toLowerCase();

    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });

    _animController.forward(from: 0);

    if (correct) {
      _score += 10;
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .set({'cutePoints': _score}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .collection('scores')
          .add({'score': 10, 'timestamp': DateTime.now()});
    }

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showResult = false;
        if (_currentIndex < _memories.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
          _memories.shuffle(Random());
        }
        _generateOptions();
      });
    });
  }

  Widget _buildCuteAnimation() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.7, end: 1.2).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
      ),
      child:
          _isCorrect
              ? Column(
                children: [
                  Icon(Icons.emoji_emotions, color: Colors.pink, size: 80),
                  const Text(
                    'Yay! Cute points +10',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    color: Colors.blueGrey,
                    size: 80,
                  ),
                  const Text(
                    'Oops! Try again!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_memories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memory Quiz Game')),
        body: const Center(
          child: Text('No memories found. Add some memories first!'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Quiz Game'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Cute Points: $_score',
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
                _memories[_currentIndex]['imageUrl'],
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
              'What memory is this?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Multiple Choice Options
            ..._options.map(
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _showResult ? null : () => _checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Animation for result
            if (_showResult) Center(child: _buildCuteAnimation()),
          ],
        ),
      ),
    );
  }
}

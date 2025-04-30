import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NostalgicObject {
  final String imageUrl;
  final String name;
  final List<String> options;
  bool isUnlocked;

  NostalgicObject({
    required this.imageUrl,
    required this.name,
    required this.options,
    this.isUnlocked = false,
  });
}

class NostalgicObjectGameScreen extends StatefulWidget {
  @override
  _NostalgicObjectGameScreenState createState() =>
      _NostalgicObjectGameScreenState();
}

class _NostalgicObjectGameScreenState extends State<NostalgicObjectGameScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<NostalgicObject> objects = [];
  int currentIndex = 0;
  String? feedback;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user!.uid)
              .collection('memories')
              .get();

      final loadedObjects =
          snapshot.docs.map((doc) {
            final data = doc.data();
            // Create a list of options including the correct answer and one wrong answer
            List<String> options = [data['text']];
            // Add a random wrong option (you might want to improve this logic)
            options.add('Other Memory');
            options.shuffle(); // Randomize the order

            return NostalgicObject(
              imageUrl: data['imageUrl'],
              name: data['text'],
              options: options,
            );
          }).toList();

      setState(() {
        objects = loadedObjects;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading memories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void checkAnswer(String selected) {
    setState(() {
      if (selected == objects[currentIndex].name) {
        objects[currentIndex].isUnlocked = true;
        feedback = 'Correct!';
        _saveGameProgress();
      } else {
        feedback = 'Try again!';
      }
    });
  }

  Future<void> _saveGameProgress() async {
    if (user == null) return;

    try {
      // Calculate game statistics
      final correctAnswers = objects.where((obj) => obj.isUnlocked).length;
      final totalQuestions = objects.length;

      // Get names of correctly answered memories
      final memoryNames =
          objects
              .where((obj) => obj.isUnlocked)
              .map((obj) => obj.name)
              .toList();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .collection('game_results')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'correctAnswers': correctAnswers,
            'totalQuestions': totalQuestions,
            'memoryNames': memoryNames,
          });
    } catch (e) {
      print('Error saving game progress: $e');
    }
  }

  void nextObject() {
    setState(() {
      feedback = null;
      if (currentIndex < objects.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (objects.isEmpty) {
      return Scaffold(
        body: Center(child: Text('No memories available for the game')),
      );
    }

    final obj = objects[currentIndex];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('nostalgic object game', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                '추억의 물건 도감',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: 200,
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          obj.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  Center(child: Text('Image not found')),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'What memory is this?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                        children:
                            obj.options
                                .map(
                                  (option) => ElevatedButton(
                                    onPressed:
                                        feedback == null
                                            ? () => checkAnswer(option)
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    if (feedback != null) ...[
                      SizedBox(height: 20),
                      Text(
                        feedback!,
                        style: TextStyle(
                          color:
                              feedback == 'Correct!'
                                  ? Colors.green
                                  : Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: nextObject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Next'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    objects
                        .map(
                          (obj) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    obj.isUnlocked
                                        ? Colors.green
                                        : Colors.grey[300],
                              ),
                              child: Icon(
                                obj.isUnlocked ? Icons.check : Icons.lock,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

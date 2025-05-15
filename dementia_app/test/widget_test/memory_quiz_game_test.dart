import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockUser extends Mock implements User {
  @override
  final String uid = 'test_uid';
}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Memory Quiz Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockCollectionReference mockPatientsCollection;
    late MockDocumentReference mockPatientDoc;
    late MockCollectionReference mockScoresCollection;
    late _PatientDashboardPageState dashboardPageState;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockPatientsCollection = MockCollectionReference();
      mockPatientDoc = MockDocumentReference();
      mockScoresCollection = MockCollectionReference();
      
      // Set up mock responses
      when(mockFirestore.collection('patients')).thenReturn(mockPatientsCollection);
      when(mockPatientsCollection.doc(any)).thenReturn(mockPatientDoc);
      when(mockPatientDoc.collection('scores')).thenReturn(mockScoresCollection);
      
      // Initialize the dashboard page state
      dashboardPageState = _PatientDashboardPageState();
      // You might need to set up other required properties here
    });

    test('_analyzeQuizResults counts remembered and forgotten attempts correctly', () async {
      // Mock query snapshot with test data
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocs = [
        // Remembered attempts (score > 0)
        _createMockQueryDoc(10, DateTime.now().subtract(Duration(days: 1))),
        _createMockQueryDoc(10, DateTime.now().subtract(Duration(days: 3))),
        // Forgotten attempts (score = 0)
        _createMockQueryDoc(0, DateTime.now().subtract(Duration(days: 2))),
        _createMockQueryDoc(0, DateTime.now().subtract(Duration(days: 4))),
        _createMockQueryDoc(0, DateTime.now().subtract(Duration(days: 10))), // Outside 7-day window
      ];

      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockScoresCollection.orderBy('timestamp', descending: true).get())
          .thenAnswer((_) => Future.value(mockQuerySnapshot));

      // Set the selected time window to 7 days
      dashboardPageState._selectedWindow = '7 days';
      
      // Call the method to test
      await dashboardPageState._analyzeQuizResults();
      
      // Verify the counts
      expect(dashboardPageState.remembered, 2);
      expect(dashboardPageState.forgotten, 2); // Only 2 forgotten within 7 days
      expect(dashboardPageState.totalAttempts, 4); // 2 remembered + 2 forgotten
      
      // Verify percentages (should be 50% for each)
      expect(dashboardPageState.rememberedPercent, 50.0);
      expect(dashboardPageState.forgottenPercent, 50.0);
    });
  });
}

// Helper function to create a mock QueryDocumentSnapshot
MockQueryDocumentSnapshot _createMockQueryDoc(int score, DateTime timestamp) {
  final mockDoc = MockQueryDocumentSnapshot();
  when(mockDoc['score']).thenReturn(score);
  when(mockDoc['timestamp']).thenReturn(Timestamp.fromDate(timestamp));
  return mockDoc;
}

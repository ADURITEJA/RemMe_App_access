import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// This is a test script to simulate a danger zone alert
// Run this in a test environment or development mode

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simulate receiving a danger zone alert
  final testMessage = RemoteMessage(
    data: {
      'type': 'danger_zone',
      'alertId': 'test_alert_123',
      'patientId': 'test_patient_456',
      'location': '37.7749,-122.4194', // San Francisco coordinates
      'timestamp': DateTime.now().toIso8601String(),
    },
    notification: const RemoteNotification(
      title: '🚨 Patient Left Safe Zone',
      body: 'John has left the safe zone!',
    ),
  );

  // Print the test message for verification
  print('Sending test danger zone alert:');
  print('Alert ID: ${testMessage.data['alertId']}');
  print('Patient ID: ${testMessage.data['patientId']}');
  print('Location: ${testMessage.data['location']}');
  print('Timestamp: ${testMessage.data['timestamp']}');
  
  // In a real scenario, this would be handled by Firebase Messaging
  // For testing, you can manually trigger the handler:
  // 1. Run the app
  // 2. Call _handleDangerZoneAlert(testMessage) from your GuardianDashboardPage
  // 3. Or trigger this test message through Firebase Console
  
  // Note: This script is for simulation purposes only
  // In a real app, the message would come from Firebase Cloud Messaging
}

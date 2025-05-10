// File: lib/pages/alerts_log_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlertsLogPage extends StatelessWidget {
  const AlertsLogPage({super.key});

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert History')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('alerts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data?.docs ?? [];

          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts triggered yet.'));
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index].data() as Map<String, dynamic>;
              final resolved = alert['resolved'] == true;
              final lat = alert['lat']?.toStringAsFixed(5) ?? '---';
              final lng = alert['lng']?.toStringAsFixed(5) ?? '---';
              final ts = alert['timestamp'] as Timestamp?;
              final patient = alert['patientName'] ?? 'Unknown';

              return Card(
                color: resolved ? Colors.green.shade50 : Colors.red.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    resolved ? Icons.check_circle : Icons.warning,
                    color: resolved ? Colors.green : Colors.red,
                  ),
                  title: Text('$patient'),
                  subtitle: Text(
                    'Location: $lat, $lng\nTime: ${ts != null ? formatTimestamp(ts) : "Unknown"}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: resolved ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resolved ? 'Resolved' : 'Unresolved',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  // Optional: onTap to go to details page
                  onTap: () {
                    // Optional: navigate to full screen alert view if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

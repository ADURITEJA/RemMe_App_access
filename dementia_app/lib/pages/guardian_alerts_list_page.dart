import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

class GuardianAlertsListPage extends StatelessWidget {
  final String patientUid;
  final String patientName;

  const GuardianAlertsListPage({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alerts for $patientName')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('patients')
                .doc(patientUid)
                .collection('alerts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }

          final alerts = snapshot.data!.docs;

          return ListView.separated(
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = alerts[index].data();
              final location = alert['location'];
              final timestamp = alert['timestamp']?.toDate();
              final lat = location?['lat'];
              final lng = location?['lng'];

              final formattedTime =
                  timestamp != null
                      ? DateFormat('yyyy-MM-dd – HH:mm:ss').format(timestamp)
                      : 'Unknown time';

              final mapLink =
                  (lat != null && lng != null)
                      ? 'https://maps.google.com/?q=$lat,$lng'
                      : null;

              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text('Alert at $formattedTime'),
                subtitle: mapLink != null ? Text('Location: $lat, $lng') : null,
                onTap:
                    mapLink != null
                        ? () async {
                          try {
                            final canLaunch = await canLaunchUrlString(mapLink);
                            if (canLaunch) {
                              await launchUrlString(mapLink);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open map link'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error opening map link.'),
                              ),
                            );
                          }
                        }
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}

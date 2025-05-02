import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String organizerName;
  final String websiteUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.organizerName,
    required this.websiteUrl,
  });

  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      location: data['location'],
      date: (data['date'] as Timestamp).toDate(),
      organizerName: data['organizerName'],
      websiteUrl: data['websiteUrl'],
    );
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String? expandedEventId;

  Stream<List<Event>> getUpcomingEvents() {
    final now = Timestamp.fromDate(DateTime.now());
    return FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThan: now)
        .orderBy('date')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromDocument(doc)).toList());
  }

  Future<void> _launchInWebView(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
        enableDomStorage: true,
      ),
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Pet Events"),
        backgroundColor: const Color(0xFF94a9a7),
      ),
      body: StreamBuilder<List<Event>>(
        stream: getUpcomingEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No upcoming events found."));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final event = events[index];
              final isExpanded = expandedEventId == event.id;

              return Card(
                elevation: 8,
                margin: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      expandedEventId = isExpanded ? null : event.id;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy – h:mm a').format(event.date),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.location,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green[600], size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Organizer: ${event.organizerName}",
                                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event.description,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity, // Make the button full width
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final uri = Uri.parse(event.websiteUrl);
                                    _launchInWebView(uri);
                                  },
                                  icon: const Icon(Icons.open_in_browser),
                                  label: const Text("Visit Event Website"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF94a9a7),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

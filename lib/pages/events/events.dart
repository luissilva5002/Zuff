import 'package:flutter/material.dart';

// Event model to structure the event data
class Event {
  final String title;
  final String date;
  final String description;

  Event({
    required this.title,
    required this.date,
    required this.description,
  });
}

// EventCard widget to display individual events in a card format
class EventCard extends StatelessWidget {
  final Event event;

  EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              event.date,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The main EventsPage widget that displays the list of events
class EventsPage extends StatelessWidget {
  // Sample events data
  final List<Event> events = [
    Event(
      title: "Pet Adoption Day",
      date: "May 10, 2025",
      description: "Come meet adoptable pets looking for a forever home!",
    ),
    Event(
      title: "Dog Training Workshop",
      date: "May 15, 2025",
      description: "Learn new tricks and tips to train your dog.",
    ),
    Event(
      title: "Pet Health Check-up",
      date: "May 20, 2025",
      description: "Get your pet checked by a professional vet.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Events"),
        backgroundColor: Colors.green, // You can change the color to match your theme
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventCard(event: events[index]);
        },
      ),
    );
  }
}

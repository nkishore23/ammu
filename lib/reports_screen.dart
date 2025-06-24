import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // TextEditingController for the search bar
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for the reports list
  final List<Map<String, String>> _reportItems = [
    {
      'imagePath': 'https://placehold.co/60x60/80C0E0/FFFFFF?text=VM',
      'title': 'VM School',
      'location': 'South Street, Chennai',
      'date': 'Today',
      'time': '11.00 AM'
    },
    {
      'imagePath': 'https://placehold.co/60x60/B0E0E6/000000?text=LB',
      'title': 'Library',
      'location': 'West Street, Chennai',
      'date': 'Today',
      'time': '9.00 AM'
    },
    {
      'imagePath': 'https://placehold.co/60x60/80C0E0/FFFFFF?text=VM',
      'title': 'VM School',
      'location': 'South Street, Chennai',
      'date': 'Yesterday',
      'time': '10.00 AM'
    },
    {
      'imagePath': 'https://placehold.co/60x60/E0B080/000000?text=HM',
      'title': 'Home',
      'location': 'North Street, Chennai',
      'date': 'Yesterday',
      'time': '9.00 AM'
    },
    {
      'imagePath': 'https://placehold.co/60x60/A0D0A0/000000?text=PK',
      'title': 'Park',
      'location': 'South Street, Chennai',
      'date': 'Dec 30,2022',
      'time': '5.00 PM'
    },
    {
      'imagePath': 'https://placehold.co/60x60/80C0E0/FFFFFF?text=VM',
      'title': 'VM School',
      'location': 'South Street, Chennai',
      'date': 'Dec 30,2022',
      'time': '9.00 AM'
    },
  ];

  // A filtered list based on search query
  List<Map<String, String>> _filteredReportItems = [];

  @override
  void initState() {
    super.initState();
    _filteredReportItems = List.from(_reportItems); // Initialize with all items
    _searchController.addListener(_filterReports);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterReports);
    _searchController.dispose();
    super.dispose();
  }

  void _filterReports() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReportItems = _reportItems.where((item) {
        return item['title']!.toLowerCase().contains(query) ||
            item['location']!.toLowerCase().contains(query) ||
            item['date']!.toLowerCase().contains(query) ||
            item['time']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for Rose', // As per the image
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none, // No visible border
              ),
              filled: true,
              fillColor:
                  Colors.grey[200], // Light grey background for search bar
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 0, horizontal: 16), // Adjust padding
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _filteredReportItems.length,
            itemBuilder: (context, index) {
              final item = _filteredReportItems[index];
              return ReportCard(
                imagePath: item['imagePath']!,
                title: item['title']!,
                location: item['location']!,
                date: item['date']!,
                time: item['time']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Custom Widget for displaying individual Report items
class ReportCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;
  final String date;
  final String time;

  const ReportCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image (Profile Pic/Location Pic)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                // Add loading and error builders for better UX
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            // Title and Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 5),
                      Expanded(
                        // Use Expanded to prevent overflow if location is long
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Add ellipsis if text overflows
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Date and Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1), // Deep blue for dates
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AcademicFollowUpScreen extends StatelessWidget {
  const AcademicFollowUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d47a1), // Deep blue theme color
        foregroundColor: Colors.white, // White icons and text
        elevation: 0, // No shadow
        title: const Text(
          'Academic Follow Up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // Dark grey for text
              ),
            ),
            const SizedBox(height: 15),
            // Grid for Marks, Assignments, Events, Others
            GridView.count(
              shrinkWrap: true, // Wrap content to avoid unbounded height
              physics:
                  const NeverScrollableScrollPhysics(), // Disable grid scrolling
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildAlertCard(
                  context,
                  imagePath:
                      'https://placehold.co/150x150/ADD8E6/000000?text=Marks', // Placeholder image
                  label: 'Marks',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marks tapped!')),
                    );
                  },
                ),
                _buildAlertCard(
                  context,
                  imagePath:
                      'https://placehold.co/150x150/C0C0C0/000000?text=Assignments', // Placeholder image
                  label: 'Assignments',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignments tapped!')),
                    );
                  },
                ),
                _buildAlertCard(
                  context,
                  imagePath:
                      'https://placehold.co/150x150/DDA0DD/000000?text=Events', // Placeholder image
                  label: 'Events',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Events tapped!')),
                    );
                  },
                ),
                _buildAlertCard(
                  context,
                  imagePath:
                      'https://placehold.co/150x150/ADD8E6/000000?text=Others', // Placeholder image
                  label: 'Others',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Others tapped!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Overall Performance Section
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 0.6, // 60/100 = 0.6
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0d47a1)), // Deep blue for progress
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://placehold.co/60x60/ADD8E6/000000?text=PC', // Placeholder for PC icon
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.laptop_mac,
                                size: 60, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '60/100', // Text inside the circle
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // View Overall Student Performance Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('View Overall Student Performance tapped!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d47a1), // Deep blue
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                      double.infinity, 55), // Full width, fixed height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'View Overall Student Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  // Helper widget to build individual alert cards
  Widget _buildAlertCard(BuildContext context,
      {required String imagePath,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                width: 90, // Adjusted size to fit the card well
                height: 90, // Adjusted size to fit the card well
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[200],
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
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
